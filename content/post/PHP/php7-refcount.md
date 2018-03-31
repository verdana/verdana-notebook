---
title: "关于 PHP7 中的 refcount"
tags: ["php", "refcount", "gc"]
categories: ["PHP"]
date: 2018-03-31
---


最近在复习 PHP 的垃圾收集机制，发现一些 refcount 的小细节，这里稍作记录。

> PHP 的 GC 是用来清理运行时资源的。它使用了基于引用的机制来处理复杂的变量类型，同时也使用了 mark-and-sweep 的技术来检测循环引用所引起的内存泄漏。

当然这篇小文并不是为了介绍 PHP 的 GC 机制，而是简单的说一下 refcount，原因是我在测试一些介绍 GC 的文章中的例子时，发现一些例子运行结果不正确。

<!--more-->

比如下面的代码，这是 PHP 手册中的一段代码：

```php
<?php
$a = "new string";
$c = $b = $a;
xdebug_debug_zval( 'a' );
$b = 42;
xdebug_debug_zval( 'a' );
unset( $c );
xdebug_debug_zval( 'a' );
```

手册给出的运行结果是这样的：

```text
// result from php5.6
a: (refcount=3, is_ref=0)='new string'
a: (refcount=2, is_ref=0)='new string'
a: (refcount=1, is_ref=0)='new string'
```

如果你使用 PHP5 运行上面的代码，结果确实是如此，但是当我使用 PHP 7.x 运行时，结果发生了变化：

```text
// result from php7.0-7.2
a: (refcount=0, is_ref=0)='new string'
a: (refcount=0, is_ref=0)='new string'
a: (refcount=0, is_ref=0)='new string'
```

哈，实际上这是 PHP7 的 GC 机制更加完善的表现。

在 PHP7 中变量会根据类型的不同，而使用或者不使用引用计数。

1. 简单的数据类型，null, bool, int, float 不会使用。
2. 一些复杂的类型，object, resource 和 reference 总是会使用。
3. 还有一些类型，比如 string 和 array 则不确定。

### 内部字符串
以字符串来说明，如果你使用的是非线程安全 (NTS) 的 PHP7 版本，那么所有的字符串实际上都是内部字符串 "interned string"，这些字符串是唯一且不重复的，并且在整个 request 生命周期中，这些字符串都是始终存在的，所以无需使用引用计数。

如果你用到了 opcache，那么内部字符串实际上全部存储在共享内存中，因为没有同步机制，而 PHP 的引用计数技术又是非原子性的，所以这种情况下也是无法使用引用计数的。

内部字串有个临时的 refcount = 1，但是即使用 xdebug 也看不到。


### 不可变数组

Immutable array 是 PHP7 opcache 中引入的一项优化机制。用在那些在编译期间就能完全确定元素值的数组上。所以 immutable array 只能包含，字符串，浮点数，整形和数组这样的元素。这项优化机制保证了在循环中，数组只会被创建一次，这样可以大幅度的减少内存占用。

其特点包括：

* 不使用引用计数
* 不会被垃圾收集
* 不可被复制

举个栗子：
```php
<?php
for ($i = 0; $i < 10000; $i ++) {
    $data[] = [1, 2.3, 'php', ['array']];
}
```

PHP5 中，相同的数组会被复制 10000 次，可见这样是非常浪费内存的。在实际的场景中，我们也是可能会遇到在循环中处理大数组的情况的。

PHP7 呢，opcache 会标记数组为 immutable：数组仅会被创建一次，内存指针被其它可能用到的地方共享，这样就起到了节约内存的作用。

尽管上面提到了 immutable array 不使用引用计数，但是实际上内部结构中 refcount 还是有个固定的值 2，这样保证了 immutable array 在需要改变时，产生一个硬拷贝并改变这个新的数组，以保证原数组的完整性。

这项优化技术是 opcache 的一部分，所以必须激活 opcache 扩展才可以使用。

