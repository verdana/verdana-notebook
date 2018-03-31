---
title: "PHP 7.1 的新特性"
tags: ["PHP"]
date: 2018-03-31
---


PHP 开发组在 2016.10.01 发布了 PHP 7.1.0，这是 7.x 系列的首个版本。7.1 带来了一些新的特性 —— 比如 void return type。

下面选择性了介绍一些 PHP 7.1 中的特性 :)

<!--more-->

## void functions

函数返回值声明为 void 之后，函数体必须忽略 return 或者使用一个空的 return。

之前版本中常使用的 null 返回值对于 void 函数来说是无效的。

示例如下：

```php
<?php
function should_return_nothing() : void {
    // Do something
    return; // valid
}

// OR

function should_return_nothing() : void {
    // Do something
    // valid
}
```

return null 是不允许的。

```php
<?php
function should_return_nothing() : void {
    // Do something
    return null; // Fatal error: A void function must not return a value
}
```

会抛出如下的错误信息：

```text
Fatal error:  A void function must not return a value
```

需要注意的是 void 只能用于声明函数返回类型，不能当作参数类型：

```php
<?php
function foobar(void $foo) {
    // Fatal error: void cannot be used as a parameter type
}
```


## Nullable types

参数和返回值的类型声明可以通过在类型名称前添加一个问号来标记为空。 也就是说，除了指定的类型外，null 也可以作为参数传递，或者作为值返回。 可空类型可以用在任何需要类型声明的地方，但要遵守一些继承规则。

```php
<?php
function answer(): ?int  {
    return null;    //ok
}

function answer(): ?int  {
    return 42;      // ok
}

function answer(): ?int {
    return new stdclass();
    // Fatal error: Uncaught TypeError: Return value of
    // answer() must be of the type integer or null
}
```

``` php
<?php
function say(?string $msg) {
    if ($msg) {
        echo $msg;
    }
}

say('hello');       // ok -- prints hello
say(null);          // ok -- does not print
say();              // error -- missing parameter
say(new stdclass);  // error -- bad type
```

注意：具有可空类型的参数不能使用默认值。如果省略参数值，那么该参数值不会默认为 null，并会导致错误：

```php
<?php
function f(?callable $p) {}
f(); // invalid; function f does not have a default
```

PHP的现有语义允许为参数提供一个空的默认值，以使其可为空或可选：

```php
<?php
function foo_default(Bar $bar = null) {}

foo_default(new Bar);   // valid
foo_default(null);      // valid
foo_default();          // valid
```


## Symmetric array destructuring

作为 PHP 5.4 中引入的速记数组语法[]，现在可以用来对指定（包括在foreach中）的数组进行解构，这可以用来替代现有的 list() 语法，不过 list 还是可以继续使用。

使用 PHP 5.4 中引入的速记数组语法，我们可以像下面那样定义一个数组。

```php
<?php
// Creates an array containing elements with the values 1, 2 and 3,
// and keys numbered from zero
$array = [1, 2, 3];

// Creates an array containing elements with the values 1, 2 and 3,
// and the keys "a", "b", "c"
$array = ["a" => 1, "b" => 2, "c" => 3];
```

与用于构造数组的 array() 语法类似，自 PHP3 以来，PHP 具有用于从数组元素分配变量的语法形式，称为解构 (destructuring)。

```php
<?php
// Assigns to $a, $b and $c the values of their respective array
// elements in $array with keys numbered from zero
list($a, $b, $c) = $array;
```

有了 PHP 7.1 的新功能，我们可以像下面那样解构一个数组。

```php
<?php
// Assigns to $a, $b and $c the values of their respective
// array elements in $array with keys numbered from zero
[$a, $b, $c] = $array;

// Assigns to $a, $b and $c the values of the array elements
// in $array with the keys "a", "b" and "c", respectively
["a" => $a, "b" => $b, "c" => $c] = $array;
```

这个语法更加简洁，和替代 array() 的 [] 一样，这个新的语法不像是函数调用。

重要的是，这个解构数组的语法意味着，数组构造和解构的语法形式上更加的对称，这应该使得语法的功能更具可读性：

```php
<?php
// The two lines in each of the following pairs are equivalent to each other
list($a, $b, $c) = array(1, 2, 3);
[$a, $b, $c] = [1, 2, 3];

list("a" => $a, "b" => $b, "c" => $c) = array("a" => 1, "b" => 2, "c" => 3);
["a" => $a, "b" => $b, "c" => $c] = ["a" => 1, "b" => 2, "c" => 3];

list($a, $b) = array($b, $a);
[$a, $b] = [$b, $a];
```


## Class Constant Visibility

之前版本中，PHP 中的类允许在属性和方法上使用修饰符，但不允许用在类常量上。

而现在，PHP7.1 允许类常量定义为 public，private 或 protected，并且未声明的常量没有明确的可见性关键字的默认为 public。

```php
<?php
class ConstDemo
{
    const PUBLIC_CONST_A = 1;
    public const PUBLIC_CONST_B = 2;
    protected const PROTECTED_CONST = 3;
    private const PRIVATE_CONST = 4;
}
```


## Support for negative string offsets

对接受偏移的字符串操作函数以及用 [] 或 {} 进行字符串索引时，现在支持使用负字符串偏移量。在这种情况下，负偏移量被解释为距字符串末尾的偏移量。

在大多数 PHP 函数中，提供一个负值作为字符串偏移意味着 —— 从字符串的末尾的第 n 个位置开始向后计数。 这种机制被广泛使用，但不幸的是，这些负值并不是到处都支持的。

大多数开发人员很难知道给定的字符串函数是否接受负值，只能去查阅文档。字符串函数的这种不一致风格，让 PHP 饱受批评。

一个例子是 strrpos() 接受负偏移量，而 strpos() 却不接受。同样情况的还有 substr() / substr_count() 前者可以使用负值偏移量，而后者却不可以。

```php
<?php
var_dump("abcdef"[-2]);
var_dump(strpos("aabbcc", "b", -3));

// output:
string (1) "e"
int(3)
```
