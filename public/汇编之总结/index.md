# 汇编之总结


# 指令系统总结

我们对8086CPU的指令系统进行一下总结。读者若要详细了解8086指令系统中的各个指令的用，可以查看有关的指令手册。

8086CPU提供以下几大类指令。

1. 数据传送指令
   `mov、push、pop、pushf、popf、xchg` 等都是数据传送指令，这些指令实现寄存器和内存、寄器和寄存器之间的单个数据传送。
2. 算术运算指令
   `add、sub、adc、sbb、inc、dec、cmp、imul、idiv、aaa`等都是算术运算指令，这些指令实现存器和内存中的数据的算数运算。它们的执行结果影响标志寄存器的`sf、zf、of、cf、pf、af`位。
3. 逻辑指令
   `and、or、not、xor、test、shl、shr、sal、sar、rol、ror、rcl、rcr`等都是逻辑指令。除了not指外，它们的执行结果都影响标志寄存器的相关标志位。
4. 转移指令
   可以修改IP，或同时修改CS和IP的指令统称为转移指令。转移指令分为以下几类。
   （1）无条件转移指令，比如，`jmp`；
   （2）条件转移指令，比如，`jcxz、je、jb、ja、jnb、jna`等；
   （3）循环指令，比如，`loop`；
   （4）过程，比如，`call、ret、retf`；
   （5）中断，比如，`int、iret`。
5. 处理机控制指令
   对标志寄存器或其他处理机状态进行设置，`cld、std、cli、sti、nop、clc、cmc、stc、hlt、wait、esc、lock`等都是处理机控制指令。
6. 串处理指令
   对内存中的批量数据进行处理，`movsb、movsw、cmps、scas、lods、stos`等。若要使用这些指令方便地进行批量数据的处理，则需要和`rep、repe、repne` 等前缀指令配合使用。


---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/%E6%B1%87%E7%BC%96%E4%B9%8B%E6%80%BB%E7%BB%93/  

