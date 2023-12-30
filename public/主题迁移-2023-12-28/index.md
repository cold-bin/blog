# 主题迁移 2023-12-28


使用github action构建自动交付与持续集成，algolia构建全文搜索引擎
<!--more-->

### 主题部分功能不生效

本地部署生效，但是vercel部署失效，主要原因是vercel的hugo默认版本太老了，需要手动指定`HUGO_VERSION`环境变量，启用支持shortcodes等的版本。

### 切换algolia搜索

原先博客是使用的`lunr`作为搜索实现，但是只能搜索英文，对于中文不能很好的检索，于是便使用了`algolia`全文搜索引擎。

{{< admonition info >}}

Algolia 是一个托管搜索引擎，提供全文、数字和分面搜索，能够通过第一次击键提供实时结果。Algolia 强大的 API 可让您在网站和移动应用程序中快速、无缝地实施搜索。我们的搜索 API 每月为数千家公司提供数十亿次查询，在世界任何地方在 100 毫秒内提供相关结果。

{{< /admonition >}}

在本站点所使用主题`LoveIt`已经集成了`algolia`，原作者认为配置`algolia`的索引文件比较麻烦，于是便自己想实现一个，最初是使用的官方的`algolia cli`，但是会出现`bufio.Reader: token is too long`的源码错误。于是乎，在网上冲浪看到了使用github action自动上传索引文件的项目，便采用之。

最后，workflows依然会出现一点问题，主要是我的索引文件比较大，需要裁减一下`conten-length`


---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/%E4%B8%BB%E9%A2%98%E8%BF%81%E7%A7%BB-2023-12-28/  

