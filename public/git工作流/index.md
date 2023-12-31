# Git工作流


## 关于版本控制

什么是版本控制？我为什么要关心它呢？

版本控制是一种记录一个或若干文件内容变化，以便将来查阅特定版本修订情况的系统。

在本书所展示的例子中，我们仅对保存着软件源代码的文本文件作版本控制管理，但实际上，你可以对任何类型的文件进行版本控制。

如果你是位图形或网页设计师，可能会需要保存某一幅图片或页面布局文件的所有修订版本（这或许是你非常渴望拥有的功能）。采用版本控制系统（VCS）是个明智的选择。有了它你就可以将某个文件回溯到之前的状态，甚至将整个项目都回退到过去某个时间点的状态。你可以比较文件的变化细节，查出最后是谁修改了哪个地方，从而找出导致怪异问题出现的原因，又是谁在何时报告了某个功能缺陷等等。使用版本控制系统通常还意味着，就算你乱来一气把整个项目中的文件改的改删的删，你也照样可以轻松恢复到原先的样子。但额外增加的工作量却微乎其微。



### 本地版本控制系统

许多人习惯用复制整个项目目录的方式来保存不同的版本，或许还会改名加上备份时间以示区别。这么做唯一的好处就是简单。不过坏处也不少：有时候会混淆所在的工作目录，一旦弄错文件丢了数据就没法撤销恢复。

为了解决这个问题，人们很久以前就开发了许多种本地版本控制系统，大多都是采用某种简单的数据库来记录文件的历次更新差异（见图）。

![image-20220825170047827](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251700825.png)

其中最流行的一种叫做 rcs，现今许多计算机系统上都还看得到它的踪影。甚至在流行的 Mac OS X 系统上安装了开发者工具包之后，也可以使用 rcs 命令。它的工作原理基本上就是保存并管理文件补丁（patch）。文件补丁是一种特定格式的文本文件，记录着对应文件修订前后的内容变化。所以，根据每次修订后的补丁，rcs 可以通过不断打补丁，计算出各个版本的文件内容。

### 集中化的版本控制系统

接下来人们又遇到一个问题，如何让在不同系统上的开发者协同工作？于是，集中化的版本控制系统（ Centralized Version Control Systems，简称 CVCS ）应运而生。这类系统，诸如 CVS，Subversion 以及 Perforce 等，都有一个单一的集中管理的服务器，保存所有文件的修订版本，而协同工作的人们都通过客户端连到这台服务器，取出最新的文件或者提交更新。多年以来，这已成为版本控制系统的标准做法（见图 1-2）。

![image-20220825170151371](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251701461.png)

这种做法带来了许多好处，特别是相较于老式的本地 VCS 来说。现在，每个人都可以在一定程度上看到项目中的其他人正在做些什么。而管理员也可以轻松掌控每个开发者的权限，并且管理一个 CVCS 要远比在各个客户端上维护本地数据库来得轻松容易。

事分两面，有好有坏。这么做最显而易见的缺点是中央服务器的单点故障。如果宕机一小时，那么在这一小时内，谁都无法提交更新，也就无法协同工作。要是中央服务器的磁盘发生故障，碰巧没做备份，或者备份不够及时，就会有丢失数据的风险。最坏的情况是彻底丢失整个项目的所有历史更改记录，而被客户端偶然提取出来的保存在本地的某些快照数据就成了恢复数据的希望。但这样的话依然是个问题，你不能保证所有的数据都已经有人事先完整提取出来过。本地版本控制系统也存在类似问题，只要整个项目的历史记录被保存在单一位置，就有丢失所有历史更新记录的风险。

### 分布式版本控制系统

于是分布式版本控制系统（ Distributed Version Control System，简称 DVCS ）面世了。在这类系统中，像 Git，Mercurial，Bazaar 以及 Darcs 等，客户端并不只提取最新版本的文件快照，而是把代码仓库完整地镜像下来。这么一来，任何一处协同工作用的服务器发生故障，事后都可以用任何一个镜像出来的本地仓库恢复。因为每一次的提取操作，实际上都是一次对代码仓库的完整备份（见图）。

![image-20220825170331645](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251703173.png)

更进一步，许多这类系统都可以指定和若干不同的远端代码仓库进行交互。籍此，你就可以在同一个项目中，分别和不同工作小组的人相互协作。你可以根据需要设定不同的协作流程，比如层次模型式的工作流，而这在以前的集中式系统中是无法实现的。

## Git 基础

那么，简单地说，Git 究竟是怎样的一个系统呢？请注意，接下来的内容非常重要，若是理解了 Git 的思想和基本工作原理，用起来就会知其所以然，游刃有余。在开始学习 Git 的时候，请不要尝试把各种概念和其他版本控制系统（诸如 Subversion 和 Perforce 等）相比拟，否则容易混淆每个操作的实际意义。Git 在保存和处理各种信息的时候，虽然操作起来的命令形式非常相近，但它与其他版本控制系统的做法颇为不同。理解这些差异将有助于你准确地使用 Git 提供的各种工具。

#### 直接记录快照，而非差异比较

Git 和其他版本控制系统的主要差别在于，Git 只关心文件数据的整体是否发生变化，而大多数其他系统则只关心文件内容的具体差异。这类系统（CVS，Subversion，Perforce，Bazaar 等等）每次记录有哪些文件作了更新，以及都更新了哪些行的什么内容，请看图。

![image-20220825170701889](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251707322.png)

Git 并不保存这些前后变化的差异数据。实际上，Git 更像是把变化的文件作快照后，记录在一个微型的文件系统中。每次提交更新时，它会纵览一遍所有文件的指纹信息并对文件作一快照，然后保存一个指向这次快照的索引。为提高性能，若文件没有变化，Git 不会再次保存，而只对上次保存的快照作一链接。Git 的工作方式就像图 1-5 所示。

![image-20220825170802339](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251708719.png)

这是 Git 同其他系统的重要区别。它完全颠覆了传统版本控制的套路，并对各个环节的实现方式作了新的设计。Git 更像是个小型的文件系统，但它同时还提供了许多以此为基础的超强工具，而不只是一个简单的 VCS。稍后在第三章讨论 Git 分支管理的时候，我们会再看看这样的设计究竟会带来哪些好处。

#### 近乎所有操作都是本地执行

在 Git 中的绝大多数操作都只需要访问本地文件和资源，不用连网。但如果用 CVCS 的话，差不多所有操作都需要连接网络。因为 Git 在本地磁盘上就保存着所有当前项目的历史更新，所以处理起来速度飞快。

举个例子，如果要浏览项目的历史更新摘要，Git 不用跑到外面的服务器上去取数据回来，而直接从本地数据库读取后展示给你看。所以任何时候你都可以马上翻阅，无需等待。如果想要看当前版本的文件和一个月前的版本之间有何差异，Git 会取出一个月前的快照和当前文件作一次差异运算，而不用请求远程服务器来做这件事，或是把老版本的文件拉到本地来作比较。

用 CVCS 的话，没有网络或者断开 VPN 你就无法做任何事情。但用 Git 的话，就算你在飞机或者火车上，都可以非常愉快地频繁提交更新，等到了有网络的时候再上传到远程仓库。同样，在回家的路上，不用连接 VPN 你也可以继续工作。换作其他版本控制系统，这么做几乎不可能，抑或非常麻烦。比如 Perforce，如果不连到服务器，几乎什么都做不了（译注：默认无法发出命令 p4 edit file 开始编辑文件，因为 Perforce 需要联网通知系统声明该文件正在被谁修订。但实际上手工修改文件权限可以绕过这个限制，只是完成后还是无法提交更新。）；如果是 Subversion 或 CVS，虽然可以编辑文件，但无法提交更新，因为数据库在网络上。看上去好像这些都不是什么大问题，但实际体验过之后，你就会惊喜地发现，这其实是会带来很大不同的。

#### 时刻保持数据完整性

在保存到 Git 之前，所有数据都要进行内容的校验和（checksum）计算，并将此结果作为数据的唯一标识和索引。换句话说，不可能在你修改了文件或目录之后，Git 一无所知。这项特性作为 Git 的设计哲学，建在整体架构的最底层。所以如果文件在传输时变得不完整，或者磁盘损坏导致文件数据缺失，Git 都能立即察觉。

Git 使用 SHA-1 算法计算数据的校验和，通过对文件的内容或目录的结构计算出一个 SHA-1 哈希值，作为指纹字符串。该字串由 40 个十六进制字符（0-9 及 a-f）组成，看起来就像是：`24b9da6552252987aa493b52f8696cd6d3b00373`

Git 的工作完全依赖于这类指纹字串，所以你会经常看到这样的哈希值。实际上，所有保存在 Git 数据库中的东西都是用此哈希值来作索引的，而不是靠文件名。

#### 多数操作仅添加数据 

常用的 Git 操作大多仅仅是把数据添加到数据库。因为任何一种不可逆的操作，比如删除数据，都会使回退或重现历史版本变得困难重重。在别的 VCS 中，若还未提交更新，就有可能丢失或者混淆一些修改的内容，但在 Git 里，一旦提交快照之后就完全不用担心丢失数据，特别是养成定期推送到其他仓库的习惯的话。

这种高可靠性令我们的开发工作安心不少，尽管去做各种试验性的尝试好了，再怎样也不会弄丢数据。至于 Git 内部究竟是如何保存和恢复数据的，我们会在第九章讨论 Git 内部原理时再作详述。

#### 文件的三种状态

好，现在请注意，接下来要讲的概念非常重要。对于任何一个文件，在 Git 内都只有三种状态：已提交（committed），已修改（modified）和已暂存（staged）。已提交表示该文件已经被安全地保存在本地数据库中了；已修改表示修改了某个文件，但还没有提交保存；已暂存表示把已修改的文件放在下次提交时要保存的清单中。

由此我们看到 Git 管理项目时，文件流转的三个工作区域：Git 的工作目录，暂存区域，以及本地仓库。

![image-20220825171053205](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251710914.png)

每个项目都有一个 Git 目录（译注：如果 git clone 出来的话，就是其中 .git 的目录；如果 git clone --bare 的话，新建的目录本身就是 Git 目录。），它是 Git 用来保存元数据和对象数据库的地方。该目录非常重要，每次克隆镜像仓库的时候，实际拷贝的就是这个目录里面的数据。

从项目中取出某个版本的所有文件和目录，用以开始后续工作的叫做工作目录。这些文件实际上都是从 Git 目录中的压缩对象数据库中提取出来的，接下来就可以在工作目录中对这些文件进行编辑。

所谓的暂存区域只不过是个简单的文件，一般都放在 Git 目录中。有时候人们会把这个文件叫做索引文件，不过标准说法还是叫暂存区域。

#### 基本的 Git 工作流程如下

1. 在工作目录中修改某些文件。
2. 对修改后的文件进行快照，然后保存到暂存区域。
3. 提交更新，将保存在暂存区域的文件快照永久转储到 Git 目录中。

所以，我们可以从文件所处的位置来判断状态：如果是 Git 目录中保存着的特定版本文件，就属于已提交状态；如果作了修改并已放入暂存区域，就属于已暂存状态；如果自上次取出后，作了修改但还没有放到暂存区域，就是已修改状态。到第二章的时候，我们会进一步了解其中细节，并学会如何根据文件状态实施后续操作，以及怎样跳过暂存直接提交。

## Git 常用命令

### git add

把要提交的文件的信息添加到暂存区中。当使用 `git commit` 时，将依据暂存区中的内容提交至本地库。

它通常将现有路径的当前内容作为一个整体添加，但是通过一些选项，它也可以用于添加内容，只对所应用的工作树文件进行一些更改，或删除工作树中不存在的路径了。

“索引”保存工作树内容的快照，并且将该快照作为下一个提交的内容。 因此，在对工作树进行任何更改之后，并且在运行 `git commit` 命令之前，必须使用 `git add` 命令将任何新的或修改的文件添加到索引。

该命令可以在提交之前多次执行。它只在运行 `git add` 命令时添加指定文件的内容; 如果希望随后的更改包含在下一个提交中，那么必须再次运行 `git add` 将新的内容添加到索引。

```bash
# 把指定的文件添加到暂存区中
$ git add <文件路径>

# 添加所有修改、已删除的文件到暂存区中
$ git add -u [<文件路径>]
$ git add --update [<文件路径>]

# 添加所有修改、已删除、新增的文件到暂存区中，省略 <文件路径> 即为当前目录
$ git add -A [<文件路径>]
$ git add --all [<文件路径>]

# 查看所有修改、已删除但没有提交的文件，进入一个子命令系统
$ git add -i [<文件路径>]
$ git add --interactive [<文件路径>]
```

### git branch

操作 Git 的分支命令。

```bash
# 列出本地的所有分支，当前所在分支以 "*" 标出
$ git branch

# 列出本地的所有分支并显示最后一次提交，当前所在分支以 "*" 标出
$ git branch -v

# 创建新分支，新的分支基于上一次提交建立
$ git branch <分支名>

# 修改分支名称
# 如果不指定原分支名称则为当前所在分支
$ git branch -m [<原分支名称>] <新的分支名称>
# 强制修改分支名称
$ git branch -M [<原分支名称>] <新的分支名称>

# 删除指定的本地分支
$ git branch -d <分支名称>

# 强制删除指定的本地分支
$ git branch -D <分支名称>
```

### git checkout

更新工作树中的文件以匹配索引或指定树中的版本。如果没有给出路径 - `git checkout` 还会更新 `HEAD` ，将指定的分支设置为当前分支。

```bash
# 切换到已存在的指定分支
$ git checkout <分支名称>

# 创建并切换到指定的分支，保留所有的提交记录
# 等同于 "git branch" 和 "git checkout" 两个命令合并
$ git checkout -b <分支名称>

# 创建并切换到指定的分支，删除所有的提交记录
$ git checkout --orphan <分支名称>

# 替换掉本地的改动，新增的文件和已经添加到暂存区的内容不受影响
$ git checkout <文件路径>
```

> `git checkout` 是 git 最常用的命令之一，同时也是一个很危险的命令，因为这条命令会重写工作区。

### git clone

将存储库克隆到新创建的目录中，为克隆的存储库中的每个分支创建远程跟踪分支(使用 `git branch -r` 可见)，并从克隆检出的存储库作为当前活动分支的初始分支。

```bash
# 默认在当前目录下创建和版本库名相同的文件夹并下载版本到该文件夹下
$ git clone <远程仓库的网址>

# 指定本地仓库的目录
$ git clone <远程仓库的网址> <本地目录>

# -b 指定要克隆的分支，默认是master分支
$ git clone <远程仓库的网址> -b <分支名称> <本地目录>
```

### git stash

**暂存当前修改**

`git stash`会把所有未提交的修改（包括暂存的和非暂存的）都保存起来，用于后续恢复当前工作目录。
比如下面的中间状态，通过`git stash`命令推送一个新的储藏，当前的工作目录就干净了。

注意：stash是本地的，不会通过`git push`命令上传到git server上。

实际应用中推荐给每个stash加一个message，用于记录版本，使用`git stash save`取代`git stash`命令。示例如下：

```bash
git stash save "test-cmd-stash"
```

**重新应用缓存的stash**

可以通过`git stash pop`命令恢复之前缓存的工作目录

```bash
git stash pop
```

这个指令将缓存堆栈中的第一个stash删除，并将对应修改应用到当前的工作目录下。

你也可以使用`git stash apply`命令，将缓存堆栈中的stash多次应用到工作目录中，但并不删除stash拷贝。

```bash
git stash apply
```

在使用`git stash apply`命令时可以通过名字指定使用哪个stash，默认使用最近的stash（即stash@{0}）。

**查看现有stash**

可以使用`git stash list`命令，一个典型的输出如下：

```bash
git stash list
stash@{0}: WIP on master: 049d078 added the index file
stash@{1}: WIP on master: c264051 Revert "added file_size"
stash@{2}: WIP on master: 21d80a5 added number to log
```

**移除stash**

可以使用`git stash drop`命令，后面可以跟着stash名字。下面是一个示例：

```bash
$ git stash list
stash@{0}: WIP on master: 049d078 added the index file
stash@{1}: WIP on master: c264051 Revert "added file_size"
stash@{2}: WIP on master: 21d80a5 added number to log
$ git stash drop stash@{0}
Dropped stash@{0} (364e91f3f268f0900bc3ee613f9f733e82aaed43)
```

或者使用`git stash clear`命令，删除所有缓存的stash。

**暂存未跟踪或忽略的文件**

默认情况下，`git stash`会缓存下列文件：

- 添加到暂存区的修改（staged changes）
- Git跟踪的但并未添加到暂存区的修改（unstaged changes）

但不会缓存一下文件：

- 在工作目录中新的文件（untracked files）
- 被忽略的文件（ignored files）

`git stash`命令提供了参数用于缓存上面两种类型的文件。使用`-u`或者`--include-untracked`可以stash untracked文件。使用`-a`或者`--all`命令可以stash当前目录下的所有修改。

### git commit

将索引的当前内容与描述更改的用户和日志消息一起存储在新的提交中。

```bash
# 把暂存区中的文件提交到本地仓库，调用文本编辑器输入该次提交的描述信息
$ git commit

# 把暂存区中的文件提交到本地仓库中并添加描述信息
$ git commit -m "<提交的描述信息>"

# 把所有修改、已删除的文件提交到本地仓库中
# 不包括未被版本库跟踪的文件，等同于先调用了 "git add -u"
$ git commit -a -m "<提交的描述信息>"

# 修改上次提交的描述信息
$ git commit --amend
```

### git config

主要是用来配置 Git 的相关参数，其主要操作有：

```bash
# 查看配置信息
# --local：仓库级，--global：全局级，--system：系统级
$ git config < --local | --global | --system > -l

# 查看当前生效的配置信息
$ git config -l

# 编辑配置文件
# --local：仓库级，--global：全局级，--system：系统级
$ git config < --local | --global | --system > -e

# 添加配置项
# --local：仓库级，--global：全局级，--system：系统级
$ git config < --local | --global | --system > --add <name> <value>

# 获取配置项
$ git config < --local | --global | --system > --get <name>

# 删除配置项
$ git config < --local | --global | --system > --unset <name>

# 配置提交记录中的用户信息
$ git config --global user.name <用户名>
$ git config --global user.email <邮箱地址>

# 更改Git缓存区的大小
# 如果提交的内容较大，默认缓存较小，提交会失败
# 缓存大小单位：B，例如：524288000（500MB）
$ git config --global http.postBuffer <缓存大小>

# 调用 git status/git diff 命令时以高亮或彩色方式显示改动状态
$ git config --global color.ui true

# 配置可以缓存密码，默认缓存时间15分钟
$ git config --global credential.helper cache

# 配置密码的缓存时间
# 缓存时间单位：秒
$ git config --global credential.helper 'cache --timeout=<缓存时间>'

# 配置长期存储密码
$ git config --global credential.helper store
```

> Git 一共有3个配置文件：

1. 仓库级的配置文件：在仓库的 `.git/.gitconfig`，该配置文件只对所在的仓库有效。
2. 全局配置文件：Mac 系统在 `~/.gitconfig`，Windows 系统在 `C:\Users\<用户名>\.gitconfig`。
3. 系统级的配置文件：在 Git 的安装目录下（Mac 系统下安装目录在 `/usr/local/git`）的 `etc` 文件夹中的 `gitconfig`。



### git diff

用于显示提交和工作树等之间的更改。

此命令比较的是工作目录中当前文件和暂存区域快照之间的差异,也就是修改之后还没有暂存起来的变化内容。

```bash
# 比较当前文件和暂存区中文件的差异，显示没有暂存起来的更改
$ git diff

# 比较暂存区中的文件和上次提交时的差异
$ git diff --cached
$ git diff --staged

# 比较当前文件和上次提交时的差异
$ git diff HEAD

# 查看从指定的版本之后改动的内容
$ git diff <commit ID>

# 比较两个分支之间的差异
$ git diff <分支名称> <分支名称>

# 查看两个分支分开后各自的改动内容
$ git diff <分支名称>...<分支名称>
```

### git fetch

从远程仓库获取最新的版本到本地的 tmp 分支上。

```bash
# 将远程仓库所有分支的最新版本全部取回到本地
$ git fetch <远程仓库的别名>

# 将远程仓库指定分支的最新版本取回到本地
$ git fetch <远程主机名> <分支名>
```

### git init

初始化项目所在目录，初始化后会在当前目录下出现一个名为 .git 的目录。

```bash
# 初始化本地仓库，在当前目录下生成 .git 文件夹
$ git init
```

### git log

显示提交的记录。

```bash
# 打印所有的提交记录
$ git log

# 打印从第一次提交到指定的提交的记录
$ git log <commit ID>

# 打印指定数量的最新提交的记录
$ git log -<指定的数量>
```

### git merge

用于将两个或两个以上的开发历史加入(合并)一起。

```bash
# 把指定的分支合并到当前所在的分支下，并自动进行新的提交
$ git merge <分支名称>

# 把指定的分支合并到当前所在的分支下，不进行新的提交
$ git merge --no-commit <分支名称>
```

### git mv

重命名文件或者文件夹。

```bash
# 重命名指定的文件或者文件夹
$ git mv <源文件/文件夹> <目标文件/文件夹>
```

### git pull

从远程仓库获取最新版本并合并到本地。 首先会执行 `git fetch`，然后执行 `git merge`，把获取的分支的 HEAD 合并到当前分支。

```bash
# 从远程仓库获取最新版本。
$ git pull

# 从origin远程仓库的main分支拉取代码到本地，一般需要加上 --allow-unrelated-histories 参数忽略提交历史的差异。然后在本地合并冲突
$ git remote add origin 连接 #（http or ssh）
$ git pull origin main --allow-unrelated-histories
```

### git push

把本地仓库的提交推送到远程仓库。

```bash
# 把本地仓库的分支推送到远程仓库的指定分支
$ git push <远程仓库的别名> <本地分支名>:<远程分支名>

# 删除指定的远程仓库的分支
$ git push <远程仓库的别名> :<远程分支名>
$ git push <远程仓库的别名> --delete <远程分支名>

```

### git remote

操作远程库。

```bash
# 列出已经存在的远程仓库
$ git remote

# 列出远程仓库的详细信息，在别名后面列出URL地址
$ git remote -v
$ git remote --verbose

# 添加远程仓库
$ git remote add <远程仓库的别名> <远程仓库的URL地址>

# 修改远程仓库的别名
$ git remote rename <原远程仓库的别名> <新的别名>

# 删除指定名称的远程仓库
$ git remote remove <远程仓库的别名>

# 修改远程仓库的 URL 地址
$ git remote set-url <远程仓库的别名> <新的远程仓库URL地址>
```

### git reset

还原提交记录，版本回退

```bash
# 重置暂存区，但文件不受影响
# 相当于将用 "git add" 命令更新到暂存区的内容撤出暂存区，可以指定文件
# 没有指定 commit ID 则默认为当前 HEAD
$ git reset [<文件路径>]
$ git reset --mixed [<文件路径>]

# 将 HEAD 的指向改变，撤销到指定的提交记录，文件未修改
$ git reset <commit ID>
$ git reset --mixed <commit ID>

# 将 HEAD 的指向改变，撤销到指定的提交记录，文件未修改
# 相当于调用 "git reset --mixed" 命令后又做了一次 "git add"
$ git reset --soft <commit ID>

# 将 HEAD 的指向改变，撤销到指定的提交记录，文件也修改了
$ git reset --hard <commit ID>
```

### git revert

生成一个新的提交来撤销某次提交，此次提交之前的所有提交都会被保留。

```bash
# 生成一个新的提交来撤销某次提交
$ git revert <commit ID>
```

### git rm

删除文件或者文件夹。

```bash
# 移除跟踪指定的文件，并从本地仓库的文件夹中删除
$ git rm <文件路径>

# 移除跟踪指定的文件夹，并从本地仓库的文件夹中删除
$ git rm -r <文件夹路径>

# 移除跟踪指定的文件，在本地仓库的文件夹中保留该文件
$ git rm --cached
```

### git status

用于显示工作目录和暂存区的状态。使用此命令能看到那些修改被暂存到了, 哪些没有, 哪些文件没有被 Git tracked 到。

```bash
# 查看本地仓库的状态
$ git status
```

> `git status` 不显示已经 `commit` 到项目历史中去的信息。
> 看项目历史的信息要使用 `git log`。

### git tag

操作标签的命令。

```bash
# 打印所有的标签
$ git tag

# 添加轻量标签，指向提交对象的引用，可以指定之前的提交记录
$ git tag <标签名称> [<commit ID>]

# 添加带有描述信息的附注标签，可以指定之前的提交记录
$ git tag -a <标签名称> -m <标签描述信息> [<commit ID>]

# 切换到指定的标签
$ git checkout <标签名称>

# 查看标签的信息
$ git show <标签名称>

# 删除指定的标签
$ git tag -d <标签名称>

# 将指定的标签提交到远程仓库
$ git push <远程仓库的别名> <标签名称>

# 将本地所有的标签全部提交到远程仓库
$ git push <远程仓库的别名> –tags
```



## 分支合并冲突

由于多人同时进行开发，有时候会同时修改一个文件，或者多分支开发，合并的时候就很容易引发冲突，下面是一个制造冲突和解决冲突的例子。

**制造冲突：**

1. 同学 A 新建码云仓库,同时添加同学 B 为开发者(其实一个人也可以制造冲突的)

2. 同学 A 新建文件 `main.js` 并提交推送到远程仓库,同学 B 把仓库同步到本地,这时两位同学都有一个 `main.js` 的空文件

3. 同学 A 在 `main.js` 的第一行添加"我是同学 A",然后添加,提交并推送到远程仓库

4. 同学 B 在 `main.js` 的第一行添加"我是同学 B",

   1. 然后执行以下命令

      ```bash
      git add .
      git commit -m"修改main.js"
      git push origin master
      ```

   2. 出现以下提示

   3. ![](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251817188.png)

      意思是被拒绝了,要先执行 `git pull` 命令

      ![img](https://raw.githubusercontent.com/cold-bin/img-for-cold-bin-blog/master/img/202208251818272.png)

      因为两位同学同时修改了同一行代码,所有 git 不知如何取舍(如果同学 a 修改了第一行,同学 b 修改了第二行,那么 git 会智能的合并),只好把合并代码这个事情交给开发者去处理,上图中`<<<<<<< HEAD` 到`========`的代码是 B 同学的代码,`======`到`>>>>>>> a248f68a5fcbcbe4cc887bee3dfc3cfd1cf7147b` 的代码是同学a的代码,括号的 Incoming Change 的意思是从外面来的修改,`a248f68a5fcbcbe4cc887bee3dfc3cfd1cf7147b` 是仓库是冲突的版本号,你可以通过 `git log` 看到详细的信息

      你可以根据具体情况去合并代码,取 a 的代码或者取 b 的代码,或者 a 取一点,b 取一点,具体情况具体分析. 手动删除这些特殊符号，并选择某个修改内容进行提交，就可以解决冲突。

## 分支管理策略

**核心：因为创建、合并和删除分支非常快，所以Git鼓励你使用分支完成某个任务，合并后再删掉分支，这和直接在master分支上工作效果是一样的，但过程更安全。**

### bug分支

软件开发中，bug就像家常便饭一样。有了bug就需要修复，在Git中，由于分支是如此的强大，所以，每个bug都可以通过一个新的临时分支来修复，修复后合并分支，然后将临时分支删除。

当你接到一个修复一个代号101的bug的任务时，很自然地，你想创建一个分支issue-101来修复它，但是，当前正在dev上进行的工作还没有提交。

并不是你不想提交，而是工作只进行到一半，还没法提交，预计完成还需1天时间。但是，必须在两个小时内修复该bug，怎么办？于是，你就现在要停下并暂存手头的工作，转而去修复bug。

幸好，Git还提供了一个`stash`功能，可以把当前工作现场“储藏”起来，等修改BUG以后恢复现场继续工作：

- 将当前工作现场“储藏”起来，等以后恢复现场继续工作
  `git stash`
  现在用`git status`查看工作区，工作区就是干净的（除非没有被Git管理的文件）
- 查看“储藏”的工作现场
  `git stash list`
- 恢复最近一次“储藏”的工作现场
  `git stash apply`
  恢复指定工作现场，通过`git stash list`查看工作现场的序号，将（stash@{序号}）追加到命令后面
  注意，序号越靠后，说明储藏的时间越长
  这样恢复后，stash内容并不会删除，需要手动删除
- 删除“储藏”的工作现场
  `git stash drop`
- 恢复并删除“储藏”的工作现场
  `git stash pop`
- master分支出现bug，说明dev同样也存在，Git专门提供了命令，让我们复制一个特定的提交到当前分支
  `git cherry-pick 特定的提交id`

### Feature分支

软件开发中，总有无穷无尽的新的功能要不断添加进来。

添加一个新功能时，你肯定不希望因为一些实验性质的代码，把主分支搞乱了，所以，每添加一个新功能，最好新建一个feature分支，在上面开发，完成后，合并，最后，删除该feature分支。

如果在feature分支还没有合并前，需要取消这个功能，删除时会销毁失败，需要使用大写的`-D`参数强制删除，`git branch -D 分支`

### 多人协作

当你从远程仓库克隆时，实际上Git自动把本地的master分支和远程的master分支对应起来了，并且，远程仓库的默认别名是origin。

- 查看远程库的信息
  `git remote -v` ，`-v`表示详细信息

- 推送分支
  `git push 远程库别名 本地分支名称`

- 抓取分支
  `git clone 远程仓库的URL`，默认只能看到本地的master分支
  如果要在dev分支上开发，就必须创建远程origin的dev分支到本地
  `git checkout -b dev origin/dev`，创建并且切换到dev分支，并将远程库origin/dev弄下来
  如果最新提交和你推送的提交有冲突，先用`git pull`把最新提交抓下来，然后在本地合并，解决冲突，再提交。

  ```bash
  # git pull 失败
  $ git pull
  There is no tracking information for the current branch.
  Please specify which branch you want to merge with.
  See git-pull(1) for details.
      git pull <remote> <branch>
  If you wish to set tracking information for this branch you can do so with:
      git branch --set-upstream-to=origin/<branch> dev
  # 原因是没有指定本地dev分支与远程origin/dev分支的链接，根据提示，设置dev和origin/dev的链接
  ```

- 设置本地分支dev与远程分支origin/dev的链接
  `git branch --set-upstream-to=origin/dev dev`

- 多人协作工作模式
  **尽量将冲突在本地解决**

  1. pull远程库内容到本地先进行合并
  2. 如合并冲突，则解决冲突
  3. 如没有冲突或解决后，再commit 并push到远程库


---

> Author: [阿冰](https://github.com/cold-bin)  
> URL: https://blog.coldbin.top/git%E5%B7%A5%E4%BD%9C%E6%B5%81/  

