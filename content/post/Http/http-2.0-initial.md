---
title: "HTTP/2 初探"
tags: ["http", "web", "php", "nginx"]
categories: ["Http"]
date: 2018-04-02
draft: false
---


## HTTP/2 介绍

[HTTP/2](https://tools.ietf.org/html/rfc7540) 是新一代的超文本传输协议，相比 1999 年发布的 HTTP/1.1 变化可谓巨大。当年，我们见到的网页还比较简单，通常只有少数几个静态页面配合一些图片和样式表资源。现在整个互联网都已经动态化，近20年没有更新的 HTTP/1.1 很多方面已经难以跟上时代的发展。

<!--more-->

### HTTP/1 的主要问题：

* 队头阻塞

单个连接利用率低，每次只能获取一个资源。h1 的管道化特性虽然允许一次性发起一组请求，但是只能按照请求的顺序依次获得响应，糟糕的是现代 Web 服务器和浏览器对这个特性支持并不好，导致这个特性几乎没有实用价值。现代浏览器虽然可以同时对同一个域名发起多个请求连接，但是单个连接依然会受到队头阻塞的影响。一旦某个请求出现问题，后续请求都会被阻塞，从而影响网页的加载速度。

* TCP 利用率低

TCP 的拥塞控制算法会自动调整拥塞窗口大小，保证了在不同的网络状况下数据传输的稳定性，但现代网站的单个页面包括资源都会比较大，要传输完整个页面可能会需要数据包的数次往复，浪费宝贵的传输时间。

* 消息头臃肿

HTTP 消息头是每个连接中最先传输的信息，也是最关键的信息，但是消息头不像主体内容一样有压缩机制，如果消息头可被压缩显然能够缓解网络的压力。


HTTP / 2解决了这些问题，因为它带来了一些基本的变化：

- 所有请求都是并行的，而不是在一个队列中
- HTTP 头被压缩
- 页面作为二进制文件传输，而不是作为文本文件传输，效率更高
- 即使没有用户的请求，**服务器也可以“推送”数据**，这可以提高高延迟用户的速度

### 现实中的 HTTP/2.0

HTTP/2.0 发布已经2年多了，现在很多站点都已经开始使用这项技术，比如 Google，Facebook，Wikipedia，Weibo 等等...

这是使用 Chrome Developer Tools 查看的[新浪微博](https://weibo.com)加载情况，Protocol 一栏显示的是 h2：

![新浪微博](/media/posts/http-2.0-initial/weibo-h2.png)

那么作为 Web 开发人员，如果条件允许也应该开始接触并运用这项技术来为自己的开发的网站提速。


## 快速上手

本文并非为了介绍 HTTP/2.0 本身，一篇短短的文章也实在无法讲述完，如果对协议本身有兴趣，可以参考 [RFC 7540](https://tools.ietf.org/html/rfc7540)，或者干脆买本书吧——[《HTTP/2 基础教程》](http://www.ituring.com.cn/book/2020) 。

作为开发人员，我更关注的是如何在实际的项目中使用 HTTP/2.0，以下会以一个实际的 PHP/Larvel 项目为例：


### Nginx 配置

以 Nginx 为例，一步步修改配置，激活 HTTP/2.0。

首先将网站的监听端口由 **80** 改为 **443**，打开 ```/etc/nginx/conf.d/default.conf```：

```nginx
listen 443 ssl http2;
server_name localhost;
```

然后我们需要配置 Nginx 使用 SSL 证书，为了测试方便我们搞个自签名的证书即可。

```shell
# 创建 Nginx SSL 目录
mkdir /etc/nginx/ssl

# 进入目录
cd /etc/nginx/ssl
```

运行以下 OpenSSL 命令来生成自签名 SSL 证书，包括私有密钥和公用证书，该命令会询问一系列的问题，实际上我们只需要填写公共名称 **Common Name = CN** 就可以了，其它选项默认。

```
openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out certificate.pem
```

再次打开 ```/etc/nginx/conf.d/default.conf``` 在 server 块中加入命令：

``` nginx
ssl_certificate /etc/nginx/ssl/certificate.pem;
ssl_certificate_key /etc/nginx/ssl/key.pem;
```

打开 ```/etc/nginx/nginx.conf```，加入下面的命令，指定 Nginx 在 SSLv3 和 TLS 协议下优先使用服务器的加密套件：

```nginx
ssl_prefer_server_ciphers on;
ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
```

下面我们需要增加密钥交换安全性，默认情况下，Nginx 使用1028位 DHE（[Ephemeral Diffie-Hellman](https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange)）密钥，该密钥相对容易解密。如果要提高安全性，可以用下面的命令创建自己的 DHE 密钥：

```shell
cd /etc/nginx/ssl

# 密钥长度越长，这个命令运行时间也就越长
openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
```

再次打开 ```/etc/nginx/conf.d/default.conf``` 文件，加入下面一行：

```nginx
ssl_dhparam  /etc/nginx/ssl/dhparam.pem;
```

检查配置是否有语法错误：

```shell
nginx -t
```

### 服务器推送

未完待续

