# Go语言设计模式之单例模式


# 单例模式

![img](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img2/202308281635261.jpeg)

简而言之：一个类只允许创建一个对象或示例。

## 饿汉式

项目初始化的时候加载并初始化对象。创建过程线程安全，而且使得问题尽早暴露。

```go
// @author cold bin
// @date 2023/8/28

package singleton

/*
	单例模式的饿汉式:项目编译运行的初期就已经初始化了对象
*/

type Logger interface {
	print(...any) error
}

type log struct{}

func (l *log) print(...any) error {
	return nil
}

var log_ *log

// 只要导入包，编译时便会初始化这个对象
func init() {
	log_ = &log{}
}

func GetInstance() Logger {
	return log_
}
```



## 懒汉式（双重检测）

支持延迟加载，在第一次使用对象的时候创建对象，也就是有需要使用的时候再创建对象。相比懒汉式，支持对象创建的并发安全。代码实现思路：一是通过`sync.Mutex`直接加锁；二是使用`sync.Once`保证对象创建只调用一次。

```go
// @author cold bin
// @date 2023/8/28

package singleton

import "sync"

/*
	单例模式的懒汉式：支持延迟加载，实现范式会导致频繁加锁和释放锁，而且并发度也低。双重检测版本
*/

var (
	log__ *log
	once  sync.Once
)

func GetLazyInstance() Logger {
	if log__ == nil {
		once.Do(func() {
			log__ = &log{}
		})
	}
	return log__
}

```



---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/go%E8%AF%AD%E8%A8%80%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F%E4%B9%8B%E5%8D%95%E4%BE%8B%E6%A8%A1%E5%BC%8F/  

