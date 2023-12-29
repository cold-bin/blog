# Redis高级篇之分布式缓存


[toc]

# 基于Redis集群解决单机Redis存在的问题

单机的Redis存在四大问题：

![image-20210725144240631](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725144240631.png)

# 分布式缓存

# 1.Redis持久化

Redis有两种持久化方案：

- RDB持久化
- AOF持久化

## 1.1.RDB持久化

RDB全称Redis Database Backup file（Redis数据备份文件），也被叫做Redis数据快照。简单来说就是把内存中的所有数据都记录到磁盘中。当Redis实例故障重启后，从磁盘读取快照文件，恢复数据。快照文件称为RDB文件，默认是保存在当前运行目录。

### 1.1.1.执行时机

RDB持久化在四种情况下会执行：

- 执行`save`命令
- 执行`bgsave`命令
- Redis停机时
- 触发RDB条件时

**1）`save`命令**

执行下面的命令，可以立即执行一次RDB：

![image-20210725144536958](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725144536958.png)

`save`命令会导致主进程执行RDB，这个过程中其它所有命令都会被阻塞。只有在数据迁移时可能用到。



**2）`bgsave`命令**

下面的命令可以异步执行RDB：

![image-20210725144725943](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725144725943.png)

这个命令执行后会开启独立进程完成RDB，主进程可以持续处理用户请求，不受影响。



**3）停机时**

Redis停机时会执行一次`save`命令，实现RDB持久化。



**4）触发RDB条件**

Redis内部有触发RDB的机制，可以在`redis.conf`文件中找到，格式如下：

```properties
# 900秒内，如果至少有1个key被修改，则执行bgsave ， 如果是save "" 则表示禁用RDB
save 900 1 
# 依次类推
save 300 10  
save 60 10000 
```

RDB的其它配置也可以在`redis.conf`文件中设置：

```properties
# 是否压缩 ,建议不开启，压缩也会消耗cpu，磁盘的话不值钱
rdbcompression yes

# RDB文件名称
dbfilename dump.rdb  

# 文件保存的路径目录
dir ./ 
```

> SAVE  保存是阻塞主进程，客户端无法连接redis，等SAVE完成后，主进程才开始工作，客户端可以连接
>
> BGSAVE  是fork一个save的子进程，在执行save过程中，不影响主进程，客户端可以正常链接redis，等子进程fork执行save完成后，通知主进程，子进程关闭。

### 1.1.2.RDB原理

RDB持久化是指在指定的时间间隔内将redis内存中的数据集快照写入磁盘，实现原理是redis服务在指定的时间间隔内先`fork`一个子进程，由子进程将数据集写入临时文件，写入成功后，再替换之前的文件，用二进制压缩存储，生成`dump.rdb`文件存放在磁盘中。

![image.png](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/6w4x54kwa7p4m_e0896752f4e84346a9e44d56612a4896.png)

`fork`采用的是copy-on-write技术：

- 当主进程执行读操作时，访问共享内存；
- 当主进程执行写操作时，则会拷贝一份数据，执行写操作。

![image-20210725151319695](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725151319695.png)

### 1.1.3.小结

**RDB方式`bgsave`的基本流程？**

- `fork`主进程得到一个子进程，共享内存空间
- 子进程读取内存数据并写入新的RDB文件
- 用新RDB文件替换旧的RDB文件

**RDB会在什么时候执行？`save 60 1000`代表什么含义？**

- 默认是服务停止时
- 代表60秒内至少执行1000次修改则触发RDB

**RDB优点？**

- 一旦采用该方式，那么你的整个Redis数据库将只包含一个文件，这对于文件备份而言是非常完美的。比如，你可能打算每个小时归档一次最近24小时的数据，同时还要每天归档一次最近30天的数据。通过这样的备份策略，一旦系统出现灾难性故障，我们可以非常容易的进行恢复。
- 对于灾难恢复而言，RDB是非常不错的选择。因为我们可以非常轻松的将一个单独的文件压缩后再转移到其它存储介质上。
- 性能最大化。对于Redis的服务进程而言，在开始持久化(`bgsave`)时，它唯一需要做的只是`fork`出子进程，之后再由子进程完成这些持久化的工作，这样就可以极大的避免服务进程执行IO操作了。(`save`会阻塞主进程)
- 相比于AOF机制，如果数据集很大，RDB的启动效率会更高。

**RDB的缺点？**

- RDB执行间隔时间长，两次RDB之间写入数据有丢失的风险
- 当内存里数据集较大时，`fork`子进程、压缩、写出RDB文件都比较耗时，那么`fork`子进程就比较消耗性能，容易拖垮服务

## 1.2.AOF持久化



### 1.2.1.AOF原理

AOF全称为Append Only File（追加文件）。Redis处理的每一个写命令都会记录在AOF文件，可以看做是命令日志文件。

![image-20210725151543640](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725151543640.png)



### 1.2.2.AOF配置

AOF默认是关闭的，需要修改`redis.conf`配置文件来开启AOF：

```properties
# 是否开启AOF功能，默认是no
appendonly yes
# AOF文件的名称
appendfilename "appendonly.aof"
```

AOF的命令记录的频率也可以通过`redis.conf`文件来配：

```properties
# 表示每执行一次写命令，立即记录到AOF文件
appendfsync always 
# 写命令执行完先放入AOF缓冲区，然后表示每隔1秒将缓冲区数据写到AOF文件，是默认方案
appendfsync everysec
# 写命令执行完先放入AOF缓冲区，由操作系统决定何时将缓冲区内容写回磁盘
appendfsync no
```

三种策略对比：

![image-20210725151654046](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725151654046.png)



### 1.2.3.AOF文件重写

因为是记录命令，AOF文件会比RDB文件大的多。而且AOF会记录对同一个key的多次写操作，但只有最后一次写操作才有意义。通过执行`bgrewriteaof`命令，可以让AOF文件执行重写功能，用最少的命令达到相同效果。

![image-20210725151729118](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725151729118.png)

如图，AOF原本有三个命令，但是`set num 123` 和 `set num 666`都是对`num`的操作，第二次会覆盖第一次的值，因此第一个命令记录下来没有意义。

所以重写命令后，AOF文件内容就是：`mset name jack num 666`

Redis也会在触发阈值时自动去重写AOF文件。阈值也可以在redis.conf中配置：

```properties
# AOF文件比上次文件增长超过多少百分比，则触发重写
auto-aof-rewrite-percentage 100
# AOF文件体积最小多大以上才触发重写
auto-aof-rewrite-min-size 64mb
```



## 1.3.RDB与AOF对比

RDB和AOF各有自己的优缺点，如果对数据安全性要求较高，在实际开发中往往会**结合**两者来使用。

![image-20210725151940515](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725151940515.png)



# 2.Redis主从

## 2.1.搭建主从架构

单节点Redis的并发能力是有上限的，要进一步提高Redis的并发能力，就需要搭建主从集群，实现读写分离。

像MySQL一样，redis是支持主从同步的，而且也支持一主多从以及多级从结构。 主从结构，一是为了纯粹的冗余备份，二是为了提升读性能，比如很消耗性能的SORT就可以由从服务器来承担。 redis的主从同步是异步进行的，这意味着主从同步不会影响主逻辑，也不会降低redis的处理性能。 主从架构中，可以考虑关闭主服务器的数据持久化功能，只让从服务器进行持久化，这样可以提高主服务器的处理性能。

![image-20210725152037611](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725152037611.png) 

## 2.2.主从数据同步原理

### 2.2.1.全量同步

主从第一次建立连接时，会执行**全量同步**，将master节点的所有数据都拷贝给slave节点，流程：

![image-20210725152222497](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725152222497.png)



这里有一个问题，master如何得知salve是第一次来连接呢？？

有几个概念，可以作为判断依据：

- **Replication Id**：简称replid，是数据集的标记，id一致则说明是同一数据集。每一个master都有唯一的replid，slave则会继承master节点的replid
- **offset**：偏移量，随着记录在repl_baklog中的数据增多而逐渐增大。slave完成同步时也会记录当前同步的offset。如果slave的offset小于master的offset，说明slave数据落后于master，需要更新。

因此slave做数据同步，必须向master声明自己的replication id 和offset，master才可以判断到底需要同步哪些数据。

因为slave原本也是一个master，有自己的replid和offset，当第一次变成slave，与master建立连接时，发送的replid和offset是自己的replid和offset。

master判断发现slave发送来的replid与自己的不一致，说明这是一个全新的slave，就知道要做全量同步了。

master会将自己的replid和offset都发送给这个slave，slave保存这些信息。以后slave的replid就与master一致了。

因此，**master判断一个节点是否是第一次同步的依据，就是看replid是否一致**。

如图：

![image-20210725152700914](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725152700914.png)



完整流程描述：

- slave节点请求增量同步
- master节点判断replid，发现不一致，拒绝增量同步，开启全量同步
- master将完整内存数据生成RDB，发送RDB到slave
- slave清空本地数据，加载master的RDB
- master将RDB期间的命令记录在repl_baklog，并持续将log中的命令发送给slave
- slave执行接收到的命令，保持与master之间的同步



### 2.2.2.增量同步

全量同步需要先做RDB，然后将RDB文件通过网络传输个slave，成本太高了。因此除了第一次做全量同步，其它大多数时候slave与master都是做**增量同步**。

什么是增量同步？就是只更新slave与master存在差异的部分数据。如图：

![image-20210725153201086](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725153201086.png)

那么master怎么知道slave与自己的数据差异在哪里呢?

### 2.2.3.repl_backlog原理

master怎么知道slave与自己的数据差异在哪里呢?

这就要说到全量同步时的repl_baklog文件了。

这个文件是一个固定大小的数组，只不过数组是环形，也就是说**角标到达数组末尾后，会再次从0开始读写**，这样数组头部的数据就会被覆盖。

repl_baklog中会记录Redis处理过的命令日志及offset，包括master当前的offset，和slave已经拷贝到的offset：

![image-20210725153359022](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725153359022.png) 

slave与master的offset之间的差异，就是salve需要增量拷贝的数据了。

随着不断有数据写入，master的offset逐渐变大，slave也不断的拷贝，追赶master的offset：

![image-20210725153524190](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725153524190.png) 

直到数组被填满：

![image-20210725153715910](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725153715910.png) 

此时，如果有新的数据写入，就会覆盖数组中的旧数据。不过，旧的数据只要是绿色的，说明是已经被同步到slave的数据，即便被覆盖了也没什么影响。因为未同步的仅仅是红色部分。

但是，如果slave出现网络阻塞，导致master的offset远远超过了slave的offset： 

![image-20210725153937031](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725153937031.png) 

如果master继续写入新数据，其offset就会覆盖旧的数据，直到将slave现在的offset也覆盖：

![image-20210725154155984](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725154155984.png) 

棕色框中的红色部分，就是尚未同步，但是却已经被覆盖的数据。此时如果slave恢复，需要同步，却发现自己的offset都没有了，无法完成增量同步了。只能做全量同步。

![image-20210725154216392](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725154216392.png)

## 2.3.主从同步优化

主从同步可以保证主从数据的一致性，非常重要

可以从以下几个方面来优化Redis主从就集群：

- 在master中配置`repl-diskless-sync yes`启用无磁盘复制，避免全量同步时的磁盘IO。
- Redis单节点上的内存占用不要太大，减少RDB导致的过多磁盘IO
- 适当提高repl_baklog的大小，发现slave宕机时尽快实现故障恢复，尽可能避免全量同步
- 限制一个master上的slave节点数量，如果实在是太多slave，则可以采用主-从-从链式结构，减少master压力

主从从架构图：

![image-20210725154405899](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725154405899.png)



## 2.4.小结

简述全量同步和增量同步区别？

- 全量同步：master将完整内存数据生成RDB，发送RDB到slave。后续命令则记录在repl_baklog，逐个发送给slave
- 增量同步：slave提交自己的offset到master，master获取repl_baklog中从offset之后的命令给slave

什么时候执行全量同步？

- slave节点第一次连接master节点时
- slave节点断开时间太久，repl_baklog中的offset已经被覆盖时

什么时候执行增量同步？

- slave节点断开又恢复，并且在repl_baklog中能找到offset时





# 3.Redis哨兵

Redis提供了哨兵（Sentinel）机制来**实现主从集群的自动故障恢复**。

## 3.1.哨兵原理

### 3.1.1.集群结构和作用

哨兵的结构如图：

![image-20210725154528072](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725154528072.png)

哨兵的作用如下：

- **监控**：Sentinel 会不断检查您的master和slave是否按预期工作
- **自动故障恢复**：如果master故障，Sentinel会将一个slave提升为master。当故障实例恢复后也以新的master为主
- **通知**：Sentinel充当Redis客户端的服务发现来源，当集群发生故障转移时，会将最新信息推送给Redis的客户端

### 3.1.2.集群监控原理

Sentinel基于心跳机制监测服务状态，每隔1秒向集群的每个实例发送ping命令：

- 主观下线：如果某sentinel节点发现某实例未在规定时间响应，则认为该实例**主观下线**。
- 客观下线：若超过指定数量（quorum）的sentinel都认为该实例主观下线，则该实例**客观下线**。quorum值最好超过Sentinel实例数量的一半。

![image-20210725154632354](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725154632354.png)



### 3.1.3.集群故障恢复原理

一旦发现master故障，sentinel需要在salve中选择一个作为新的master，选择依据是这样的：

- 首先会判断slave节点与master节点断开时间长短，如果超过指定值（down-after-milliseconds * 10）则会排除该slave节点
- 然后判断slave节点的slave-priority值，越小优先级越高，如果是0则永不参与选举
- 如果slave-prority一样，则判断slave节点的offset值，越大说明数据越新，优先级越高
- 最后是判断slave节点的运行id大小，越小优先级越高。

当选出一个新的master后，该如何实现切换呢？

流程如下：

- sentinel给备选的slave1节点发送`slaveof no one`命令，让该节点成为master
- sentinel给所有其它slave发送`slaveof 192.168.150.101 7002`命令，让这些slave成为新master的从节点，开始从新的master上同步数据。
- 最后，sentinel将故障节点标记为slave，当故障节点恢复后会自动成为新的master的slave节点

![image-20210725154816841](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725154816841.png)

### 3.1.4.小结

Sentinel的三个作用是什么？

- 监控
- 故障转移
- 通知

Sentinel如何判断一个redis实例是否健康？

- 每隔1秒发送一次ping命令，如果超过一定时间没有相向则认为是主观下线
- 如果大多数sentinel都认为实例主观下线，则判定服务下线

故障转移步骤有哪些？

- 首先选定一个slave作为新的master，执行`slaveof no on`命令
- 然后让所有节点都执行`slaveof 新master主机 端口号`
- 修改故障节点配置，添加`slaveof 新master 端口号`



## 3.2.搭建哨兵集群



## 3.3.RedisTemplate

在Sentinel集群监管下的Redis主从集群，其节点会因为自动故障转移而发生变化，Redis的客户端必须感知这种变化，及时更新连接信息。Spring的RedisTemplate底层利用lettuce实现了节点的感知和自动切换。

下面，我们通过一个测试来实现RedisTemplate集成哨兵机制。

### 3.3.1.导入Demo工程

首先，我们引入课前资料提供的Demo工程：

![image-20210725155124958](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725155124958.png) 



### 3.3.2.引入依赖

在项目的pom文件中引入依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```



### 3.3.3.配置Redis地址

然后在配置文件application.yml中指定redis的sentinel相关信息：

```java
spring:
  redis:
    sentinel:
      master: mymaster
      nodes:
        - 192.168.150.101:27001
        - 192.168.150.101:27002
        - 192.168.150.101:27003
```



### 3.3.4.配置读写分离

在项目的启动类中，添加一个新的bean：

```java
@Bean
public LettuceClientConfigurationBuilderCustomizer clientConfigurationBuilderCustomizer(){
    return clientConfigurationBuilder -> clientConfigurationBuilder.readFrom(ReadFrom.REPLICA_PREFERRED);
}
```



这个bean中配置的就是读写策略，包括四种：

- MASTER：从主节点读取
- MASTER_PREFERRED：优先从master节点读取，master不可用才读取replica
- REPLICA：从slave（replica）节点读取
- REPLICA _PREFERRED：优先从slave（replica）节点读取，所有的slave都不可用才读取master





# 4.Redis分片集群

## 4.1.搭建分片集群

主从和哨兵可以解决高可用、高并发读的问题。但是依然有两个问题没有解决：

- 海量数据存储问题：我们知道，主从集群模式下，redis的单个master就将所有数据饱揽下来。那么这样始终有一天，面临内存不足的问题，某些关键数据可能会被LRU所淘汰。
- 高并发写的问题：虽然主从架构可以提高并发读的性能，但是对于高并发写性能提升意义不大。因为在主从集群下，master只要一个，也就是redis的写只能写在一个master节点上（虽然我们利用主从集群抽离master上的读命令执行，但依然提升有限）。问题主要出现在master只有一个，而且redis执行命令都是单线程的，只能一条一条的执行。那么解决方案显而易见：我们可以多选几个master出来执行写命令。而且这几个master的数据是不一致的，这样可以减轻主从集群模式下，单节点master数据存储的压力。

使用分片集群可以解决上述问题（分片感觉就是多个集群有机结合），如图:

![image-20210725155747294](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725155747294.png)



分片集群特征：

- 集群中有多个master，每个master**保存不同数据**

- 每个master都可以有多个slave节点

- master之间通过ping监测彼此健康状态

- 客户端请求可以访问集群任意节点，最终都会被转发到正确节点

  这里面最大的问题是：请求如何知道自己的数据在哪个master？那么就涉及到查找和寻址的问题，典型的解决方案就是哈希的思想，我们将

## 4.2.散列插槽

### 4.2.1.插槽原理

Redis会把每一个master节点映射到`0~16383`共`16384`个插槽（hash slot）上，查看集群信息时就能看到：

![image-20210725155820320](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725155820320.png)



数据key不是与节点绑定，而是与插槽绑定。redis会根据key的有效部分计算插槽值，分两种情况：

- key中包含"{}"，且“{}”中至少包含1个字符，“{}”中的部分是有效部分
- key中不包含“{}”，整个key都是有效部分

例如：key是num，那么就根据num计算，如果是`{itcast}num`，则根据itcast计算。计算方式是利用CRC16算法得到一个hash值，然后对`16384`取余，得到的结果就是slot值。

![image-20210725155850200](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725155850200.png) 

如图，在7001这个节点执行`set a 1`时，对a做hash运算，对16384取余，得到的结果是15495，因此要存储到7003节点。

到了7003后，执行`get num`时，对num做hash运算，对16384取余，得到的结果是2765，因此需要切换到7001节点

**散列过程里存在一个巨严重的问题：**

> 当我们需要增删redis分片集群的master节点时，那么hash的散列表映射长度发生变化，那么就会导致后续请求的master节点命中失败。
>
> 那么怎么解决呢？这时候就需要引入高级一点的哈希————一致性哈希
>
> redis的一致性哈希有三大特性：
>
> - key哈希结果尽可能分配到不同Redis实例
> - 当实例增加或移除，需要保护已映射的内容不会重新被分配到新实例上
> - 对key的哈希应尽量避免重复
>
> 
>
> **分片实现：**
> 前面谈到主从切换的哨兵模式已经提到，哨兵模式可以实现高可用以及读写分离，但是缺点在于所有Redis实例存储的数据全部一致，所以Redis支持cluster模式，可以简单将cluster理解为Redis集群管理的一个插件，通过它可以实现Redis的分布式存储。
>
> 数据分片方式一般有三种：客户端分片、代理分片和服务器分片。
>
> **1）客户端分片**
>
> - 定义：客户端自己计算key需要映射到哪一个Redis实例。
> - 优点：客户端分片最明显的好处在于降低了集群的复杂度，而服务器之间没有任何关联性，数据分片由客户端来负责实现。
> - 缺点：客户端实现分片则客户端需要知道当前集群下不同Redis实例的信息，**当新增Redis实例时需要支持动态分片，多数Redis需要重启才能实现该功能**。
>
> **2）代理分片**
>
> - 定义：客户端将请求发送到代理，代理通过计算得到需要映射的集群实例信息，然后将客户端的请求转发到对应的集群实例上，然后返回响应给客户端。
> - 优点：降低了客户端的复杂度，客户端不用关心后端Redis实例的状态信息。
> - 缺点：多了一个中间分发环节，所以对性能有些取的损失。
>
> **3）服务器分片**
>
> - 定义：客户端可以和集群中任意Redis实例通信，当客户端访问某个实例时，服务器进行计算key应该映射到哪个具体的Redis实例中存储，如果映射的实例不是当前实例，则该实例主动引导客户端去对应实例对key进行操作。这其实是一个重定向的过程**。**这个过程不是从当前Redis实例转发到对应的Redis实例，而是客户端收到服务器通知具体映射的Redis实例重定向到映射的实例中。**当前还不能完全适用于生产环境。**
> - 优点：支持高可用，任意实例都有主从，主挂了从会自动接管。
> - 缺点：需要客户端语言实现服务器集群协议，但是目前大多数语言都有其客户端实现版本。
>
> **4）预分片**
> 从上面可以清楚地看出，**分片机制增加或移除实例是非常麻烦的一件事**，所以我们可以考虑一开始就开启32个节点实例，当我们可以新增Redis服务器时，我们可以将一半的节点移动到新的Redis服务器。这样我们只需要在新服务器启动一个空节点，然后移动数据，配置新节点为源节点的从节点，然后更新被移动节点的ip信息，然后向新服务器发送`slaveof`命令关闭主从配置，最后关闭旧服务器不需要使用的实例并且重新启动客户端。这样我们就可以在几乎不需要停机时间时完成数据的移动。
>
> 
>
> **分片机制的缺点**
>
> - 分片是由多台Redis实例共同运转，所以如果其中一个Redis实例宕机，则整个分片都将无法使用，所以分片机制无法实现高可用。
> - 如果有不同的key映射到不同的Redis实例，**这时候不能对这两个key做交集或者使用事务**。=> 单机上的redis事务不支持，只有使用分布式事务
> - 使用分片机制因为涉及多实例，数据处理比较复杂。
> - 分片中对于实例的添加或删除会很复杂，不过可以使用预分片技术进行改善。

### 4.2.1.小结

Redis如何判断某个key应该在哪个实例？

- 将16384个插槽分配到不同的实例
- 根据key的有效部分计算哈希值，对16384取余
- 余数作为插槽，寻找插槽所在实例即可

如何将同一类数据固定的保存在同一个Redis实例？

- 这一类数据使用相同的有效部分，例如key都以{typeId}为前缀

[redis分片机制详解](https://zhuanlan.zhihu.com/p/367227866)

## 4.3.集群伸缩

redis-cli --cluster提供了很多操作集群的命令，可以通过下面方式查看：

![image-20210725160138290](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725160138290.png)

比如，添加节点的命令：

![image-20210725160448139](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725160448139.png)



### 4.3.1.需求分析

需求：向集群中添加一个新的master节点，并向其中存储 num = 10

- 启动一个新的redis实例，端口为7004
- 添加7004到之前的集群，并作为一个master节点
- 给7004节点分配插槽，使得num这个key可以存储到7004实例

这里需要两个新的功能：

- 添加一个节点到集群中
- 将部分插槽分配到新插槽

### 4.3.2.创建新的redis实例

创建一个文件夹：

```sh
mkdir 7004
```

拷贝配置文件：

```sh
cp redis.conf /7004
```

修改配置文件：

```sh
sed /s/6379/7004/g 7004/redis.conf
```

启动

```sh
redis-server 7004/redis.conf
```

### 4.3.3.添加新节点到redis

添加节点的语法如下：

![image-20230115171427313](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20230115171427313.png)

执行命令：

```sh
redis-cli --cluster add-node  192.168.150.101:7004 192.168.150.101:7001
```

通过命令查看集群状态：

```sh
redis-cli -p 7001 cluster nodes
```

如图，7004加入了集群，并且默认是一个master节点：

![image-20210725161007099](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161007099.png)

但是，可以看到7004节点的插槽数量为0，因此没有任何数据可以存储到7004上

### 4.3.4.转移插槽

我们要将num存储到7004节点，因此需要先看看num的插槽是多少：

![image-20210725161241793](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161241793.png)

如上图所示，num的插槽为2765.

我们可以将0~3000的插槽从7001转移到7004，命令格式如下：

![image-20210725161401925](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161401925.png)



具体命令如下：

建立连接：

![image-20210725161506241](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161506241.png)

得到下面的反馈：

![image-20210725161540841](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161540841.png)

询问要移动多少个插槽，我们计划是3000个：

新的问题来了：

![image-20210725161637152](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161637152.png)

那个node来接收这些插槽？？

显然是7004，那么7004节点的id是多少呢？

![image-20210725161731738](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161731738.png)

复制这个id，然后拷贝到刚才的控制台后：

![image-20210725161817642](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725161817642.png)

这里询问，你的插槽是从哪里移动过来的？

- all：代表全部，也就是三个节点各转移一部分
- 具体的id：目标节点的id
- done：没有了

这里我们要从7001获取，因此填写7001的id：

![image-20210725162030478](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725162030478.png)

填完后，点击done，这样插槽转移就准备好了：

![image-20210725162101228](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725162101228.png)

确认要转移吗？输入yes：

然后，通过命令查看结果：

![image-20210725162145497](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725162145497.png) 

可以看到： 

![image-20210725162224058](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725162224058.png)

目的达成。

## 4.4.故障转移

集群初识状态是这样的：

![image-20210727161152065](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210727161152065.png)

其中7001、7002、7003都是master，我们计划让7002宕机。

### 4.4.1.自动故障转移

当集群中有一个master宕机会发生什么呢？

直接停止一个redis实例，例如7002：

```sh
redis-cli -p 7002 shutdown
```

1）首先是该实例与其它实例失去连接

2）然后是疑似宕机：

![image-20210725162319490](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725162319490.png)

3）最后是确定下线，自动提升一个slave为新的master：

![image-20210725162408979](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725162408979.png)

4）当7002再次启动，就会变为一个slave节点了：

![image-20210727160803386](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210727160803386.png)

### 4.4.2.手动故障转移

利用cluster failover命令可以手动让集群中的某个master宕机，切换到执行cluster failover命令的这个slave节点，实现无感知的数据迁移。其流程如下：

![image-20210725162441407](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210725162441407.png)

这种failover命令可以指定三种模式：

- 缺省：默认的流程，如图1~6歩
- force：省略了对offset的一致性校验
- takeover：直接执行第5歩，忽略数据一致性、忽略master状态和其它master的意见

**案例需求**：在7002这个slave节点执行手动故障转移，重新夺回master地位

步骤如下：

1）利用redis-cli连接7002这个节点

2）执行cluster failover命令

如图：

![image-20210727160037766](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20210727160037766.png)

效果：

![image-20230115171831415](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/image-20230115171831415.png)

## 4.5.RedisTemplate访问分片集群

RedisTemplate底层同样基于lettuce实现了分片集群的支持，而使用的步骤与哨兵模式基本一致：

1）引入redis的starter依赖

2）配置分片集群地址

3）配置读写分离

与哨兵模式相比，其中只有分片集群的配置方式略有差异，如下：

```yaml
spring:
  redis:
    cluster:
      nodes:
        - 192.168.150.101:7001
        - 192.168.150.101:7002
        - 192.168.150.101:7003
        - 192.168.150.101:8001
        - 192.168.150.101:8002
        - 192.168.150.101:8003
```




