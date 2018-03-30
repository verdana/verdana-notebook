---
title: "PostgreSQL 常用命令"
tags: ["PostgreSQL"]
date: 2018-03-15
---


最近开始学习 PostgreSQL，准备慢慢告别 MySQL 了，这里整理收集了一些常用的控制台命令，方便查阅。

<!--more-->

* 连接数据库

```text
psql -U username -d dbname
psql dbname rolename
sudo -u username psql dbname
```

* 数据库列表

```text
mysql: show databases
pgsql: \l 或 \list
```

* 切换数据库

```text
mysql: use dbname
pgsql: \c dbname
```

* 列出当前数据库下的数据表

```text
mysql: show tables
pgsql: \d
```

* 列出指定表的所有字段

```text
mysql: show full columns from tablename
pgsql: \d tablename
```

* 查看指定表的结构信息

```text
mysql: describe tablename
pgsql: \d+ tablename
```

* 列出数据表/索引/序列/试图/系统表

```text
\d{t|i|s|v|S} [PATTERN] (add "+" for more detail)
```

* 退出登录

```text
mysql: quit 或 \q
pgsql: \q
```
