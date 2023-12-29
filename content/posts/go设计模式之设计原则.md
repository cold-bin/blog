---
title: "Go设计模式之设计原则"
date: 2023-08-28T08:35:47+08:00
tags: []
categories: [设计模式]
draft: false
---

***

# 设计原则

- SOLID原则

  SRP、OCP、LSP、ISP、DIP

- KISS原则

- YAGNI原则

- DRY原则

- LOD原则

## SRP

单一职责原则（Single Responsibility Principle）：一个模块或类只负责完成一个功能。不要设计大而全的类。

**是否越单一越好？**

> 越单一的模块，会使得代码内聚性变低。我们要做到高内聚，低耦合。

**如何判断模块设计的是否满足SRP原则？**

> 以业务而定。

## OCP

开闭原则（Open / Closed Principle）：通过在已有代码的基础上扩展代码（添加新的模块、类、方法、属性等），而非修改代码（修改已有的模块、类、方法、属性等）。

**如何理解开闭原则？**

> 扩展和修改的定义是相对于作用对象而言的。
>
> - 添加一个方法或属性在类的层面就是修改类，但是在方法或属性层面就是扩展了属性或方法。换言之，同样的代码改动，在不同对象粒度上，会有不同看法。
> - OCP并非完全排斥修改，而是将修改对代码可维护性的影响降至最低

**怎么做到开闭原则？**

> 提前了解项目需求，预测短期内可能出现的业务变更，组件变更等，在这些地方预留扩展点。怎么留扩展点？运用一些设计模式技巧、基于接口而非实现编程、依赖注入、多态等

## LSP

里氏替换原则（Liskov Subsititution Principle）：子类对象能够替换程序中对父类对象出现的任何地方，并且保证原来程序的逻辑行为不变及正确不被破坏。

**哪些子类设计违反LSP**

> - 子类违背父类声明要实现的功能
> - 子类违背父类对输入、输出和异常的要求
> - 子类违背父类注释中所罗列的任何特殊声明
>
> 简而言之，子类对父类方法重构的实际输入输出、功能需求不能发生变化。

**LSP和多态有什么区别？**

> LSP是设计原则，多态是编程方法。LSP指导子类如何设计，以让子类可以替换父类出现的任何位置。

## ISP

接口隔离原则（Interface Segregation Principle）：客户端不应该强迫依赖它不需要的接口。

三种理解：

- 一组API集合

  某组API只被某个客户端使用，那就没有必要将这组API暴露给其他客户端，将它隔离出来

- 一个API或函数

  类似于单一职责原则，函数或API功能单一，不应该包含其他功能或业务。

- OOP里的接口

  语法上的接口，应该尽可能使得接口里面的方法少，只包含必要的方法

## DIP

依赖反转原则（Dependency Inversion Principle）：高层模块不要依赖低层模块，高层模块和低层模块应该通过抽象来相互依赖。抽象不要依赖具体实现细节，具体实现以来抽象。

### IOC

控制反转（Inversion Of Control）：通过框架约束程序执行流程。

### DI

依赖注入（Dependency Injection）：是一种实现IOC的且用于解决依赖性问题的设计模式，我们不在内部创建对象并使用它，而是将依赖对象直接注入来使用，这样我们就只依赖依赖注入的对象。

> 下面是摘自[飞书技术](https://juejin.cn/post/7148011939279405087)。

**依赖注入前**

```go
// dal/user.go

func (u *UserDal) Create(ctx context.Context, data *UserCreateParams) error {
    db := mysql.GetDB().Model(&entity.User{})
    user := entity.User{
      Username: data.Username,
      Password: data.Password,
   }

    return db.Create(&user).Error
}

// service/user.go
func (u *UserService) Register(ctx context.Context, data *schema.RegisterReq) (*schema.RegisterRes, error) {
   params := dal.UserCreateParams{
      Username: data.Username,
      Password: data.Password,
   }

   err := dal.GetUserDal().Create(ctx, params)
   if err != nil {
      return nil, err
   }

   registerRes := schema.RegisterRes{
      Msg: "register success",
   }

   return &registerRes, nil
}
```

在这段代码里，层级依赖关系为 service -> dal -> db，上游层级通过 `Getxxx`实例化依赖。但在实际生产中，我们的依赖链比较少是垂直依赖关系，更多的是横向依赖。即我们一个方法中，可能要多次调用`Getxxx`的方法，这样使得我们代码极不简洁。

不仅如此，我们的依赖都是写死的，即依赖者的代码中写死了被依赖者的生成关系。当被依赖者的生成方式改变，我们也需要改变依赖者的函数，这极大的增加了修改代码量以及出错风险。

接下来我们用`依赖注入`的方式对代码进行改造：

**依赖注入后**

```go
// dal/user.go
type UserDal struct{
    DB *gorm.DB
}

func NewUserDal(db *gorm.DB) *UserDal{
    return &UserDal{
        DB: db
    }
}

func (u *UserDal) Create(ctx context.Context, data *UserCreateParams) error {
    db := u.DB.Model(&entity.User{})
    user := entity.User{
      Username: data.Username,
      Password: data.Password,
   }

    return db.Create(&user).Error
}

// service/user.go
type UserService struct{
    UserDal *dal.UserDal
}

func NewUserService(userDal dal.UserDal) *UserService{
    return &UserService{
        UserDal: userDal
    }
}

func (u *UserService) Register(ctx context.Context, data *schema.RegisterReq) (*schema.RegisterRes, error) {
   params := dal.UserCreateParams{
      Username: data.Username,
      Password: data.Password,
   }

   err := u.UserDal.Create(ctx, params)
   if err != nil {
      return nil, err
   }

   registerRes := schema.RegisterRes{
      Msg: "register success",
   }

   return &registerRes, nil
}

// main.go 
db := mysql.GetDB()
userDal := dal.NewUserDal(db)
userService := dal.NewUserService(userDal)
```

如上编码情况中，我们通过将 db 实例对象注入到 dal 中，再将 dal 实例对象注入到 service 中，实现了层级间的依赖注入。解耦了部分依赖关系。

在系统简单、代码量少的情况下上面的实现方式确实没什么问题。但是项目庞大到一定程度，结构之间的关系变得非常复杂时，手动创建每个依赖，然后层层组装起来的方式就会变得异常繁琐，并且容易出错。这个时候勇士 [wire](https://github.com/google/wire) 出现了！

## KISS

尽量保持简单（Keep It Simple and Stupid）

**如何写出满足KISS原则的代码？**

> - 注重代码可读性
> - 不要重复造轮子（生产开发
> - 不要过度优化

## YAGNI

你不会需要它（You Aren't Gonna Need It）：核心就是不要过度设计，把一些目前没必要使用的模块也引入

## DRY

不要重复自己（Don't repeat yourself）：

- 实现逻辑重复，但功能逻辑不重复，并不违反DRY原则
- 实现逻辑不重复，但功能逻辑重复，违反DRY原则
- 代码执行重复也算违背DRY原则

**如何提高代码复用性？**

> - 减少代码耦合
> - 满足单一职责原则
> - 模块化
> - 业务与非业务逻辑分离
> - 通用代码下沉
> - 抽象、多态和封装
> - 使用合适的设计模式

## LOD

迪米特法则（Law Of Demeter）：每个模块只应该了解哪些与它关系密切模块的优先知识。

**如何理解高内聚、松耦合？**

> 高内聚就是指把功能相近或为一体的放到同一个模块实现，松耦合就是减少模块之间不必要的依赖。

