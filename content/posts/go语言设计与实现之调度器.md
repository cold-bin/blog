---
title: "Go语言设计与实现之调度器"
date: 2023-10-29T15:09:26+08:00
lastmod: 2023-10-29T15:09:26+08:00
draft: false
keywords: [gmp]
description: "本文将介绍go语言是如何调度协程的"
tags: [go语言底层原理]
categories: [golang]
---

# go线程调度器

## 抢占式调度器

go语言调度器的发展历程经过好几个版本，目前的实现是**基于信号的抢占式调度器**。go语言是在用户空间实现的协程调度器，相比于依赖于操作系统线程调度器，go的多个协程绑定到一个内核线程上去，内存开销很小，可以创建很多协程；并且没有用户态和内核态切换的成本。

但是go调度器并没有彻底解决STW问题。

## 数据结构

go调度器主要由三个主要部分组成：G，M，P

### G

G指的是调度器中执行的任务，也就是goroutine，部分结构如下：

```go
type g struct {
	stack       stack // 标识当前goroutine栈内存范围
	stackguard0 uintptr
         
         preempt       bool // 抢占信号
	preemptStop   bool // 抢占时将状态修改成 `_Gpreempted`
	preemptShrink bool // 在同步安全点收缩栈
    
         _panic       *_panic // 最内侧的 panic 结构体
	_defer       *_defer // 最内侧的延迟函数结构体
    
         m              *m // 当前G占用的线程
	sched          gobuf // 存储G的调度数据：其实就是保存上下文
	atomicstatus   uint32 // G的状态
	goid           int64 // 唯一标识G
         
         ...
}

type gobuf struct {
	sp   uintptr // 栈指针
	pc   uintptr // 程序计数器
	g    guintptr
	ret  sys.Uintreg // 系统调用返回值
	...
}
```

### M

M指的是操作系统的线程，调度器最多可以创建10000个线程，但同时可以运行的线程只能有`gomaxprocs`个。（`runtime.GOMAXPROCS`可以设置，默认设置是线程数等于cpu核数，其实也是P的个数）

```go
type m struct {
	g0   *g // 负责调度P的goroutine：参与大内存分配、CGO函数执行等
	curg *g // 获得线程执行权的goroutine
	p             puintptr // 正在运行代码的处理器
	nextp         puintptr // 暂存的处理器
	oldp          puintptr // 执行系统调用前的处理器
    
         ...
}
```

### P

P是协程和线程的中间层，负责将协程映射到某个线程执行（提供给线程上下文环境），同时负责调度本地队列里的协程。

```go
type p struct {
	m           muintptr

	runqhead uint32 // 
	runqtail uint32 // 
	runq     [256]guintptr // 等待运行队列，最多256个
	runnext guintptr // 下一个需要被执行的G
	...
}
```

## 如何调度

### 创建G时

1. 创建好G时，如果允许G作为下一个处理器要执行的G，则直接设置`g.runnext`属性为G
2. 如果不允许，则将G放入处理器的本地运行队列；
3. 如果本地运行队列已满，则将一部分G和新加入的G放入全局的运行队列

### 运行时调度循环

- [`runtime.schedule`](https://draveness.me/golang/tree/runtime.schedule) 函数会从下面几个地方查找待执行的 Goroutine：
  1. 为了保证公平，当全局运行队列中有待执行的 Goroutine 时，通过 `schedtick` 保证有一定几率会从全局的运行队列中查找对应的 Goroutine；
  2. 从处理器本地的运行队列中查找待执行的 Goroutine；
  3. 如果前两种方法都没有找到 Goroutine，会通过 [`runtime.findrunnable`](https://draveness.me/golang/tree/runtime.findrunnable) 进行阻塞地查找 Goroutine；

- [`runtime.findrunnable`](https://draveness.me/golang/tree/runtime.findrunnable) 的实现非常复杂，这个 300 多行的函数通过以下的过程获取可运行的 Goroutine：
  1. 从本地运行队列、全局运行队列中查找；
  2. 从网络轮询器中查找是否有 Goroutine 等待运行；
  3. 通过 [`runtime.runqsteal`](https://draveness.me/golang/tree/runtime.runqsteal) 尝试从其他随机的处理器中窃取待运行的 Goroutine，该函数还可能窃取处理器的计时器；

因为函数的实现过于复杂，上述的执行过程是经过简化的，总而言之，当前函数一定会返回一个可执行的 Goroutine，如果当前不存在就会阻塞等待。

- P获取到Goroutine之后，调度到当前线程上执行，执行完毕后，会执行一些清理工作，然后又进入下一轮调度，形成调度循环。

## 调度时机

- 主动挂起 — [`runtime.gopark`](https://draveness.me/golang/tree/runtime.gopark) -> [`runtime.park_m`](https://draveness.me/golang/tree/runtime.park_m)
- 系统调用 — [`runtime.exitsyscall`](https://draveness.me/golang/tree/runtime.exitsyscall) -> [`runtime.exitsyscall0`](https://draveness.me/golang/tree/runtime.exitsyscall0)
- 协作式调度 — [`runtime.Gosched`](https://draveness.me/golang/tree/runtime.Gosched) -> [`runtime.gosched_m`](https://draveness.me/golang/tree/runtime.gosched_m) -> [`runtime.goschedImpl`](https://draveness.me/golang/tree/runtime.goschedImpl)
- 系统监控 — [`runtime.sysmon`](https://draveness.me/golang/tree/runtime.sysmon) -> [`runtime.retake`](https://draveness.me/golang/tree/runtime.retake) -> [`runtime.preemptone`](https://draveness.me/golang/tree/runtime.preemptone)
