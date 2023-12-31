# 汇编之转移指令原理


# 转移指令的原理

------

可以修改`IP`，或同时修改CS和IP的指令统称为转移指令。概括地讲，转移指令就是可以控制CPU执行内存中某处代码的指令。

8086CPU的转移行为有以下几类。

- 只修改`IP`时，称为`段内转移`，比如：`jmp ax`。
- 同时修改`CS`和`IP`时，称为`段间转移`，比如：`jmp 1000:0`。

由于转移指令对`IP`的修改范围不同，段内转移又分为：`短转移和近转移`。

- 短转移`IP`的修改范围为`-128 ~ 127`。
- 近转移`IP`的修改范围为`-32768 ~ 32767`。

8086CPU的转移指令分为以下几类。

- 无条件转移指令（如：`jmp`）
- 条件转移指令
- 循环指令（如：`loop`）
- 过程
- 中断

## 1、操作符offset

操作符offset在汇编语言中是由编译器处理的符号，它的功能是取得标号的偏移地址。

```asm
;将s处的一条指令复制到s0处
assume cs:codesg
codesg segment
 s:   mov ax, bx           ;（mov ax,bx 的机器码占两个字节）
      mov si, offset s     ;获得标号s的偏移地址
      mov di, offset s0    ;获得标号s0的偏移地址
      
      mov ax, cs:[si]
      mov cs:[di], ax
 s0:  nop                     ;（nop的机器码占一个字节）
      nop
 codesg ends
 ends
```

## 2、`jmp`指令

`jmp`为无条件转移，转到标号处执行指令可以只修改IP，也可以同时修改CS和IP；

`jmp`指令要给出两种信息：

- 转移的目的地址
- 转移的距离（段间转移、段内短转移，段内近转移）

 `jmp short 标号` `jmp near ptr 标号` `jcxz 标号` `loop 标号` 等几种汇编指令，它们对 IP的修改

是根据转移目的地址和转移起始地址之间的位移来进行的。在它们对应的机器码中不包含转移的目的地址，而包含的是到目的地址的位移距离。

### 1、依据位移进行转移的`jmp`指令

`jmp short 标号`（段内短转移）

指令“`jmp short 标号`”的功能为`(IP)=(IP)+8位位移`，转到标号处执行指令

（1）8位位移 = “标号”处的地址 - `jmp`指令后的第一个字节的地址；

（2）short指明此处的位移为8位位移；

（3）8位位移的范围为-128~127，用补码表示

（4）8位位移由编译程序在编译时算出。

```asm
assume cs:codesg
codesg segment
  start:mov ax,0
        jmp short s ;s不是被翻译成目的地址
        add ax, 1
      s:inc ax ;程序执行后， ax中的值为 1 
codesg ends
end start
```

CPU不需要这个目的地址就可以实现对IP的修改。这里是依据位移进行转移

**`jmp short s`指令的读取和执行过程：**

1. (CS)=0BBDH，(IP)=0006，上一条指令执行结束后`CS:IP`指向`EB 03`（`jmp short s`的机器码）；
2. 读取指令码`EB 03`进入指令缓冲器；
3. (IP) = (IP) + 所读取指令的长度 = (IP) + 2 = 0008，`CS:IP`指向`add ax,1`；
4. CPU指行指令缓冲器中的指令`EB 03`；
5. 指令`EB 03`执行后，(IP)=000BH，`CS:IP`指向`inc ax`

`jmp near ptr 标号` （段内近转移）

指令“`jmp near ptr 标号`”的功能为：`(IP) = (IP) + 16位位移`。

### 2、转移的目的地址在指令中的`jmp`指令

`jmp far ptr 标号`（段间转移或远转移）

指令 “`jmp far ptr 标号`” 功能如下：

- (CS) = 标号所在段的段地址；
- (IP) = 标号所在段中的偏移地址。
- `far ptr`指明了指令用标号的段地址和偏移地址修改`CS`和`IP`。

```asm
assume cs:codesg
codesg segment
   start: mov ax, 0
		  mov bx, 0
          jmp far ptr  s ;s被翻译成转移的目的地址0B01 BD0B
          db 256 dup (0) ;转移的段地址：0BBDH，偏移地址：010BH
    s:    add ax,1
          inc ax
codesg ends
end start
12345678910
```

![在这里插入图片描述](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/20190322151439754.png)

### 3、转移地址在寄存器或内存中的jmp指令

```
jmp 16位寄存器
```

功能：`IP` =（16位寄存器）

转移地址在内存中的`jmp`指令有两种格式：

- `jmp word ptr 内存单元地址`（段内转移）

功能：从内存单元地址处开始存放着一个字，是转移的目的偏移地址。

```asm
mov ax, 0123H
mov ds:[0], ax
jmp word ptr ds:[0]
;执行后，(IP)=0123H
```

- `jmp dword ptr 内存单元地址`（段间转移）

功能：从内存单元地址处开始存放着两个字，高地址处的字是转移的目的段地址，低地址处是转移的目的偏移地址。

1. (CS)=(内存单元地址+2)
2. (IP)=(内存单元地址)

```asm
mov ax, 0123H
mov ds:[0], ax;偏移地址
mov word ptr ds:[2], 0;段地址
jmp dword ptr ds:[0]
;执行后，
;(CS)=0
;(IP)=0123H
;CS:IP 指向 0000:0123。
```

### 4、`jcxz`指令和`loop`指令

**`jcxz`指令**

`jcxz`指令为有条件转移指令，所有的有条件转移指令都是短转移，

在对应的机器码中包含转移的位移，而不是目的地址。对IP的修改范围都为`-128~127`。

指令格式：`jcxz 标号`（如果(cx)=0，则转移到标号处执行。）

当(cx) = 0时，(IP) = (IP) + 8位位移

- 8位位移 = “标号”处的地址 - `jcxz`指令后的第一个字节的地址；
- 8位位移的范围为-128~127，用补码表示；
- 8位位移由编译程序在编译时算出。

当(cx)!=0时，什么也不做（程序向下执行）

**`loop`指令**

loop指令为循环指令，所有的循环指令都是短转移，在对应的机器码中包含转移的位移，而不是目的地址。

对IP的修改范围都为`-128~127`。

指令格式：`loop 标号` ((cx) = (cx) - 1，如果(cx) ≠ 0，转移到标号处执行)。

(cx) = (cx) - 1；如果 (cx) != 0，(IP) = (IP) + 8位位移。

- 8位位移 = 标号处的地址 - `loop`指令后的第一个字节的地址；
- 8位位移的范围为`-128~127`，用补码表示；
- 8位位移由编译程序在编译时算出。

如果（cx）= 0，什么也不做（程序向下执行）。

## 3、总结

- 转移指令时，都是以下一个指令的偏移量为依据，如果是下一个指令的目标地址，那么这段程序就不能随意放到某个地址了。使用偏移量就可以很好解决这个问题：无论这段代码放到哪里都可以通过位移来找寻指令
- 归根结底，指令其实就是`cs:ip`指向地址的内容，那么我们要转移指令，就是修改`cs:ip`的指向地址
- 实现循环：每次循环体结束都会返回到循环代码的头部，那么如何实现呢？答案就是：转移指令，每当循环执行完毕时，我们就将指令转移到循环体头部；
- 实现if-else：类似循环，不过使用的是条件转移指令


---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/%E6%B1%87%E7%BC%96%E4%B9%8B%E8%BD%AC%E7%A7%BB%E6%8C%87%E4%BB%A4%E5%8E%9F%E7%90%86/  

