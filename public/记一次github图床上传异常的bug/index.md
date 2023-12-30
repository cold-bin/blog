# 记一次github图床上传异常的bug




## 记一次picgo+github图床上传失败的过程

### 问题

这次遇到一个非常非常奇怪的问题。我和往常一样使用picgo在github上上传图片。但是突然没有预兆的给我报了`err: connected etimedout`的错误（指连接超时）。

我`ping`了一下`api.github.com`，发现链路不通，数据包送不过去，但是浏览器还可以请求`api.github.com`。

上网冲浪后得知：应该是服务端设置了相关策略对网络层icmp回显请求报文进行了限制；而访问网页用的是http协议，因此会出现此现象。

所以这个现象聊胜于无。

后来看到picgo的[issue](https://github.com/Molunerfinn/PicGo/issues/1167)中，有不少人都提了这个问题。

## 解决

其实这个就是系统代理本身的问题了：并不是所有软件或工具的网络请求都会走系统代理，有些应用的网络请求可能绕过代理，直接与网络通信。

所以，我们需要给picgo手动设置代理，让picgo的所有请求一定要经过代理。如下图：

我们在picgo中设置了vpn的服务端口。这样所有请求就可以转发到这里，包括一些外网的请求。

![image-20230822163253429](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img2/202308221632138.png)

因此，解决了代理问题。

## 意外惊喜

我最近一直遇到这样问题：我明明已经开了梯子，但为什么我在bash中`git pull`或`git push`时总是报这个两个错：

```
fatal: unable to access 'https://github.com/cold-bin/cold-bin.github.io.git/': OpenSSL SSL_read: Connection was reset, errno 10054
```

or

```
fatal: unable to access 'https://github.com/cold-bin/cold-bin.github.io.git/': Failed to connect to github.com port 443 after 21109 ms: Timed out
```

其实和上面的问题一样，有些软件不走你的系统代理，直接走网络通信。解决方案也和上面一样：给git设置vpn代理的端口。

```bash
git config --global http.proxy http://127.0.0.1:7890 
git config --global https.proxy http://127.0.0.1:7890
# 我的clash在7890上系统代理
```



---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/%E8%AE%B0%E4%B8%80%E6%AC%A1github%E5%9B%BE%E5%BA%8A%E4%B8%8A%E4%BC%A0%E5%BC%82%E5%B8%B8%E7%9A%84bug/  

