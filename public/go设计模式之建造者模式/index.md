# Go设计模式之建造者模式


***

# 建造者模式

与工厂模式不同，建造者模式只创建一种类型的复杂对象，可以通过设置可选参数，定制化地创建不同对象。

简而言之，创建参数复杂的对象

## 应用场景

- 类属性较多
- 类属性之间含有依赖关系
- 存在必选和非必选参数
- 希望创建不可变对象

## 代码实现

```go
// @author cold bin
// @date 2023/8/30

package builder

import "errors"

const (
	DefaultMaxTotal = 10
	DefaultMaxIdle  = 9
	DefaultMinIdle  = 1
)

type Build struct {
	name     string
	maxTotal int
	maxIdle  int
	minIdle  int
}

// Build 建造器
//
//	这里负责参数校验，通过后真正new对象
func (b *Build) Build() (*Pool, error) {
	if b.maxIdle <= 0 {
		b.maxIdle = DefaultMaxIdle
	}
	if b.minIdle <= 0 {
		b.minIdle = DefaultMinIdle
	}
	if b.maxTotal <= 0 {
		b.maxTotal = DefaultMaxTotal
	}
	if b.minIdle > b.maxIdle {
		return nil, errors.New("minIdle is more than maxIdle")
	}

	if b.maxIdle > b.maxTotal {
		return nil, errors.New("maxIdle is more than maxTotal")
	}

	return &Pool{
		name:     b.name,
		maxTotal: b.maxTotal,
		maxIdle:  b.maxIdle,
		minIdle:  b.minIdle,
	}, nil
}

func (b *Build) SetName(name string) {
	b.name = name
}

func (b *Build) SetMaxTotal(maxTotal int) {
	b.maxTotal = maxTotal
}

func (b *Build) SetMaxIdle(maxIdle int) {
	b.maxIdle = maxIdle
}

func (b *Build) SetMinIdle(minIdle int) {
	b.minIdle = minIdle
}

type Pool struct {
	name     string
	maxTotal int
	maxIdle  int
	minIdle  int
}
```



---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/go%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F%E4%B9%8B%E5%BB%BA%E9%80%A0%E8%80%85%E6%A8%A1%E5%BC%8F/  

