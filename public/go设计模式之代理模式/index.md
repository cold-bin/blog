# Go设计模式之代理模式


***

# 代理模式

> 单例模式、工厂模式、建造者模式、原型模式、函数选项模式都是属于创建型模式，指导如何创建对象。
>
> 而结构型模式主要指导如何将对象或类组合在一起，有代理模式、桥接模式、装饰器模式、门面模式、组合模式、享元模式。

什么是代理模式呢？顾名思义，在**不改变原始类（被代理类）代码**的情况下，通过引入代理类给原始类**附加功能**。

## 应用场景

- RPC

- 缓存

- 监控

- 鉴权

- 限流

- 事务

  ...

这里给出一个文件上传代理模式框架实现

```go
// @author cold bin
// @date 2023/9/1

package proxy

import (
	"context"
)

// Uploader 上传文件的抽象
type Uploader interface {
	UploadSingle(ctx context.Context, key string, value []byte)
	UploadMultiple(ctx context.Context, keys []string, values [][]byte)
}

// UploaderProxy 上传的代理者
//
//	将所有实现都进行代理，我们可以在Up执行前或后做一些事情，例如实现一些hook
type UploaderProxy struct {
	Up Uploader
}

func (u *UploaderProxy) UploadSingle(ctx context.Context, key string, value []byte) {
	// 这里可以做一些事情：
	//  1、校验文件名是否正确
	//  2、记录图床开始上传时间
	//  3、统计上传频率，做限流等
	u.Up.UploadSingle(ctx, key, value)
	// 这里也可以做一些事情：
	//  1、hook结果
	//  2、记录图床结束上传时间
	//  3、记录图床上传时间
}

func (u *UploaderProxy) UploadMultiple(ctx context.Context, keys []string, values [][]byte) {
	u.Up.UploadMultiple(ctx, keys, values)
}

type QiniuOss struct {
	// 注入七牛的依赖
}

func (q *QiniuOss) UploadSingle(ctx context.Context, key string, value []byte) {

}

func (q *QiniuOss) UploadMultiple(ctx context.Context, keys []string, values [][]byte) {

}

type AliOss struct {
	// 注入阿里云oss依赖
}

func (a *AliOss) UploadSingle(ctx context.Context, key string, value []byte) {

}

func (a *AliOss) UploadMultiple(ctx context.Context, keys []string, values [][]byte) {

}
```

## 总结

- 看的出来，代理模式的实现是在“基于接口而非实现”的抽象之上的

- 可以说，代理模式也实现了基于接口而非实现的设计原则，并且在此基础上，通过实现代理类，来给原有业务实现添加一些功能。添加的功能作用于局限于原业务执行前后，但是不能作用于原业务中。

  > 其实，作用于原业务中就不使用代理模式了，只能重构原业务代码实现。
  
- 代理模式指的是：通过引入原始类的方式来给原始类增加功能。我们也可以引入原始类实现的接口，这样可以对所有的实现进行统一代理

