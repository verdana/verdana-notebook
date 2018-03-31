---
title: "HTTP 状态码"
tags: ["http", "web"]
categories: ["Http"]
date: 2018-03-10
---


当我们从客户端向服务器发起 HTTP 请求时，服务器会向我们返回响应信息，其中头信息中包含的 HTTP 状态码会告诉我们服务器的状态。

下面的表格中列出了一些在 Web Development 中常见的 HTTP 状态码。

<!--more-->

| 状态码 | 响应类别 | 原因短语 |
| :----- | :------- | :------- |
| 1XX    | 信息性状态码（Informational）    | 服务器正在处理请求                |
| 2XX    | 成功状态码（Success）            | 请求已正常处理完毕                |
| 3XX    | 重定向状态码（Redirection）      | 需要进行额外操作以完成请求        |
| 4XX    | 客户端错误状态码（Client Error） | 客户端原因导致服务器无法处理请求  |
| 5XX    | 服务器错误状态码（Server Error） | 服务器原因导致处理请求出错        |

[RFC2616](https://tools.ietf.org/html/rfc2616)（用来指定HTTP协议标准的文档）标准定义的就有四十多种，加上扩展能达到六十种，
不过常见的大概只有十几种，下面列出一些有代表性的状态码。


| 状态码   | 原因短语 |
| :------- | :------- |
| 200 OK                    |   请求正常处理完毕                        |
| 204 No Content            |   请求成功处理，没有实体的主体返回        |
| 206 Partial Content       |   GET范围请求已成功处理                   |
| 301 Moved Permanently     |   永久重定向，资源已永久分配新URI         |
| 302 Found                 |   临时重定向，资源已临时分配新URI         |
| 303 See Other             |   临时重定向，期望使用GET定向获取         |
| 304 Not Modified          |   请求的资源一直未变动                    |
| 307 Temporary Redirect    |   临时重定向，POST不会变成GET             |
| 400 Bad Request           |   请求报文语法错误或参数错误              |
| 401 Unauthorized          |   需要通过HTTP认证，或认证失败            |
| 403 Forbidden             |   请求资源被拒绝                          |
| 404 Not Found             |   无法找到请求资源（服务器无理由拒绝）    |
| 405 Method Not Allowed    |   请求资源不支持请求的方法                |
| 500 Internal Server Error |   服务器故障或Web应用故障                             |
| 502 Bad Gateway           |   服务器作为网关或代理从上游服务器接收到无效响应      |
| 503 Service Unavailable   |   服务器超负载或停机维护                              |
| 504 Gateway Timeout       |   服务器作为网关或代理从上游服务器接收响应时超时      |

