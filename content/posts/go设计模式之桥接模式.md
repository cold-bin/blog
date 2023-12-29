---
title: "Go设计模式之桥接模式"
date: 2023-09-02T11:27:02+08:00
tags: []
categories: [设计模式]
draft: false
---

***

# 桥接模式

一个类存在多个独立变化维度，我们通过**组合**的方式让多个维度可以独立进行扩展。桥接模式的目的是将抽象部分与实现部分解耦，使**它们可以独立地变化**。

举例：实现一个告警系统：告警系统含有多个告警类别和多种告警方式，告警类别和告警方式之间可以任意对应使用，方便灵活调整。也就是说，告警方式和告警类别可以独立变化，因为这两个没有依赖关系。

```go
// @author cold bin
// @date 2023/9/2

package bridge

import "fmt"

// AlertMethod 告警方式的接口
type AlertMethod interface {
	SendAlert(message string)
}

// 具体的告警方式

type EmailAlert struct{}

func (e *EmailAlert) SendAlert(message string) {
	fmt.Println("通过邮件发送告警：", message)
}

type SMSAlert struct{}

func (s *SMSAlert) SendAlert(message string) {
	fmt.Println("通过短信发送告警：", message)
}

// AlertLevel 告警级别的接口
type AlertLevel interface {
	SetAlertMethod(method AlertMethod)
	Alert(message string)
}

// 具体的告警级别

type WarningAlert struct {
	method AlertMethod
}

func (w *WarningAlert) SetAlertMethod(method AlertMethod) {
	w.method = method
}

func (w *WarningAlert) Alert(message string) {
	w.method.SendAlert("[Warning] " + message)
}

type ErrorAlert struct {
	method AlertMethod
}

func (e *ErrorAlert) SetAlertMethod(method AlertMethod) {
	e.method = method
}

func (e *ErrorAlert) Alert(message string) {
	e.method.SendAlert("[Error] " + message)
}
```

