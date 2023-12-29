# Go语言设计模式之工厂模式


***

# 工厂模式

与单例模式不同，工厂模式根据传入参数不同，会创建出不同的但是相关联的对象，由给定参数来决定是哪一种对象。像一个工厂一样，传入什么，生产什么，不止一种。

## 简单工厂

传出不同对象需要，使用接口多态特性

```go
// @author cold bin
// @date 2023/8/28

package factory

type Config interface {
	Parse(data []byte) error
	UnParse(src []byte, dst []byte) error
}

type Json struct {
}

func (j Json) Parse(data []byte) error {
	panic("implement me")
}

func (j Json) UnParse(src []byte, dst []byte) error {
	panic("implement me")
}

type Yaml struct {
}

func (y Yaml) Parse(data []byte) error {
	panic("implement me")
}

func (y Yaml) UnParse(src []byte, dst []byte) error {
	panic("implement me")
}

// NewConfig 这里直接使用简单工厂方法创建最终对象
//
//	如果创建对象不复杂，不涉及对象之间的组合，可以使用
func NewConfig(name, typ string) Config {
	switch typ {
	case "json":
		return &Json{}
	case "yaml":
		return &Yaml{}
	}
	return nil
}
```

## 工厂方法

简单工厂适合直接创建一些较简单的对象，如果涉及多个对象之间的组合以及初始化，可以考虑使用工厂方法。工厂方法并不是直接拿的直接对象，而是拿的工厂，拿到之后，可以在有需要的时候根据工厂来创建对象并组合。

而且，工厂可以复用，避免重复创建工厂

```go
// @author cold bin
// @date 2023/8/29

package factory

// ConfigFactory Config 的工厂方法抽象
type ConfigFactory interface {
	Create() Config
}

type JsonFactory struct{}

func (j JsonFactory) Create() Config {
	return Json{}
}

type YamlFactory struct{}

func (y YamlFactory) Create() Config {
	return Json{}
}

// NewConfigFactory 这里使用简单工厂的方式创建工厂
//
//	与简单工厂不同的是，这里拿的还是工厂，而不是直接的对象
func NewConfigFactory(typ string) ConfigFactory {
	switch typ {
	case "json":
		return JsonFactory_
	case "yaml":
		return YamlFactory_
	}
	return nil
}

var (
	JsonFactory_ = JsonFactory{}
	YamlFactory_ = YamlFactory{}
)
```

## 抽象工厂

略

## 应用——DI

DI是依赖注入的意思。DI的底层设计其实就是工厂模式的应用。

## 总结

工厂模式是用以创建不同但是相关联的对象，根据传入参数来决定创建那种对象。

- 不用工厂模式创建多个有关联对象：if-else逻辑过多、创建逻辑、业务代码耦合在一起

- 简单工厂可以将多个对象的创建逻辑放到一个工厂类里

- 工厂方法可以将不同创建逻辑拆分到不同工厂类里，然后可以通过特定工厂创建对象

  适合简单工厂创建对象过于复杂的情形

