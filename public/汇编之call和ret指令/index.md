# 汇编之call和ret指令


# call和ret指令

------

call和ret指令都是转移指令，它们都修改IP，或同时修改CS和IP。

## 1、ret 和 retf

- ret指令用栈中的数据，修改IP的内容，从而实现近转移；
- retf指令用栈中的数据，修改CS和IP的内容，从而实现远转移。

CPU执行ret指令时，相当于进行： `pop IP`：

（1）(IP) = ( (ss) * 16 + (sp) )

（2）(sp) = (sp) + 2

CPU执行retf指令时，相当于进行：`pop IP, pop CS`：

（1）(IP) = ( (ss) * 16 + (sp) )

（2）(sp) = (sp) + 2

（3）(CS) = ( (ss) * 16 + (sp) )

（4）(sp) = (sp) + 2

```asm
assume cs:code 
stack seqment
	db 16 dup (0)
stack ends 

code segment
		mov ax, 4c00h
		int 21h 
 start:	mov ax, stack 
 		mov ss, ax
 		mov sp, 16
		mov ax, 0
		push ax ;ax入栈
		mov bx, 0
		ret ;ret指令执行后，(IP)=0，CS:IP指向代码段的第一条指令。可以push cs  push ax  retf
code ends
end start
```

## 2、call 指令

call指令经常跟ret指令配合使用，因此CPU执行call指令，进行两步操作：

（1）将当前的 IP 或 CS和IP 压入栈中；

（2）转移（jmp）。

call指令不能实现短转移，除此之外，call指令实现转移的方法和 jmp 指令的原理相同。

`call 标号`（近转移）

CPU执行此种格式的call指令时，相当于进行 `push IP` `jmp near ptr 标号`

`call far ptr 标号`（段间转移）

CPU执行此种格式的call指令时，相当于进行：`push CS，push IP` `jmp far ptr 标号`

```
call 16位寄存器
```

CPU执行此种格式的call指令时，相当于进行： `push IP` `jmp 16位寄存器`

```
call word ptr 内存单元地址
```

CPU执行此种格式的call指令时，相当于进行：`push IP` `jmp word ptr 内存单元地址`

```asm
mov sp, 10h
mov ax, 0123h
mov ds:[0], ax
call word ptr ds:[0]
;执行后，(IP)=0123H，(sp)=0EH
```

call dword ptr 内存单元地址

CPU执行此种格式的call指令时，相当于进行：`push CS` `push IP` `jmp dword ptr 内存单元地址`

```asm
mov sp, 10h
mov ax, 0123h
mov ds:[0], ax
mov word ptr ds:[2], 0
call dword ptr ds:[0]
;执行后，(CS)=0，(IP)=0123H，(sp)=0CH
```

## 3、call 和 ret 的配合使用

分析下面程序

```asm
assume cs:code
code segment
start:	mov ax,1
	    mov cx,3
     	call s ;（1）CPU指令缓冲器存放call指令，IP指向下一条指令（mov bx, ax），执行call指令，IP入栈，jmp
     	
	    mov bx,ax	;（4）IP重新指向这里  bx = 8
     	mov ax,4c00h
     	int 21h
     s: add ax,ax
     	loop s;（2）循环3次ax = 8
	    ret;（3）return : pop IP
code ends
end start
```

call 与 ret 指令共同支持了汇编语言编程中的模块化设计，用来编写子程序

## 4、寄存器冲突

在设计子程序时，由于寄存器资源有限，难免会出现子程序和调用程序使用了同一个寄存器，而且子程序还修改了这个寄存器，那么这样就存在巨大的问题。如何解决呢？

> 其实，这个就类似于高级语言的函数调用。既然都要使用某个寄存器，那么就可以这样：当进入子程序时，我们将调用程序寄存器里的数据放到栈里面存放，这样子程序就可以放心使用啦。子程序结束之后，我们再将数据恢复到寄存器里即可。


---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/%E6%B1%87%E7%BC%96%E4%B9%8Bcall%E5%92%8Cret%E6%8C%87%E4%BB%A4/  

