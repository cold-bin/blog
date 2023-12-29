---
title: "Go设计模式之函数选项模式"
date: 2023-08-30T15:28:21+08:00
tags: []
categories: [设计模式]
draft: false
---

***

> 来源于[topgoer](https://www.topgoer.com/%E5%85%B6%E4%BB%96/%E9%80%89%E9%A1%B9%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F.html)

# 函数选项模式

## 默认值

有时候一个函数会有很多参数，为了方便函数的使用，我们会给希望给一些参数设定默认值，调用时只需要传与默认值不同的参数即可，类似于 python 里面的默认参数和字典参数，虽然 golang 里面既没有默认参数也没有字典参数，但是我们有选项模式。

## 应用

从这里可以看到，为了实现选项的功能，我们增加了很多的代码，实现成本相对还是较高的，所以实践中需要根据自己的业务场景去权衡是否需要使用。个人总结满足下面条件可以考虑使用选项模式

- 参数确实比较复杂，影响调用方使用
- 参数确实有比较清晰明确的默认值
- 为参数的后续拓展考虑

## 代码实现

```go
// @author cold bin
// @date 2023/8/30

package option

const (
	DefaultMaxTotal = 10
	DefaultMaxIdle  = 9
	DefaultMinIdle  = 1
)

type Pool struct {
	name     string
	maxTotal int
	maxIdle  int
	minIdle  int
}

func NewPool(name string, opts ...Option) *Pool {
	// 填必须参数
	p := &Pool{name: name, maxTotal: DefaultMaxTotal, maxIdle: DefaultMaxIdle, minIdle: DefaultMinIdle}
	// 填入选项
	for _, opt := range opts {
		opt(p)
	}
	return p
}

type Option func(*Pool)

func WithMaxTotal(maxTotal int) Option {
	return func(pool *Pool) {
		pool.maxTotal = maxTotal
	}
}

func WithMaxIdle(maxIdle int) Option {
	return func(pool *Pool) {
		pool.maxIdle = maxIdle
	}
}

func WithMinIdle(minIdle int) Option {
	return func(pool *Pool) {
		pool.minIdle = minIdle
	}
}
```

