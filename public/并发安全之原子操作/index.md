# 并发安全之原子操作


[toc]

## 原子操作

并发是业务开发中经常要面对的问题，很多时候我们会直接用一把 `sync.Mutex` 互斥锁来线性化处理，保证每一时刻进入临界区的 goroutine 只有一个。这样避免了并发，但性能也随着降低。

所以，我们进而又有了 `RWMutex` 读写锁，保障了多个读请求的并发处理，对共享资源的写操作和读操作则区别看待，并消除了读操作之间的互斥。

`Mutex` 和 `RWMutex` 锁的实现本身还是基于 `atomic` 包提供的原子操作，辅之以自旋等处理。很多时候其实我们不太需要**锁住资源**这个语意，而是一个**原子操作**就ok。这篇文章我们来看一下 `atomic` 包提供的能力。

### 定义

不会被线程调度机制打断的操作。

"原子操作(atomic operation)是不需要synchronized"，这是多线程编程的老生常谈了。所谓**原子操作是指不会被线程调度机制打断的操作**；这种操作一旦开始，就一直运行到结束，中间不会有任何 context switch（切换到另一个线程）。使用原子操作，就可以保证你的操作一定是原子的，也就是不会被同一时刻其他并发线程打断，一定会执行。

### Golang的原子操作

Go语言通过内置包`sync/atomic`提供了对原子操作的支持，其提供的原子操作有以下几大类：

- 增减，操作的方法名方式为`AddXXXType`，保证对操作数进行原子的增减，支持的类型为`int32`、`int64`、`uint32`、`uint64`、`uintptr`，使用时以实际类型替换前面我说的`XXXType`就是对应的操作方法。
- 载入，保证了读取到操作数前没有其他任务对它进行变更，操作方法的命名方式为`LoadXXXType`，支持的类型除了基础类型外还支持`Pointer`，也就是支持载入任何类型的指针。
- 存储，有载入了就必然有存储操作，这类操作的方法名以`Store`开头，支持的类型跟载入操作支持的那些一样。
- 比较并交换，也就是`CAS`（Compare And Swap），像Go的很多并发原语实现就是依赖的`CAS`操作，同样是支持上面列的那些类型。
- 交换，这个简单粗暴一些，不比较直接交换，这个操作很少会用。

### 互斥锁跟原子操作的区别

平日里，在并发编程里，Go语言`sync`包里的同步原语`Mutex`是我们经常用来保证并发安全的，那么他跟`atomic`包里的这些操作有啥区别呢？在我看来他们在使用目的和底层实现上都不一样：

- 使用目的：**互斥锁是用来保护一段逻辑，原子操作用于对一个变量的更新保护**。
- 底层实现：`Mutex`由**操作系统**的调度器实现（上下文切换开销较大），而`atomic`包中的原子操作则由**底层硬件指令**直接提供支持，这些指令在执行的过程中是不允许中断的，因此原子操作可以在`lock-free`的情况下保证并发安全，并且它的性能也能做到随`CPU`个数的增多而线性扩展。

**对于一个变量更新的保护，原子操作通常会更有效率，并且更能利用计算机多核的优势。**

所以，如果在业务里只是针对单个变量并发运算的安全时，不应该考虑加锁而是考虑使用原子操作保证其原子性。貌似原子操作是乐观锁的实现，如果同一时刻有太多变量对同一个变量进行写操作，使用CAS机制时，最多同一时刻只能有一个操作成功，其余操作全部失败终止或者进入原地地“自旋”。

使用互斥锁的并发计数器程序的例子：

```go
func mutexAdd() {
 var a int32 =  0
 var wg sync.WaitGroup
 var mu sync.Mutex // 互斥锁
 start := time.Now()
 for i := 0; i < 100000000; i++ {
  wg.Add(1)
  go func() {
   defer wg.Done()
   mu.Lock()
   a += 1
   mu.Unlock()
  }()
 }
 wg.Wait()
 timeSpends := time.Now().Sub(start).Nanoseconds()
 fmt.Printf("use mutex a is %d, spend time: %v\n", a, timeSpends)
}
```

把`Mutex`改成用方法`atomic.AddInt32(&a, 1)`调用，在不加锁的情况下仍然能确保对变量递增的并发安全。

```go
func AtomicAdd() {
 var a int32 =  0
 var wg sync.WaitGroup
 start := time.Now()
 for i := 0; i < 1000000; i++ {
  wg.Add(1)
  go func() {
   defer wg.Done()
   atomic.AddInt32(&a, 1)
  }()
 }
 wg.Wait()
 timeSpends := time.Now().Sub(start).Nanoseconds()
 fmt.Printf("use atomic a is %d, spend time: %v\n", atomic.LoadInt32(&a), timeSpends)
}
```

可以在本地运行以上这两段代码，可以观察到计数器的结果都最后都是`1000000`，都是线程安全的。

上面两种方式：第一种互斥锁实现的并发计数例子里，每一次开了大量携程来对`a`加`1`，为了保证并发安全加了互斥锁，虽然有效但是性能开销太大了，期间发生了很多次上下文切换；第二种使用原子操作来对`a`变量实现加`1`操作，这个过程是原子的，其他协程无法打断，只能等待指令执行成功之后，其他协程才能拿到这个`a`的地址又进行原子操作，这样循环直到所有协程执行完毕后程序结束。相比第一种加互斥锁保证并发安全的方式，第二种原子操作的方式是通过CPU指令集实现的，没有上下文切换的开销，只是执行一个CPU指令而已。

### 比较并交换

该操作简称`CAS` (Compare And Swap)。这类操作的前缀为 `CompareAndSwap` :

```go
func CompareAndSwapInt32(addr *int32, old, new int32) (swapped bool)

func CompareAndSwapPointer(addr *unsafe.Pointer, old, new unsafe.Pointer) (swapped bool)
```

该操作在**进行交换前首先确保被操作数的值未被更改，即仍然保存着参数 `old` 所记录的值，满足此前提条件下才进行交换操作**。`CAS`的做法类似操作数据库时常见的乐观锁机制。

需要注意的是：当有大量的goroutine 对变量进行**读写操作**时，可能导致`CAS`操作无法成功，这时可以利用`for`循环多次尝试。(乐观锁不适合写多读少的场景)

上面我只列出了比较典型的`int32`和`unsafe.Pointer`类型的`CAS`方法，主要是想说除了读数值类型进行比较交换，还支持对指针进行比较交换。

> `unsafe.Pointer`提供了绕过Go语言指针类型限制的方法，unsafe指的并不是说不安全，而是说官方并不保证向后兼容。

```go
// 定义一个struct类型P
type P struct{ x, y, z int }
  
// 执行类型P的指针
var pP *P
  
func main() {
  
    // 定义一个执行unsafe.Pointer值的指针变量
    var unsafe1 = (*unsafe.Pointer)(unsafe.Pointer(&pP))
  
    // Old pointer
    var sy P
  
    // 为了演示效果先将unsafe1设置成Old Pointer
    px := atomic.SwapPointer(
        unsafe1, unsafe.Pointer(&sy))
  
    // 执行CAS操作，交换成功，结果返回true
    y := atomic.CompareAndSwapPointer(
        unsafe1, unsafe.Pointer(&sy), px)
  
    fmt.Println(y)
}
```

上面的示例并不是在并发环境下进行的`CAS`，只是为了演示效果，先把被操作数设置成了`Old Pointer`。

其实`Mutex`的底层实现也是依赖原子操作中的`CAS`实现的，原子操作的`atomic`包相当于是`sync`包里的那些同步原语的实现依赖。

比如互斥锁`Mutex`的结构里有一个`state`字段，其是表示锁状态的状态位。

```go
type Mutex struct {
 state int32
 sema  uint32
}
```

为了方便理解，我们在这里将它的状态定义为0和1，0代表目前该锁空闲，1代表已被加锁，以下是`sync.Mutex`中`Lock`方法的部分实现代码。

```go
func (m *Mutex) Lock() {
   // Fast path: grab unlocked mutex.
   if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
       if race.Enabled {
           race.Acquire(unsafe.Pointer(m))
       }
       return
   }
   // Slow path (outlined so that the fast path can be inlined)
    m.lockSlow()
}
```

在`atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked)`中，`m.state`代表锁的状态，通过`CAS`方法，判断锁此时的状态是否空闲（`m.state==0`），是，则对其加锁（`mutexLocked`常量的值为1）。

### `atomic.Value`保证任意值的读写安全

`atomic`包里提供了一套`Store`开头的方法，用来保证各种类型变量的并发写安全，避免其他操作读到了修改变量过程中的脏数据。

```go
func StoreInt32(addr *int32, val int32)

func StoreInt64(addr *int64, val int64)

func StorePointer(addr *unsafe.Pointer, val unsafe.Pointer)

...
```

这些操作方法的定义与上面介绍的那些操作的方法类似，我就不再演示怎么使用这些方法了。

值得一提的是如果你想要并发安全的设置一个结构体的多个字段，除了把结构体转换为指针，通过`StorePointer`设置外，还可以使用`atomic`包后来引入的`atomic.Value`，它在底层为我们完成了从具体指针类型到`unsafe.Pointer`之间的转换。

有了`atomic.Value`后，它使得我们可以不依赖于不保证兼容性的`unsafe.Pointer`类型，同时又能将任意数据类型的读写操作封装成原子性操作（中间状态对外不可见）。

`atomic.Value`类型对外暴露了两个方法：

- `v.Store(c)` - 写操作，将原始的变量`c`存放到一个`atomic.Value`类型的`v`里。
- `c := v.Load()` - 读操作，从线程安全的`v`中读取上一步存放的内容。

1.17 版本我看还增加了`Swap`和`CompareAndSwap`方法。

简洁的接口使得它的使用也很简单，只需将需要做并发保护的变量读取和赋值操作用`Load()`和`Store()`代替就行了。

由于`Load()`返回的是一个`interface{}`类型，所以在使用前我们记得要先转换成具体类型的值，再使用。下面是一个简单的例子演示`atomic.Value`的用法。

```go
type Demo struct {
	A int
	B int
}

var rect atomic.Value

func main() {
	wg := sync.WaitGroup{}
	var container *Demo = &Demo{}
	// 10 个协程并发更新
	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			container.A = i
			container.B = i + 1
			rect.Store(container)
		}()
	}
	wg.Wait()
	_r := rect.Load().(*Demo)

	fmt.Printf("rect.width=%d\nrect.length=%d\n", _r.A, _r.B)
}
```

你也可以试试，不用`atomic.Value`，看看在并发条件下，两个字段的值是不是能跟预期的一样变成10和15。

### 总结

原子操作由**底层硬件**支持，而锁则由操作系统的**调度器**实现。

- 锁应当用来保护一段逻辑

- 对于一个变量更新的保护，原子操作通常会更有效率，并且更能利用计算机多核的优势
- 如果要更新的是一个复合对象，则应当使用`atomic.Value`封装好的实现

## 项目案例分析

在`net\http`官方包里，`http.ListenAndServe()`里面的逻辑就是：来一个请求就开一个协程去处理它。在高并发的场景下，虽然go可以轻松开启数百万协程，每个协程初始被分配2kb的内存大小。来一个请求就开一个协程，这样的方式太过粗暴，耗费资源。我们可以对goroutine做池化处理：维护cap容量的goroutine工作，当执行的任务小于cap时，这时资源是充足的，可以让每个goroutine对应一个执行任务；当执行任务大于cap时，这时认为资源是不足的，我们需要复用goroutine，也就是会存在一个goroutine执行完当前任务时，就再执行下一个任务，达到复用的目的。

### `Pool`

`Pool`是对外暴露的方法集合的接口。内部是`pool`结构体来实现的

```go
type Pool interface {
    // Name returns the corresponding pool name.
    Name() string
    // SetCap sets the goroutine capacity of the pool.
    SetCap(cap int32)
    // Go executes f.
    Go(f func())
    // CtxGo executes f and accepts the context.
    CtxGo(ctx context.Context, f func())
    // SetPanicHandler sets the panic handler.
    SetPanicHandler(f func(context.Context, interface{}))
    // WorkerCount returns the number of running workers
    WorkerCount() int32
}
```

简单看看这几个方法

- `Name() string` 方法是指定当前池的名字
- `SetCap(cap int32)`用来动态扩容，可以看到源码里是并发安全的（原子的将新值加载到`pool.cap`的）
- `Go(f func())`将函数放到任务链表里，并判断是否需要新开`worker`（即协程）来分担`f`所在的任务链表执行
- `CtxGo(ctx context.Context, f func())`同`Go(f func()`
- `SetPanicHandler(f func(context.Context, interface{}))`是自定义panic处理逻辑，如果不定义将会默认调用`github.com/bytedance/gopkg/util/logger`来处理
- `WorkerCount() int32`动态获取当前运行的`worker`，也就是正在跑的goroutine数量

### `pool`

`pool`是内部包自己实现`Pool`接口的结构体。

```go
type pool struct {
    // The name of the pool
    name string

    // capacity of the pool, the maximum number of goroutines that are actually working
    cap int32 // 也就是限制 worker 的数量

    // Configuration information
    config *Config // gopool提供默认配置，当任务数大于1时，就新开一个goroutine

    // 真正放函数的地方，所有的函数都放在这里
    // linked list of tasks
    taskHead  *task      // 头节点
    taskTail  *task      // 指向最后一个节点，实现一个O(1)的复杂度添加
    taskLock  sync.Mutex // 保证并发安全
    taskCount int32      // 任务数量

    // Record the number of running workers
    workerCount int32 // 正在跑的worker

    // This method will be called when the worker panic
    panicHandler func(context.Context, interface{})
}
```

- `name`是当前池的名字。
- `cap`是当前池的容量，即允许在跑的最大协程数
- `config`标识当前每个`worker`应当被分配的任务函数个数，包里默认是`1`
- `taskXXXX`是任务链表，`taskLock`是为了保证代码片段的并发安全，`taskCount`动态标识当前还未执行的任务函数
- `workerCount`标识当前正在跑的协程数
- `panicHandler`自定义panic处理

### `pool`的方法

```go
func (p *pool) Name() string {
    return p.name
}

// SetCap 通过CPU指令集保证是原子的方式存到指定地址，保证并发安全
func (p *pool) SetCap(cap int32) {
    // 将值原子地设置到p里
    atomic.StoreInt32(&p.cap, cap)
}

func (p *pool) Go(f func()) {
    p.CtxGo(context.Background(), f)
}

func (p *pool) CtxGo(ctx context.Context, f func()) {
    // 池里取空的对象
    t := taskPool.Get().(*task)
    // 置新
    t.ctx = ctx
    t.f = f
    // 下面代码逻辑上锁
    p.taskLock.Lock()
    // 将 task 放到任务链表里，这个过程由于是多个Goroutine操作并发操作，都在往任务链表里塞 task ，
    // 因此，需要将task入链表的代码锁住，防止并发问题
    if p.taskHead == nil { // 链表为空
        p.taskHead = t
        p.taskTail = t
    } else { //
        p.taskTail.next = t
        p.taskTail = t
    }
    p.taskLock.Unlock()
    // 然后原子更改任务状态，不需要加锁（避免上下文切换），这样可以获得更好的性能
    atomic.AddInt32(&p.taskCount, 1)
    // The following two conditions are met:
    // 1. the number of tasks is greater than the threshold.
    // 2. The current number of workers is less than the upper limit p.cap.
    // or there are currently no workers.
    // 根据默认的配置：worker数大于等于 p.cap时就会，就不会新建 worker了，此时就会复用已有的worker来执行；
    // 在小于p.cap时就会每个task新建一个goroutine
    if (atomic.LoadInt32(&p.taskCount) >= p.config.ScaleThreshold && p.WorkerCount() < atomic.LoadInt32(&p.cap)) || p.WorkerCount() == 0 {
        // 新开一个 worker
        p.incWorkerCount()
        // 池里拿
        w := workerPool.Get().(*worker)
        // p放到worker的pool里
        w.pool = p
        // 再开一个协程跑，取这个worker的任务并执行
        w.run()
    }
}

// SetPanicHandler the func here will be called after the panic has been recovered.
func (p *pool) SetPanicHandler(f func(context.Context, interface{})) {
    p.panicHandler = f
}

func (p *pool) WorkerCount() int32 {
    return atomic.LoadInt32(&p.workerCount)
}

func (p *pool) incWorkerCount() {
    atomic.AddInt32(&p.workerCount, 1)
}

func (p *pool) decWorkerCount() {
    atomic.AddInt32(&p.workerCount, -1)
}
```

### `worker`

`worker`结构体里有一个`pool`指针，在`gopool`的逻辑实现里，多个`worker`的`pool`指向同一个`pool`。意思是多个`worker`针对同一个`pool`里的任务链表处理

```go
type worker struct {
    pool *pool // 多个worker都指向这个pool
}
```

### `worker`的方法

#### `run`

新开一个携程去轮询任务链表，并作panic的处理。值得注意的是：取任务链表里的任务时，必须上锁。因为此时有多个协程并发地取任务链表执行。panic处理也挺有意思，这里是将panic和任务函数调用放到一个匿名函数调用里，这样就可以使得panic地捕获一定是任务函数地panic，而不是捕获`run`方法里的panic

```go
func (w *worker) run() {
    go func() {
        for {
            var t *task

            // 必须上锁，因为可能有多个 worker（也就是多个协程） 同时再对这个pool里的task链表做取出操作，并执行这个task
            w.pool.taskLock.Lock()

            // 不断拿出 task
            if w.pool.taskHead != nil {
                t = w.pool.taskHead
                w.pool.taskHead = w.pool.taskHead.next
                // 原子的减少任务数
                atomic.AddInt32(&w.pool.taskCount, -1)
            }

            // 任务取完了
            if t == nil {
                // if there's no task to do, exit
                w.close()
                w.pool.taskLock.Unlock()
                // 回收
                w.Recycle()
                return
            }

            // 释放时机到了
            w.pool.taskLock.Unlock()

            // 匿名函数调用，退一个栈从而形成独立环境，不让当前的defer去捕获外面函数里的异常，只是捕获这个执行函数的panic
            // 确保这个defer一定是捕获的task的panic
            func() {
                // 处理panic
                defer func() {
                    if r := recover(); r != nil {
                        if w.pool.panicHandler != nil {
                            w.pool.panicHandler(t.ctx, r)
                        } else {
                            msg := fmt.Sprintf("GOPOOL: panic in pool: %s: %v: %s", w.pool.name, r, debug.Stack())
                            logger.CtxErrorf(t.ctx, msg)
                        }
                    }
                }()
                // 真正地执行函数
                t.f()
            }()
            // 回收task
            t.Recycle()
        }
    }()
}
```

#### 其他方法

```go
// 协程数减一
func (w *worker) close() {
    w.pool.decWorkerCount()
}

func (w *worker) zero() {
    w.pool = nil
}

// Recycle 回收worker
func (w *worker) Recycle() {
    w.zero()
    // 放回池里
    workerPool.Put(w)
}
```

`task`

```go
type task struct {
    ctx context.Context
    f   func()

    next *task
}
```

```go
func (t *task) zero() {
    t.ctx = nil
    t.f = nil
    t.next = nil
}

// Recycle 回收到 sync.Pool里
func (t *task) Recycle() {
    // task 置空
    t.zero()
    // 放到池里
    taskPool.Put(t)
}
```



---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/%E5%B9%B6%E5%8F%91%E5%AE%89%E5%85%A8%E4%B9%8B%E5%8E%9F%E5%AD%90%E6%93%8D%E4%BD%9C/  

