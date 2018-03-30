---
title: "如何使用 Golang 的 Interface"
tags: ["Golang"]
date: 2018-03-29
---


我偶尔会在我的日常工作上免费进行咨询和代码审查。因此，我倾向于阅读很多其他人的代码。虽然这很可能是错觉，但我真的看到了很多我称之为 Java 风格的接口用法。

这篇博文是 Go 的具体建议，基于我写Go代码的经验，以及如何很好地使用接口。

For this blog post, the running example will span two packages: animal and circus. A lot of what I write about here is about code at the boundary of packages.

## 别这么干

我看到很多人的接口是这样用的：

```go
package animals

type Animal interface {
	Speaks() string
}

// implementation of Animal
type Dog struct{}
func (a Dog) Speaks() string { return "woof" }
```

```go
package circus

import "animals"

func Perform(a animal.Animal) string { return a.Speaks() }
```

这就是所谓的 Java 风格的接口用法。通常步骤是这样的：

1. 定义一个接口
2. 定义一个匹配这个接口的类型（如：Dog 结构体）
3. 定义满足接口实现的方法

我将这个概括为“编写类型以实现接口”。这种代码味道的人为因素很明显：

* 其中最明显的是它只有一种类型可以实现接口，而没有明显的扩展手段。
* 函数通常采用具体的类型而不是接口类型。


## 正确的做法

Go 接口鼓励人们懒惰，这是一件好事，而不是编写类型来完成接口，编写接口来满足使用需求。

我的意思是这个 - 不是在 animals package 中定义 Animal，而是在 package circus 的使用点上定义它。

```go
package animals

type Dog struct{}
func (a Dog) Speaks() string { return "woof" }
```

```go
package circus

type Speaker interface {
	Speaks() string
}

func Perform(a Speaker) string { return a.Speaks() }
```

更舒适的方式是：

1. 定义类型
2. 在使用点定义接口

这种方式明显降低了对 package animals 的依赖。

## 伯斯塔尔法则

[伯斯塔尔法则](https://en.wikipedia.org/wiki/Robustness_principle) 是创作优秀软件需要遵循的准则之一。

通常的说法是这样的：

> Be conservative with what you do, be liberal with you accept

如果翻译到 Go 语言的语境中：

> Accept interfaces, return structs

Go 中的主要代码单元是函数，设计函数/方法时应当遵循的以下的模式：

```go
func funcName(a INTERFACETYPE) CONCRETETYPE
```

这里我们看到我们接受任何实现接口的东西 - 可以是任何接口或空白接口，并返回一个具体值。

当然，限制参数 a 的具体类型是很有必要的，最好不要在函数中传入空白接口 interface{}，没有意义。

> the empty interface says nothing - Rob Pike


## 使用案例：Mocking

伯斯塔尔法则的有用性的一个很好的例证就是在测试的环境中下，比如你有一个类似下面的函数：

```go
func Takes(db Database) error
```

如果 Database 是一个接口，然后在测试代码中，您可以提供一个 Database 的模拟实现，而不必传入实际的数据库对象。


## 什么时候可以接受预先定义接口

老实说，编程的形式是非常自由的 - 没有任何的硬性规定。你当然可以预先定义一个接口。在多个 package 的情况下，如果你知道你的函数正在使用包中的某个接口，那么通过一切手段来做到这一点。

预定义接口通常有点过度工程的意味。但是在很多状况下你很明显是需要预先接口的，我可以想到的是：

* 封闭接口
* 抽象数据类型
* 递归接口

在这里我将简要介绍一下。

## 封闭接口

Sealed interfaces can only be discussed in the context of having multiple packages. A sealed interface is an interface with unexported methods. This means users outside the package is unable to create types that fulfil the interface. This is useful for emulating a sum type as an exhaustive search for the types that fulfil the interface can be done.

封闭接口只能在具有 package 的环境中讨论。封闭接口指的是没有导出任何方法的接口。这意味着 package 外部的用户无法创建满足界面的类型。这对于模拟总和类型非常有用，因为它可以完成可以完成接口的类型的详尽搜索。

所以你要定义这样的东西：

```go
type Fooer interface {
	Foo()
	sealed()
}
```

Only the package that defined Fooer can use and create any valid value of Fooer. This allows for exhaustive type switches to be done.

A sealed interface also allows for analysis tools to easily pick up any non-exhaustive pattern match. In fact BurntSushi’s [sumtypes](https://github.com/BurntSushi/go-sumtype) package does just that for you.


## 抽象数据类型

The other use of defining an interface upfront is to create a abstract data type. It may or may not be sealed.

The sort package that comes in the standard library is a good example of this. It defines a sortable collection as

```go
type Interface interface {
    // Len is the number of elements in the collection.
    Len() int
    // Less reports whether the element with
    // index i should sort before the element with index j.
    Less(i, j int) bool
    // Swap swaps the elements with indexes i and j.
    Swap(i, j int)
}
```

Now this has made a lot of people upset - because if you want to use the sort package you’d have to implement the methods for the interface, and people for the most part are upset about having to type three extra lines.

However in my opinion this is a very elegant form of generics in Go. It should be encouraged more.

The alternative design that is elegant would require higher-kinded types. We shan’t go there in this blog post.


## 递归接口

This is probably another code smell, but there are times which are unavoidable, you perform something within a monad and end up with an interface that looks like this:

```go
type Fooer interface {
	Foo() Fooer
}
```

The recursive interface pattern would require the interface be defined upfront, clearly. The guideline of defining an interface at the point of use is inapplicable here.

This pattern is useful for creating contexts to operate in. Context-heavy code are usually self-contained within a package, with only the contexts exported (alá the tensor package), so I don’t actually see a lot of this. I’ve quite a bit more to say about contextual patterns, but I’ll leave that to another blog post.


## 结论

Even though I have a section titled “Don’t Do This”, the purpose of this post is not meant to be proscriptive. Rather, I want to encourage people to think at the boundary conditions - that’s where all the edge cases happen.

I personally found the declare-at-point-of-use pattern extremely useful. As a result I don’t particularly run into issues that I’ve observed a number of people have run into.

I however also run into cases where I end up accidentally writing Java style interfaces - typically after I come back from a stint of writing code in Python or Java. The desire to overengineer and “class all the things” something is quite strong especially when writing Go code after writing a lot of object oriented code.

Hence this post also serves as a self-reminder on what the path to pain-free code looks like. Tell me what you think!

Thanks to [Stratos Neiros](https://twitter.com/nstratos) for reviewing an earlier version of this article. And to Riteek Srivastava for picking out some bugs in the example code.

