---
title: "Go设计模式之原型模式"
date: 2023-08-31T16:40:50+08:00
tags: []
categories: [设计模式]
draft: false
---

***

# 原型模式

如果对象创建成本比较大（有些字段赋值可能需要rpc、网络、磁盘读取等），而且同一个类的对象差异不大（大部分字段都相同）。在这种情况下，可以从已有对象拷贝出新的对象使用，可以减少对象创建时的成本。

## 实现方法

- 浅拷贝

  针对引用或指针类型的浅拷贝，如果对象发生变化，所有指向对象的指针所得值都会跟着变化。

- 深拷贝

  拷贝得到的对象完全独立，不会受源对象的影响。

  - 深度递归实现（注意环路数据结构）
  - 序列后与反序列化

## 例子

需求: 假设现在数据库中有大量数据，包含了关键词，关键词被搜索的次数等信息，模块 A 为了业务需要

- 会在启动时加载这部分数据到内存中
- 并且需要定时更新里面的数据
- 同时展示给用户的数据每次必须要是相同版本的数据，不能一部分数据来自版本 1 一部分来自版本 2

```go
// @author cold bin
// @date 2023/8/31

package prototype

import (
	"encoding/json"
	"time"
)

// Keyword 搜索关键字
type Keyword struct {
	Word      string
	Visit     int
	UpdatedAt *time.Time
}

// Clone 这里使用序列化与反序列化的方式深拷贝
func (k *Keyword) Clone() *Keyword {
	var newKeyword Keyword
	b, _ := json.Marshal(k)
	json.Unmarshal(b, &newKeyword)
	return &newKeyword
}

// Keywords 关键字 map
// 数据库缓存
type Keywords map[string]*Keyword

// Clone 复制一个新的 keywords
// updatedWords: 需要更新的关键词列表，由于从数据库中获取数据常常是数组的方式
func (words Keywords) Clone(updatedWords []*Keyword) Keywords {
	newKeywords := Keywords{}

	for k, v := range words {
		// 这里是浅拷贝，直接拷贝了地址
		newKeywords[k] = v
	}

	// 替换掉需要更新的字段，这里用的是深拷贝
	for _, word := range updatedWords {
		newKeywords[word.Word] = word.Clone()
	}

	return newKeywords
}
```

