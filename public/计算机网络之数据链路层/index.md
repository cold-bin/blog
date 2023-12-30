# 计算机网络之数据链路层


[toc]

# 3.1、数据链路层概述

## 概述

### 链路与数据链路

**链路**是从一个结点到相邻结点的一段物理线路，**数据链路**则是在链路的基础上增加了一些必要的硬件（如网络适配器）和软件（如协议的实现）。

网络中的主机、路由器等都必须实现数据链路层

![image-20201011102531462](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081933063.png)

局域网中的主机、交换机等都必须实现数据链路层

![image-20201014004326549](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081933111.png)

从层次上来看数据的流动：

![image-20201011102618878](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081937718.png)

仅从数据链路层观察帧的流动：

![image-20201011102653161](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081937016.png)

![image-20201011102733584](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081937655.png)

> 主机H1 到主机H2 所经过的网络可以是多种不同类型的
>
> 注意：不同的链路层可能采用不同的数据链路层协议

### 数据链路层使用的信道

数据链路层属于计算机网路的低层。**数据链路层使用的信道主要有以下两种类型：**

* 点对点信道
* 广播信道

![image-20201014004459744](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081937405.png)

> **局域网属于数据链路层**
>
> 局域网虽然是个网络。但我们并不把局域网放在网络层中讨论。这是因为在网络层要讨论的是多个网络互连的问题，是讨论分组怎么从一个网络，通过路由器，转发到另一个网络。
>
> 而在同一个局域网中，分组怎么从一台主机传送到另一台主机，但并不经过路由器转发。从整个互联网来看，**局域网仍属于数据链路层**的范围



## 三个重要问题

数据链路层传送的协议数据单元是**帧**

### 封装成帧

* **封装成帧** (framing) 就是在一段数据的前后分别添加首部和尾部，然后就构成了一个帧。
* 首部和尾部的一个重要作用就是进行**帧定界**。
* 数据链路层采用的点对点信道的PPP协议封装的**PPP帧**和采用以太网协议的**MAC帧**

![image-20201011110851301](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151606198.png)

> 当发送端出问题，帧没有发送完毕，那么发送端只能重发此帧；此时接收端接收到不完整的帧，会丢弃这个帧。

### 差错控制

在传输过程中可能会产生**比特差错**：1 可能会变成 0， 而 0 也可能变成 1。

![image-20201011103917512](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081937521.png)

> 为了保证数据传输的可靠性，在计算机网络传输数据时，必须采用各种差错检测措施。
>
> - [循环冗余检验CRC](https://blog.csdn.net/TL18382950497/article/details/113794438)
>
>   缺点：可能会检测不出错误，从而导致纠错能力不足

### 透明传输

帧定界符：可以选用ASCII码表中的`SOH(0x01)`作为帧开始定界符，`EOT(0x04)`为帧结束定界符。

如果数据部分出现“EOT”或“SOH”时，那么会使得数据部分拆分出帧，使得帧的解析出现问题，所以要进行字节填充。

具体方法：发送端的数据链路层在数据中出现控制字符“EOT”、“SOH”以及“ESC”，则在前面插入一个转义字符“ESC”的编码。接收端的数据链路层在收到删除这个插入的转义字符。这样用字节填充法解决透明传输的问题。

![img](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081955145.png)

>以上三个问题都是使用**点对点信道的数据链路层**来举例的



**如果使用广播信道的数据链路层除了包含上面三个问题外，还有一些问题要解决**

如图所示，主机A，B，C，D，E通过一根总线进行互连，主机A要给主机C发送数据，代表帧的信号会通过总线传输到总线上的其他各主机，那么主机B，D，E如何知道所收到的帧不是发送给她们的，主机C如何知道发送的帧是发送给自己的

![image-20201011105824466](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081937468.png)

可以用编址（地址）的来解决，将帧的目的地址添加在帧中一起传输

![image-20201011110017415](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306081937445.png)

### 数据碰撞

除了上面三个问题，还有数据碰撞问题

![image-20201011110129994](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151623958.png)

> 随着技术的发展，交换技术的成熟，在 有线（局域网）领域 使用**点对点链路**和**链路层交换机**的**交换式局域网**取代了~~共享式局域网~~；在无线局域网中仍然使用的是共享信道技术
>

------



# 3.2、封装成帧

## 介绍

封装成帧是指数据链路层给上层交付的协议数据单元添加帧头和帧尾使之成为帧

* **帧头和帧尾中包含有重要的控制信息**

![image-20201011110851301](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151625221.png)

发送方的数据链路层将上层交付下来的协议数据单元封装成帧后，还要通过物理层，将构成帧的各比特，转换成电信号交给传输媒体，那么接收方的数据链路层如何从物理层交付的比特流中提取出一个个的帧？

答：需要帧头和帧尾来做**帧定界**

![image-20201011111334052](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151626906.png)

但并不是每一种数据链路层协议的帧都包含有帧定界标志，例如下面例子

![image-20201011111729324](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151630512.png)

> 前导码
>
> * 前同步码：作用是使接收方的时钟同步
> * 帧开始定界符：表明其后面紧跟着的就是MAC帧

另外以太网还规定了帧间间隔为96比特时间，因此，MAC帧不需要帧结束定界符，只需要检测当前比特是否

![image-20201011112450187](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151649949.png)



## 透明传输

> **透明**
>
> 指某一个实际存在的事物看起来却好像不存在一样。

透明传输是指**数据链路层对上层交付的传输数据没有任何限制**，好像数据链路层不存在一样

帧界定标志也就是个特定数据值，如果在上层交付的协议数据单元中，恰好也包含这个特定数值，接收方就不能正确接收

![image-20201011113207944](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151650288.png)

> 所以数据链路层应该对上层交付的数据有限制，其内容不能包含帧定界符的值

**解决透明传输问题**

![image-20201011113804721](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222250287.png)

* **解决方法**：面向字节的物理链路使用**字节填充** (byte stuffing) 或**字符填充** (character stuffing)，面向比特的物理链路使用**比特填充**的方法实现透明传输
* 发送端的数据链路层在数据中出现控制字符“SOH”或“EOT”的前面**插入一个转义字符“ESC”**(其十六进制编码是1B)。
* 接收端的数据链路层在将数据送往网络层之前删除插入的转义字符。
* 如果转义字符也出现在数据当中，那么应在转义字符前面插入一个转义字符 ESC。当接收端收到连续的两个转义字符时，就删除其中前面的一个。 



**帧的数据部分长度**

![image-20201011115008209](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151653058.png)



## 总结

![image-20201011115049672](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151700362.png)



------



# 3.3、差错检测

## 介绍

![image-20201011133757804](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151700479.png)



## 奇偶校验

![image-20201011234428217](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151700552.png)

奇偶检验法只能检测出奇数个错误，不能检测出所有的错误

## 循环冗余校验CRC(Cyclic Redundancy Check)

![image-20201011234605045](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151700553.png)

![image-20201011234701845](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151704343.png)

**例题**

![image-20201011235128869](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151718326.png)

![image-20201011235325022](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151719494.png)

**总结**

![image-20201011235726437](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151722312.png)

> 循环冗余校验 CRC 是一种检错方法，而帧校验序列 FCS 是添加在数据后面的冗余码



------



# 3.4、可靠传输

## 基本概念

**下面是比特差错**

![image-20201012153605893](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222127935.png)

**其他传输差错**

![image-20201012153811724](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222127207.png)

* 分组丢失

路由器输入队列快满了，主动丢弃收到的分组

![image-20201012154910921](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222127664.png)

* 分组失序

数据并未按照发送顺序依次到达接收端

![image-20201012155300937](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222127134.png)

* 分组重复

由于某些原因，有些分组在网络中滞留了，没有及时到达接收端，这可能会造成发送端对该分组的重发，重发的分组到达接收端，但一段时间后，滞留在网络的分组也到达了接收端，这就造成**分组重复**的传输差错

![image-20201012160026362](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222128014.png)



## 三种可靠协议

一般情况下，有线链路的不由数据链路层提供可靠传输，而交由上层解决可靠传输问题；但是无线链路的误码率较高，需要数据链路层提供可靠传输服务。有三种可靠协议实现：

* 停止-等待协议SW
* 回退N帧协议GBN
* 选择重传协议SR

> 这三种可靠传输实现机制的基本原理并不仅限于数据链路层，可以应用到计算机网络体系结构的各层协议中



## 停止-等待协议

### 定义

停止等待协议中，发送方每发送一个分组都必须`等待`接收方的`确认分组ACK（Acknowled Character）`才能发送下一个分组，如果是`否认分组NAK（Negative Acknowledge)`则重传上次发送的分组

<img src="https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222131365.png" alt="image-20201012162009780" style="zoom:67%;" />

### 停止-等待协议可能遇到的问题

**超时重传**

如果发送方分组`丢失`，那么接收方就不会发送`ACK`，此时发送方就会一直等待`ACK`而不能发送数据。为了避免这种情况，发送方主动设置一个`时钟`，如果分组发出后超过了一定的时间没有收到`ACK`就自动`重发`分组，这称为`超时重传`，超时时间一般设置为略大于一个分组`往返`的时间

<img src="https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222131393.png" alt="image-20201012162112151" style="zoom:67%;" />

**确认丢失**

接收方的`确认（否认）分组`也是可能`丢失`的，假设发送方发送了分组并且被接收方接收，接收方的确认分组在传输过程中丢失，那么发送方因为没收到确认分组就会触发超时重传把相同的分组再发送一遍，此时接收方会收到一个重复的分组

为了避免`分组重复`，发送方需要给每个分组`编号`，因为发送方每次只发送一个分组就停下来等待，所以发送方只需使用`一个比特`进行编号就能使分组区分开来

当接收方检查编号发现是重复的分组时就知道上个分组的确认分组丢失了，此时接收方只需`丢弃`收到的分组并发送`ACK`即可，发送方收到`ACK`后也不会再重发分组了

<img src="https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222131980.png" alt="image-20201012162348428" style="zoom:67%;" />

> 既然数据分组需要编号，确认分组是否需要编号？
>
> 要。如下图所示

**确认迟到**

接收方的`ACK`也有可能迟到，发送方发送`分组0`后因为`ACK`迟到触发超时重传再次发送`分组0`，再次发送`分组0`后收到了`迟到的ACK`然后发送方发送`分组1`。假设接收方先收到重传的`分组0`然后发送`ACK`再收到`分组1`，但是发送方收到重传的`分组0`的`ACK`时有可能误认为是`分组1`的`ACK`。为了避免上述情况，`ACK`也需要编号以便发送方确认，同样的`ACK`编号也只需要`一个比特`

<img src="https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222131634.png" alt="image-20201012162815885" style="zoom:67%;" />

> 注意，图中最下面那个数据分组与之前序号为0的那个数据分组不是同一个数据分组

**注意事项**

![image-20201012164008780](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222132289.png)



### 停止-等待协议的信道利用率

假设收发双方之间是一条直通的信道

* **TD**：是发送方发送数据分组所耗费的发送时延
* **RTT**：是收发双方之间的往返时间
* **TA**：是接收方发送确认分组所耗费的发送时延

TA一般都远小于TD，可以忽略，当RTT远大于TD时，**信道利用率会非常低**

![image-20201012164924635](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222138917.png)

![image-20201012181005719](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222140573.png)

![image-20201012181047665](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222140450.png)

> 像停止-等待协议这样通过确认和重传机制实现的可靠传输协议，常称为自动请求重传协议ARQ(**A**utomatic **R**epeat re**Q**uest)，意思是重传的请求是自动进行，因为不需要接收方显式地请求，发送方重传某个发送的分组

由以上的种种情况分析，发送方每发送一个分组都需要等待接收方的回应再做下一步，因此停止等待协议`信道利用率`很低，大多数时间都用来等待了

## 回退N帧协议GBN

### 为什么用回退N帧协议

在相同的时间内，使用停止-等待协议的发送方只能发送一个数据分组，而采用流水线传输的发送方，可以发送多个数据分组

![image-20201012190027828](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222154665.png)



回退N帧协议在流水线传输的基础上，利用发送窗口来限制发送方可连续发送数据分组的个数

![image-20201012190632086](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222155360.png)



### 无差错情况流程

发送方将序号落在发送窗口内的0~4号数据分组，依次连续发送出去

![image-20201012191936466](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222159471.png)



他们经过互联网传输正确到达接收方，就是没有乱序和误码，接收方按序接收它们，每接收一个，接收窗口就向前滑动一个位置，并给发送方发送针对所接收分组的确认分组，在通过互联网的传输正确到达了发送方

![image-20201012192932035](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222200873.png)

发送方每接收一个确认分组，发送窗口就向前滑动一个位置，这样就有新的序号落入发送窗口，发送方可以将收到确认的数据分组从缓存中删除了，而接收方可以择机将已接收的数据分组交付上层处理

![image-20201012193212419](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222202417.png)



### 累计确认

![image-20201012194304696](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222202194.png)

> 累计确认
>
> 优点:
>
> * 即使确认分组丢失，发送方也可能不必重传
> * 减小接收方的开销
> * 减小对网络资源的占用
>
> 缺点：
>
> * 不能向发送方及时反映出接收方已经正确接收的数据分组信息




### 有差错情况

例如

在传输数据分组时，5号数据分组出现误码，接收方通过数据分组中的检错码发现了错误

![image-20201012195440780](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222216988.png)

于是丢弃该分组，而后续到达的这剩下四个分组与接收窗口的序号不匹配

![image-20201012195629368](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222216987.png)

接收同样也不能接收它们，将它们丢弃，并对之前按序接收的最后一个数据分组进行确认，发送ACK4，**每丢弃一个数据分组，就发送一个ACK4**

![image-20201012195836902](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222219529.png)

当收到重复的ACK4时，就知道之前所发送的数据分组出现了差错，于是可以不等超时计时器超时就立刻开始重传，具体收到几个重复确认就立刻重传，根据具体实现决定

![image-20201012200120166](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222220574.png)



 如果收到这4个重复的确认并不会触发发送立刻重传，一段时间后。超时计时器超时，也会将发送窗口内以发送过的这些数据分组全部重传

![image-20201012200454557](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222221192.png)



若WT超过取值范围，例如WT=8，会出现什么情况？

![image-20201012201109774](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222221828.png)

**习题**

![image-20201012202419107](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222222277.png)

**总结**

![image-20201012202222138](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222249247.png)

* 回退N帧协议在流水线传输的基础上利用发送窗口来限制发送方连续发送数据分组的数量，是一种连续ARQ协议
* 在协议的工作过程中发送窗口和接收窗口不断向前滑动，因此这类协议又称为滑动窗口协议
* 由于回退N帧协议的特性，当通信线路质量不好时，其信道利用率并不比停止-等待协议高



## 选择重传协议SR

![image-20201012203638722](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222226295.png)

[具体流程请看视频](https://www.bilibili.com/video/BV1c4411d7jb?p=27)

**习题**

![image-20201012205250996](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222243598.png)

**总结**

![image-20201012204742870](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222243087.png)

![image-20201012205133924](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151724746.png)



------



# 3.5、点对点协议PPP

* 点对点协议PPP（Point-to-Point Protocol）是目前使用最广泛的点对点数据链路层协议
* PPP协议是因特网工程任务组IEIF在1992年制定的。经过1993年和1994年的修订，现在的PPP协议已成为因特网的正式标准[RFC1661，RFC1662]
* 数据链路层使用的一种协议，它的特点是：
  - 简单；
  - 只检测差错，而不是纠正差错（因为在差错检验时，选用的是CRC差错检验技术，CRC差错检验技术并没有纠错能力）
  - 不使用序号，也不进行流量控制；
  - 可同时支持多种网络层协议，例如ip、ipx等协议

![image-20201012210844629](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151724161.png)

* PPPoE 是为宽带上网的主机使用的链路层协议

![image-20201012211423528](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151726199.png)

## 帧格式

必须规定特殊的字符作为帧定界符

![image-20201012211826281](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151726246.png)

## 透明传输

必须保证数据传输的透明性

实现透明传输的方法

* 面向字节的异步链路：字节填充法（插入“转义字符”）

![image-20201012212148803](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151728461.png)

* 面向比特的同步链路：比特填充法（插入“比特0”）

![image-20201012212255550](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151730796.png)

## 差错检测

能够对接收端收到的帧进行检测，并立即丢弃有差错的帧。

![image-20201012212558654](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151730435.png)

## 工作状态

* 当用户拨号接入 ISP 时，路由器的调制解调器对拨号做出确认，并建立一条物理连接。
* PC 机向路由器发送一系列的 LCP 分组（封装成多个 PPP 帧）。
* 这些分组及其响应选择一些 PPP 参数，并进行网络层配置，NCP 给新接入的 PC 机分配一个临时的 IP 地址，使 PC 机成为因特网上的一个主机。
* 通信完毕时，NCP 释放网络层连接，收回原来分配出去的 IP 地址。接着，LCP 释放数据链路层连接。最后释放的是物理层的连接。

![image-20201012213021860](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151732694.png)

> 可见，PPP 协议已不是纯粹的数据链路层的协议，它还包含了物理层和网络层的内容。

------



# 3.6、媒体接入控制（介质访问控制）——广播信道

媒体接入控制（介质访问控制）使用一对多的广播通信方式

> Medium Access Control翻译成媒体接入控制，有些翻译成介质访问控制

**局域网的数据链路层**

* 局域网最主要的**特点**是：
  * 网络为一个单位所拥有；
  * 地理范围和站点数目均有限。 
* 局域网具有如下**主要优点**：
  * 具有广播功能，从一个站点可很方便地访问全网。局域网上的主机可共享连接在局域网上的各种硬件和软件资源。 
  * 便于系统的扩展和逐渐地演变，各设备的位置可灵活调整和改变。
  * 提高了系统的可靠性、可用性和残存性。

![image-20201013201521915](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151737305.png)

![image-20201013201533445](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151737756.png)

数据链路层的两个子层:

为了使数据链路层能更好地适应多种局域网标准，IEEE 802 委员会就将局域网的数据链路层拆成两个子层：

1. **逻辑链路控制** LLC (Logical Link Control)子层；
2. **媒体接入控制** MAC (Medium Access Control)子层。

与接入到传输媒体有关的内容都放在 MAC子层，而 LLC 子层则与传输媒体无关。不管采用何种协议的局域网，对 LLC 子层来说都是透明的。

![image-20201013201133903](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151739679.png)

## 基本概念

为什么要媒体接入控制（介质访问控制）？

**共享信道带来的问题**

若多个设备在共享信道上同时发送数据，则会造成彼此干扰，导致发送失败。

![image-20201013152007335](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151739128.png)

![image-20201013152453425](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151740324.png)

> 随着技术的发展，交换技术的成熟和成本的降低，具有更高性能的使用点对点链路和链路层交换机的交换式局域网在有线领域已完全取代了共享式局域网，但由于无线信道的广播天性，无线局域网仍然使用的是共享媒体技术



## 静态划分信道

**信道复用**

![image-20201013153642544](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151741039.png)

**频分复用FDM (Frequency Division Multiplexing)**

* 将整个带宽分为多份，用户在分配到一定的频带后，在通信过程中自始至终都占用这个频带。

* **频分复用**的所有用户在同样的时间**占用不同的带宽资源**（请注意，这里的“带宽”是频率带宽而不是数据的发送速率）。

![image-20201013153947668](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151741713.png)

**时分复用TDM (Time Division Multiplexing)**

* 时分复用则是将时间划分为一段段等长的时分复用帧（TDM帧）。每一个时分复用的用户在每一个 TDM 帧中占用固定序号的时隙。
* 每一个用户所占用的时隙是**周期性地出现**（其周期就是TDM帧的长度）的。
* TDM 信号也称为**等时** (isochronous) 信号。
* 时分复用的所有用户在不同的时间占用同样的频带宽度。

![image-20201013154142540](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151741055.png)

**波分复用 WDM(Wavelength Division Multiplexing)**

![image-20201013202218132](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151741142.png)

> 波分复用就是光的频分复用，使用一根光纤来同时传输多个光载波信号
>
> 光信号传输一段距离后悔衰减，所以要用 掺铒光纤放大器 放大光信号

**码分复用 CDM  (Code Division Multiplexing)** 

![image-20201013203126625](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151741040.png)

![image-20201013203324709](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151742686.png)

![image-20201013203459640](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151742604.png)

![image-20201013203819578](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151742988.png)



## 动态接入控制

**受控接入**

受控接入在局域网中使用得较少，本书不再讨论

**随机接入**

重点

## 随机接入（CSMA/CD协议）

总线局域网使用协议：CSMA/CD媒体接入控制协议

> CSMA/CD协议曾经用于各种总线结构以太网和双绞线以太网的早起版本中。
>
> 现在的以太网基于交换机和全双工连接，不会有碰撞，因此没有必要使用CSMA/CD协议

### 基本概念

最初的以太网是将许多计算机都连接到一根总线上。易于实现广播通信。当初认为这样的连接方法既简单又可靠，因为总线上没有有源器件。

> 以太网（Ethernet）是一种计算机局域网技术。IEEE组织的IEEE 802.3标准制定了以太网（Ethernet）的技术标准
>
> 以太网采用无连接的工作方式，对发送的数据帧不进行编号，也不要求对方发回确认。目的站收到有差错帧就把它丢弃，其他什么也不做。

![image-20201013211620687](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151743594.png)

![image-20201013213102777](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151743815.png)



### 多址接入MA

表示许多主机以多点接入的方式连接在一根总线上。

![image-20201013215400688](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151743470.png)



### 载波监听CS

是指每一个站在发送数据之前先要检测一下总线上是否有其他计算机在发送数据，如果有，则暂时不要发送数据，以免发生碰撞。以太网的mac帧每隔96比特时间就会传输一个帧，所以，监听的时候只需要监听96比特时间就知道当前信道是否空闲了。

![image-20201013215530979](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151744725.png)

总线上并没有什么“载波”。因此， **“载波监听”就是用电子技术检测总线上有没有其他计算机发送的数据信号。**

### 碰撞检测CD

* “碰撞检测”就是计算机边发送数据边检测信道上的信号电压大小。
* 当几个站同时在总线上发送数据时，总线上的信号电压摆动值将会增大（互相叠加）。
* 当一个站检测到的信号电压摆动值超过一定的门限值时，就认为总线上至少有两个站同时在发送数据，表明产生了碰撞。
* 所谓“碰撞”就是发生了冲突。因此“碰撞检测”也称为“冲突检测”。
* 在发生碰撞时，总线上传输的信号产生了严重的失真，无法从中恢复出有用的信息来。
* 每一个正在发送数据的站，一旦发现总线上出现了碰撞，就要立即停止发送，免得继续浪费网络资源，然后等待一段随机时间后再次发送。

![image-20201013221240514](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151748967.png)

> 为什么要进行碰撞检测？ 因为信号传播时延对载波监听产生了影响
>
> ![image-20201013221834942](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151751980.png)
>
> A 需要单程传播时延的 2 倍的时间，才能检测到与 B 的发送产生了冲突



### CSMA/CD 协议工作流程

![image-20201013221705893](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151751242.png)



### CSMA/CD 协议工作——争用期（碰撞窗口）

![image-20201013223235305](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306151752218.png)



### CSMA/CD 协议工作——最小帧长

![image-20201013224051932](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152034048.png)



### CSMA/CD 协议工作——最大帧长

![image-20201013225400777](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152036151.png)



### CSMA/CD 协议工作——截断二进制指数退避算法

该算法可以用来解决以太网数据发送和传输过程中，站点间的碰撞问题。该算法是在发生碰撞过后确定随机等待时间的时候起作用。随着重传次数增加，那么，再次等待的随机时间就会更长。

![image-20201013230717856](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152037006.png)



### CSMA/CD 协议工作——信道利用率

![image-20201013231430295](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152037671.png)

> 在理想情况下，以太网上的各个站点数据发送与传输不发生冲突，那么计算信道利用率时，就不用考虑争用期了。

### CSMA/CD 协议工作——帧接收流程

![image-20201013231703302](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152040533.png)



### CSMA/CD 协议的重要特性

* 使用 CSMA/CD 协议的以太网不能进行全双工通信而**只能进行双向交替通信（半双工通信）。**
* 每个站在发送数据之后的一小段时间内，存在着遭遇碰撞的可能性。 
* 这种**发送的不确定性**使整个以太网的平均通信量远小于以太网的最高数据率。 

> CSMA/CD协议曾经用于各种总线结构以太网和双绞线以太网的早起版本中。
>
> 现在的以太网基于交换机和全双工连接，不会有碰撞，因此没有必要使用CSMA/CS协议



## 随机接入（CSMA/CA协议）

无线局域网使用的协议：CSMA/CA

### 为什么无线局域网要使用CSMA/CA协议

![image-20201014192811760](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152043311.png)



### 帧间间隔IFS（Inter Frame Space）

![image-20201014200149717](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152051793.png)



### CSMA/CA协议的工作原理

![image-20201014200833233](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152056262.png)

> **源站为什么在检测到信道空闲后还要再等待一段时间DIFS？**
>
> * 考虑到可能有其他的站有高优先级的帧要发送。若有，就要让高优先级帧先发送
>
> **目的站为什么正确接收数据帧后还要等待一段时间SIFS才能发送ACK帧？**
>
> * SIFS是最短的帧间间隔，用来分隔开属于一次对话的各帧，在这段时间内，一个站点应当能够从发送方式切换到接收方式，以便做好接受ACK帧或其他帧的准备。

![image-20201014201511741](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152117268.png)

> **信道由忙转为空闲且经过DIFS时间后，其他站还要退避一段随机时间才能使用信道？**
>
> 防止多个站点同时发送数据而产生碰撞

**使用退避算法的时机**

![image-20201014201927680](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152119784.png)

### CSMA/CA协议的退避算法

![image-20201014202213766](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152120468.png)

**退避算法的示例**

![image-20201014202819851](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152121805.png)

当A正在发送数据时，B, C和D都有数据要发送(用向上的箭头表示)。由于这三个站都检测到信道忙，因此都要执行退避算法，各自随机退避一段时间再发送数据。802. I 1标准规定，退避时间必须是整数倍的时隙时间。前面己经讲过，第i次退避是在时隙{0, 1, ..., 2^2^+i}中随机地选择一个。这样做是为了使不同站点选择相同退避时间的概率减少。因此，第1次退避(i=1)要推迟发送的时间是在时隙{0, 1,…，7}中(共8个时隙)随机选择一个，而第2次退避是在时隙{0, 1,…，15}中(共16个时隙)随机选择一个。当时隙编号达到255时(这对应于第6次退避)就不再增加了。这半决定退避时间的变量，称为退避变量。

退避时间选定后，就相当于设置了一个**退避计时器**(backoff timer)。站点每经历一个时隙的时间就检测一次信道。这可能发生两种情况:

- 若检测到信道空闲，退避计时器就继续倒计时;
- 若检测到信道忙，就冻结退避计时器的剩余时间，重新等待信道变为空闲并再经过时间DIFS后，从剩余时间开始继续倒计时。如果退避计时器的时间减小到零时，就开始发送整个数据帧。

C的退避计时器最先减到零，于是C立即把整个数据帧发送出去。请注意，A发送完数据后信道就变为空闲。C的退避计时器一直在倒计时。当C在发送数据的过程中，B和D检测到信道忙，就冻结各自的退避计时器的数值，重新期待信道变为空闲。正在这时E也想发送数据。由于E检测到信道忙，因此E就执行退避算法和设置退避计时器。   

当C发送完数据并经过了时间DIFS后，B和D的退避计时器又从各自的剩余时间开始倒计时。现在争用信道的除B和D外，还有E、D的退避计时器最先减到零，于是D得到了发送权。在D发送数据时，B和E都冻结其退避计时器。

以后E的退避计时器比B先减少到零。当E发送数据时，B再次冻结其退避计时器。等到E发送完数据并经过时间DIFS后，B的退避计时器才继续工作，一直到把最后剩余的时间用完，然后就发送数据。

冻结退避计时器剩余时间的做法是为了使协议对所有站点更加公平。

### CSMA/CA协议的信道预约和虚拟载波监听

![image-20201014203119710](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152123222.png)



![image-20201014203506878](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152126682.png)

**虚拟载波监听机制能减少隐蔽站带来的碰撞问题的示例**

![image-20201014203859033](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306152127702.png)



------



# 3.7、MAC地址、IP地址以及ARP协议

![image-20201014222831663](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162103735.png)



## MAC地址

> * 使用点对点信道的数据链路层不需要使用地址
> * 使用广播信道的数据链路层必须使用地址来区分各主机

![image-20201014223659993](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221744576.png)



### 广播信道的数据链路层必须使用地址（MAC）

![image-20201014224732019](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221745609.png)

> **MAC地址又称为硬件地址或物理地址**。请注意：不要被 “物理” 二字误导认为物理地址属于物理层范畴，物理地址属于数据链路层范畴



### IEEE 802局域网的MAC地址格式

![image-20201014225358570](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221752304.png)

> **组织唯一标识符OUI**
>
> * 生产网络设备的厂商，需要向IEEE的注册管理机构申请一个或多个OUI
>
> **网络接口标识符**
>
> * 由获得OUI的厂商自行随意分配
>
> **EUI-48**
>
> * 48是这个MAC地址的位数

![image-20201014230248959](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221755962.png)

> 对于使用EUI-48空间的应用程序，IEEE的目标寿命为100年（直到2080年），但是鼓励采用EUI-64作为替代

**关于无效的 MAC 帧**

* 数据字段的长度与长度字段的值不一致；
* 帧的长度不是整数个字节；
* 用收到的帧检验序列 FCS 查出有差错；
* 数据字段的长度不在 46 ~ 1500 字节之间。局域网中，MAC帧会根据以太网协议进行传输，所以最少需要64个字节，然后减去非数据字段字节数得到46
* 有效的 MAC 帧长度为 64 ~ 1518 字节之间。

> 对于检查出的无效 MAC 帧就简单地丢弃。以太网不负责重传丢弃的帧。 



### IEEE 802局域网的MAC地址发送顺序

![image-20201014230625182](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221802931.png)



### 单播MAC地址举例

![image-20201014230822305](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221809241.png)

> 主机B给主机C发送**单播帧**，主机B首先要构建该**单播帧**，**在帧首部中的目的地址字段填入主机C的MAC地址**，源地址字段填入自己的MAC地址，再加上帧首部的其他字段、数据载荷以及帧尾部，就构成了该**单播帧**

![image-20201014231244655](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221809027.png)

> 主机B将该**单播帧**发送出去，主机A和C都会收到该**单播帧**
>
> 主机A的网卡发现该**单播帧**的目的MAC地址与自己的MAC地址不匹配，丢弃该帧
>
> 主机C的网卡发现该**单播帧**的目的MAC地址与自己的MAC地址匹配，接受该帧
>
> 并将该帧交给其上层处理



### 广播MAC地址举例

![image-20201014231754669](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221812272.png)

> 假设主机B要发送一个**广播帧**，主机B首先要构建该**广播帧**，**在帧首部中的目的地址字段填入广播地址**，也就是十六进制的全F，源地址字段填入自己的MAC地址，再加上帧首部中的其他字段、数据载荷以及帧尾部，就构成了该**广播帧**

![image-20201014232132424](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221814181.png)

> 主机B讲该**广播帧**发送出去，主机A和C都会收到该**广播帧**，**发现该帧首部中的目的地址字段的内容是广播地址**，就知道该帧是**广播帧**，主机A和主机C都接受该帧，并将该帧交给上层处理



### 多播MAC地址举例

![image-20201014232714791](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221817698.png)

> 假设主机A要发送**多播帧**给该**多播地址**。将该**多播地址**的左起第一个字节写成8个比特，第一个字节的最低比特位是1，这就表明该地址是**多播地址**。
>
> 快速判断地址是不是**多播地址**，就是上图所示箭头所指的第十六进制数不能整除2（1,3,5,7,9,B,D,F），则该地址是**多播地址**。理解：最低位为1表明一定是个奇数。
>
> 假设主机B，C和D支持多播，各用户给自己的主机配置多播组列表**如下所示**

![image-20201015001243584](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221822460.png)

> 主机B属于两个多播组，主机C也属于两个多播组，而主机D不属于任何多播组

![image-20201015001535528](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221824708.png)

> 主机A首先要构建该**多播帧**，**在帧首部中的目的地址字段填入该多播地址**，源地址点填入自己的MAC地址，再加上帧首部中的其他字段、数据载荷以及帧尾部，就构成了该**多播帧**

![image-20201015002054876](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221827858.png)

> 主机A将该**多播帧**发送出去，主机B、C、D都会收到该**多播帧**
>
> **主机B和C发现该多播帧的目的MAC地址在自己的多播组列表中**，主机B和C都会接受该帧
>
> 主机D发现该**多播帧**的目的MAC地址不在自己的多播组列表中，则丢弃该**多播帧**

> 给主机配置多播组列表进行私有应用时，不得使用公有的标准多播地址



## IP地址

IP地址属于网络层的范畴，不属于数据链路层的范畴

下面内容讲的是IP地址的使用，详细的IP地址内容在网络层中介绍

### 基本概念

![image-20201015104441580](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221826072.png)



### 从网络体系结构看IP地址与MAC地址

![image-20201015104913755](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222051302.png)



### 数据包转发过程中IP地址与MAC地址的变化情况

图上各主机和路由器各接口的IP地址和MAC地址用简单的标识符来表示

![image-20201015105455043](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222054628.png)

![image-20210103212224961](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222058872.png)

> 如何从IP地址找出其对应的MAC地址？
>
> ARP协议



## ARP协议

如何从IP地址找出其对应的MAC地址？

ARP（地址解析协议）

### 流程

![image-20201015113826197](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222101947.png)

ARP高速缓存表

![image-20201015114052206](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222102138.png)

> 当主机B要给主机C发送数据包时，会首先在自己的ARP高速缓存表中查找主机C的IP地址所对应的MAC地址，但未找到，因此，主机B需要发送ARP请求报文，来获取主机C的MAC地址

![image-20201015114444263](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222104645.png)

> ARP请求报文有具体的格式，上图的只是简单描述
>
> ARP请求报文被封装在MAC帧中发送，目的地址为广播地址
>
> 主机B发送封装有ARP请求报文的广播帧，总线上的其他主机都能收到该广播帧

![image-20201015114811501](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222105533.png)

> 收到ARP请求报文的主机A和主机C会把ARP请求报文交给上层的ARP进程
>
> 主机A发现所询问的IP地址不是自己的IP地址，因此不用理会
>
> 主机C的发现所询问的IP地址是自己的IP地址，需要进行相应

![image-20201015115212170](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222107342.png)

![image-20201015115236673](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222109908.png)

![image-20201015115252972](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222109811.png)

动态与静态的区别

![image-20201015115831543](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222109254.png)



**ARP协议只能在一段链路或一个网络上使用，而不能跨网络使用**

![image-20201015120108028](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222110499.png)

> ARP协议的使用是逐段链路进行的



### 总结

![image-20201015120707150](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222110237.png)

> ARP表中的IP地址与MAC地址的对应关系记录，是**会定期自动删除的**，**因为IP地址与MAC地址的对应关系不是永久性的**



------



# 3.8、集线器与交换机的区别

## 集线器-在物理层扩展以太网

### 概念

![image-20201015144628691](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222250819.png)

> * 传统以太网最初是使用粗同轴电缆，后来演进到使用比较便宜的细同轴电缆，最后发展为使用更便宜和更灵活的双绞线。
> * 采用双绞线的以太网采用星形拓扑，在星形的中心则增加了一种可靠性非常高的设备，叫做**集线器** (hub)。
> * **集线器**是也可以看做多口中继器，每个端口都可以成为一个中继器，中继器是对减弱的信号进行放大和发送的设备
> * **集线器**的以太网在逻辑上仍是个总线网，需要使用CSMA/CD协议来协调各主机争用总线，只能工作在半双工模式，收发帧不能同时进行



### 集线器HUB在物理层扩展以太网

**使用集线器扩展**：将多个以太网段连成更大的、多级星形结构的以太网

![image-20201015145732275](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222250339.png)

> * **优点**
>   1. 使原来属于不同碰撞域的以太网上的计算机能够进行跨碰撞域的通信。
>   2. 扩大了以太网覆盖的地理范围。
>
> * **缺点**
>   1. 碰撞域增大了，但总的吞吐量并未提高，反而降低。
>
>      假设两个主机进行数据交换，那么在整个扩展以太网下的所有主机都会收到数据，所以那么其他主机发送数据或传输数据就会发生冲突。显然，这个冲突的可能性反而提高了
>
>   2. 如果不同的碰撞域使用不同的数据率，那么就不能用集线器将它们互连起来。 

**碰撞域**

* **碰撞域（collision domain）**又称为**冲突域**，是指网络中一个站点发出的帧会与其他站点发出的帧产生碰撞或冲突的那部分网络。

  例如：几个主机接到一个集线器上，形成星型拓扑结构，那么一个主机给另外一个主机进行数据交换时，其他主机都能收到数据，因此，其他主机不能发送再发送数据了，否则就会冲突。

  所以，这也是集线器的最大问题，容易导致“广播风暴”。

* 碰撞域越大，发生碰撞的概率越高。

为了解决集线器组装时，冲突越来越大的问题，后面又出现了网桥和交换机来对以太网进行扩展的技术

## 以太网交换机和网桥-在数据链路层扩展以太网

### 概念

* 扩展以太网更常用的方法是在数据链路层进行。
* 早期使用**网桥**，现在使用**以太网交换机**。

![image-20201015150620067](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222250366.png)

> **网桥**
>
> * 网桥工作在数据链路层。
> * 它根据 MAC 帧的目的地址对收到的帧进行转发和过滤。
> * 当网桥收到一个帧时，并不是向所有的接口转发此帧，而是先检查此帧的目的MAC 地址，然后再确定将该帧转发到哪一个接口，或把它丢弃。 
>
> **交换机**
>
> * 1990 年问世的交换式集线器 (switching hub) 可明显地提高以太网的性能。
> * 交换式集线器常称为**以太网交换机** (switch) 或**第二层交换机** (L2 switch)，强调这种交换机工作在数据链路层。
> * 以太网交换机实质上就是一个**多接口的网桥**
>
> 网桥和交换机用户**分割冲突域**，就是网桥和交换机可以较少**被逼的广播(hub导致的)**，但**不能分割广播域**。不严格地说，交换机可以看作网桥的高度集成。



### **集线器HUB与交换机SWITCH区别**

![image-20201015152232158](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251295.png)

> 使用集线器互连而成的共享总线式以太网上的某个主机，要给另一个主机发送单播帧，该单播帧会通过共享总线传输到总线上的其他各个主机
>
> 使用交换机互连而成的交换式以太网上的某个主机，要给另一个主机发送单播帧，该单播帧进入交换机后，交换机会将该单播帧转发给目的主机，而不是网络中的其他各个主机
>
> 这个例子的前提条件是忽略ARP过程，并假设交换机的帧交换表已经学习或配置好了



![image-20201015152858146](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251525.png)

> **以太网交换机的交换方式**
>
> * 存储转发方式
>   * 把整个数据帧**先缓存**后再进行处理。
> * 直通 (cut-through) 方式
>   * 接收数据帧的同时就**立即按数据帧的目的 MAC 地址决定该帧的转发接口**，因而提高了帧的转发速度。
>   * **缺点**是它不检查差错就直接将帧转发出去，因此有可能也将一些无效帧转发给其他的站。
>
> 这个例子的前提条件是忽略ARP过程，并假设交换机的帧交换表已经学习或配置好了



**对比集线器和交换机**

![image-20201015153907268](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251947.png)

![image-20201015154523036](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251613.png)

> 多台主机同时给另一台主机发送单播帧
>
> 集线器以太网：会产生碰撞，遭遇碰撞的帧会传播到总线上的各主机
>
> 交换机以太网：会将它们缓存起来，然后逐个转发给目的主机，不会产生碰撞
>
> **这个例子的前提条件是忽略ARP过程，并假设交换机的帧交换表已经学习或配置好了**



**集线器扩展以太网和交换机扩展以太网区别**

**单播**

![image-20201015155408692](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251589.png)

**广播**

![image-20201015155440402](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251669.png)

**多个单播**

![image-20201015155526386](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251534.png)

![image-20201015155706698](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222251276.png)

广播域（broadcast domain）：指这样一部分网络，其中任何一台设备发出的广播通信都能被该部分网络中的所有其他设备所接收。



## 总结

![image-20201015160146482](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222250004.png)

![image-20201015160526999](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306222252247.png)

> 工作在数据链路层的以太网交换机，其性能远远超过工作在物理层的集线器，而且价格并不贵，这就使得集线器逐渐被市场淘汰



------



# 3.9、以太网交换机自学习和转发帧的流程

## 概念

![image-20201015161015165](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162306893.png)

## 自学习和转发帧的例子

以下例子假设各主机知道网络中其他各主机的MAC地址（无需进行ARP）

**A -> B**

![image-20201015161458528](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162308688.png)

> 1. A 先向 B 发送一帧。该帧从接口 1 进入到交换机
> 2. 交换机收到帧后，先查找（图中左边）交换表。没有查到应从哪个接口转发这个帧给 B
> 3. 交换机把这个帧的源地址 A 和接口 1 写入（图中左边）交换表中
> 4. 交换机向除接口 1 以外的所有的接口广播这个帧
> 5. 接口 4到接口 2，先查找（图中右边）交换表。没有查到应从哪个接口转发这个帧给 B
> 6. 交换机把这个帧的源地址 A 和接口 2 写入（图中右边）交换表中
> 7. 除B主机之外与该帧的目的地址不相符，将丢弃该帧
> 8. 主机B发现是给自己的帧，接受该帧
>
> 可以看到在这个过程中，没有找到目标MAC地址对应的接口时，就将源MAC地址和源主机接接口号记录在表中，之后再将帧进行广播，如果目的MAC地址与源主机相通，则可以将帧接收到。故此，**这个过程学习到了源主机MAC地址和接口**。

**B -> A**

![image-20201015162310922](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306192230725.png)

> 1. B 向 A 发送一帧。该帧从接口 3 进入到交换机
> 2. 交换机收到帧后，先查找（图中左边）交换表。发现（图中左边）交换表中的 MAC 地址有 A，表明要发送给A的帧应从接口1转发出去。于是就把这个帧传送到接口 1 转发给 A。
> 3. 主机 A 发现目的地址是它，就接受该帧
> 4. 交换机把这个帧的源地址 B 和接口 3 写入（图中左边）交换表中
>
> 如果交换机的帧交换表中含有目的主机MAC地址对应的接口号，那么就**不需要进行广播了，直接就将帧传给指定接口。当然，源主机MAC和接口地址没有再帧交换表时，也应该学习到。**

**E -> A**

![image-20201015162622462](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221727168.png)

> 1. E 向 A发送一帧
> 2. 交换机收到帧后，先查找（图中右边）交换表。发现（图中右边）交换表中的 MAC 地址有 A，表明要发送给A的帧应从接口2转发出去。于是就把这个帧传送到接口 2 转发给 接口 4。
> 3. 交换机把这个帧的源地址 E 和接口 3 写入（图中右边）交换表中
> 4. 接口 4 到 左边的交换机，先查找（图中左边）交换表。发现（图中左边）交换表中的 MAC 地址有 A，表明要发送给A的帧应从接口1转发出去。于是就把这个帧传送到接口 1 转发给 A。
> 5. 交换机把这个帧的源地址 E 和接口 4 写入（图中左边）交换表中
> 6. 主机 A 发现目的地址是它，就接受该帧
>
> 这个过程主要是在帧的传播过程中，学习到接口和目的源主机MAC地址的关系。

**G -> A**

![image-20201015163157140](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221732704.png)

> 主机 A、主机 G、交换机 1的接口 1就共享同一条总线（相当于总线式网络，可以想象成用集线器连接了）
>
> 1. 主机 G 发送给 主机 A 一个帧
> 2. 主机 A 和 交换机接口 1都能接收到
> 3. 主机 A 的网卡收到后，根据帧的目的MAC地址A，就知道是发送给自己的帧，就接受该帧
> 4. 交换机 1收到该帧后，首先进行登记工作
> 5. 然后交换机 1对该帧进行转发，该帧的MAC地址是A，在（图中左边）交换表查找MAC 地址有 A
> 6. MAC 地址为 A的接口号是1，但是该帧正是从接口 1 进入交换机的，交换机不会再从该接口 1 将帧转发出去，因为这是没有必要，于是丢弃该帧

随着网络中各主机都发送了帧后，网络中的各交换机就可以学习到各主机的MAC地址，以及它们与自己各接口的对应关系

![image-20201015164210543](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221733484.png)

> 考虑到可能有时要在交换机的接口更换主机，或者主机要更换其网络适配器，这就需要更改交换表中的项目。为此，在交换表中每个项目都设有一定的**有效时间**。**过期的项目就自动被删除**。
>
> **以太网交换机的这种自学习方法使得以太网交换机能够即插即用，不必人工进行配置，因此非常方便。**



## 总结

**交换机自学习和转发帧的步骤归纳**

![image-20201015170656500](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221735583.png)

![image-20201015170739679](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306221739642.png)



------



# 3.10、以太网交换机的生成树协议STP

## 如何提高以太网的可靠性

![image-20201015171453001](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162108660.png)

![image-20201015171515481](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162108822.png)

![image-20201015171900775](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162112915.png)



## 生成树协议STP

为什么要用STP协议？

为了解决第二层网络环路问题而又要保证网络的稳定和健壮性，引入了链路动态管理的策略。

- 首先通过阻塞某些链路避免环路的产生（避免环路）
- 再次当正常工作的链路由于故障断开时，阻塞的链路立刻激活，迅速取代故障链路的位置，保证网络的正常运行。

> IEEE 802.1D 标准制定了一个**生成树协议 STP**  (Spanning Tree Protocol)。
>
> 其**要点**是：**不改变**网络的实际拓扑，但在逻辑上则切断某些链路，使得从一台主机到所有其他主机的路径是**无环路的树状结构**，从而消除了兜圈子现象。

### STP中根桥，根端口，指定端口的选举规则

https://developer.aliyun.com/article/911748

![image-20201015202257756](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162122285.png)



------



# 3.11、虚拟局域网VLAN

## LAN与VLAN

- LAN 表示 Local Area Network，本地局域网。
  一个 LAN 表示一个[广播域](https://so.csdn.net/so/search?q=广播域&spm=1001.2101.3001.7020)，含义是：LAN 中的所有成员都会收到任意一个成员发出的广播包。

  <img src="https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162208471.png" alt="img" style="zoom: 33%;" />

  上图为最基本的LAN布局。如果设备间想要通讯，必须要获取到对方的MAC地址。

  > 举例：A 发信息给 C，A 并不知道 C 的 MAC 地址。此时通过 [ARP](https://so.csdn.net/so/search?q=ARP&spm=1001.2101.3001.7020) 协议（Address Resolution Protocol；地址解析协议；）获取 C 的 MAC 地址，A 先要广播一个包含目标 IP 地址的 ARP 请求到链接在集线器上的所有设备上，C 接受到广播后返回 MAC 地址给 A，其他设备则丢弃信息。至此已经建立设备间通信的准备条件。

- 虚拟局域网（VLAN）是在局域网（LAN）的逻辑上划分成多个广播域，每一个广播域就是一个 VLAN。

  下图为交换机划分虚拟局域网。交换机把一个广播域划分成了3个广播域，物理上这些设备在一个交换机上，但是逻辑上已经分别划分到三个交换机上，所以会有三个局域网（虚拟局域网），三个广播域。

  <img src="https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162211703.png" alt="img" style="zoom: 50%;" />

## 为什么要虚拟局域网VLAN

**广播风暴**

![image-20201015202859124](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162212206.png)

**分割广播域的方法**

![image-20201015203113654](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162215227.png)

> 为了分割广播域，所以虚拟局域网VLAN技术应运而生



## 概念

<img src="https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162216404.png" alt="image-20201015203559548" style="zoom:50%;" />

> * 利用以太网交换机可以很方便地实现虚拟局域网 VLAN (Virtual LAN)。
> * IEEE 802.1Q 对虚拟局域网 VLAN 的**定义**：
>   **虚拟局域网 VLAN** 是由一些局域网网段构成的**与物理位置无关的逻辑组**，而这些网段具有某些共同的需求。每一个 VLAN 的帧都有一个明确的标识符，指明发送这个帧的计算机是属于哪一个 VLAN。
> * 同一个VLAN内部可以广播通信，不同VLAN不可以广播通信
> * **虚拟局域网其实只是局域网给用户提供的一种服务，而并不是一种新型局域网。**
> * 由于虚拟局域网是用户和网络资源的逻辑组合，因此可按照需要将有关设备和资源非常方便地重新组合，使用户从不同的服务器或数据库中存取所需的资源。



## 虚拟局域网VLAN的实现机制

虚拟局域网VLAN技术是在交换机上实现的，需要交换机能够实现以下功能

* 能够处理带有VLAN标记的帧——IEEE 802.1 Q帧
* 交换机的各端口可以支持不同的端口类型，不同端口类型的端口对帧的处理方式有所不同

![image-20201015204639599](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162218030.png)

![image-20201015204749141](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162218152.png)

**Access端口**

交换机与用户计算机之间的互连

![image-20201015205311757](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162218735.png)

> 同一个VLAN内部可以广播通信，不同VLAN不可以广播通信。
>
> 简单来说就是：VLAN相较于LAN的实现上，就是在广播以太网MAC帧的时候，再在这个帧上添加一个4字节的VLAN标记，指明只有满足`PVID==VID`条件才能将广播的以太网MAC帧发送到相同VLAN的交换机的access类型端口连着的主机；其他不满足`PVID==VID`的条件的主机也就是不在一个VLAN下，自然就不能接收到帧。

**Truck端口**

交换机之间 或 交换机与路由器之间的互连

![image-20201015205947636](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162218102.png)



**小例题**

![image-20201015210417695](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162243141.png)



**华为交换机私有的Hybrid端口类型**

![image-20201015211031361](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162243269.png)

![image-20201015211349531](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162243128.png)



## 总结

![image-20201015211512622](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202306162244671.png)

> **虚拟局域网优点**
>
> 虚拟局域网（VLAN）技术具有以下主要优点：
>
> 1. 改善了性能
> 2. 简化了管理
> 3. 降低了成本
> 4. 改善了安全性 


---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%BD%91%E7%BB%9C%E4%B9%8B%E6%95%B0%E6%8D%AE%E9%93%BE%E8%B7%AF%E5%B1%82/  

