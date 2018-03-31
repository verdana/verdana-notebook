---
title: "如何使用 Golang 的 Interface"
tags: ["Golang"]
categories: ["Golang"]
date: 2018-03-29
---


我偶尔会在我的日常工作上免费进行咨询和代码审查。因此，我倾向于阅读很多其他人的代码。虽然这很可能是错觉，但我真的看到了很多我称之为 Java 风格的接口用法。

这篇博文是 Go 的具体建议，基于我写Go代码的经验，以及如何很好地使用接口。


## 不要这样做

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

所以你要定义这样的东西：

```go
type Fooer interface {
	Foo()
	sealed()
}
```

只有定义了 Fooer 的包才能使用并创建任何有效的 Fooer 值，这允许实现彻底的类型切换。

一个密封的接口也允许分析工具轻松地获取任何非穷举的模式匹配，请看 BurntSushi’s [sumtypes](https://github.com/BurntSushi/go-sumtype)。


## 抽象数据类型

定义接口的另一个用途是创建一个抽象数据类型，无所谓是否被密封（sealed）。

标准库中的排序包就是一个很好的例子，它定义了一个可排序的集合：

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

现在这已经让很多人感到不爽了 - 因为如果你想使用排序包，你必须自己实现接口的方法。

但在我看来，这是Go中非常优雅的范式，应该鼓励这么做。

另一种方式是使用更高阶的类型来实现优雅的设计，这里就不做讨论了。


## 递归接口

这可能是另一种形式的代码，但是有时候不太容易避免，你在 monad 中执行某些操作，最终得到的接口如下所示：

```go
type Fooer interface {
	Foo() Fooer
}
```

递归接口模式需要清晰地预先定义接口，在此使用点定义接口的准则不太适用。

这种模式对于创建上下文来操作是非常有用的。上下文密集的代码通常是自包含在一个包中，只有上下文导出，实际上我见的不多。

## 结论

尽管我有一个标题为“不要这样做”的部分，但这篇文章的目的并不意味着具有前瞻性。相反，我想鼓励人们在边界条件下思考 - 就是所有边缘案例发生的场景。

我个人发现使用点声明模式非常有用，因此，我很少遇到我前面讨论过的这些问题。

但是，我也遇到过最终需要编写Java风格接口的情况 - 通常是在我用Python或Java编写代码的时候。 在编写大量面向对象的代码后再编写Go代码时，过度编程和“对所有事物进行分类”的愿望非常强烈。

因此这篇文章也可以作为一个自我提醒，告诉我们如何写出无痛的代码。

感谢 [Stratos Neiros](https://twitter.com/nstratos) 审核这篇文章，同时也感谢 Riteek Srivastava 指出示例代码中的错误。


### 原文来源

<a id="ref01">[How To Use Go Interfaces](https://blog.chewxy.com/2018/03/18/golang-interfaces/)</a>
