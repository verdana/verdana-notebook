---
title: "如何使用 Golang 的 Interface"
tags: ["Golang"]
date: 2018-03-29
---


I occasionally give free Go consults and code review on top of my daily work. As such, I tend to read a lot of other peoples’ codes. And while this is really more of a feeling *, I’ve seen an increase in what I call “Java-style” interface usage.

This blog post is a Go specific recommendation from me, based on my experiences writing Go code, on how to use interfaces well.

For this blog post, the running example will span two packages: animal and circus. A lot of what I write about here is about code at the boundary of packages.

## 不要这么做

A very common thing I see people do is this:

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


This is the so-called “Java-style” interface usage. The steps are as such:

1. Define an interface
2. Define one type that fulfils the interface
3. Define the methods that satisfies implementation of the interface.

I would summarize this as “writing types to fulfil interfaces”. The artefacts of such a code smell is clear:

* The most obvious of which is that it has only one type that fulfils the interface with no obvious means of extension.
* Functions typically take concrete types instead of interface types.


## 正确的做法

Go interfaces encourages one to be lazy, and this is a good thing. Instead of writing types to fulfil interfaces, write interfaces to fulfil usage requirements.

What I mean is this - instead of defining Animal in package animals, define it at point of use - in package circus.

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


The more idiomatic way would be this:

1. Define the types
2. Define the interface at point of use.

This way shows a reduced dependency on the components of package animals. Reduced dependencies is how you build robust software.


## 伯斯塔尔法则

[伯斯塔尔法则](https://en.wikipedia.org/wiki/Robustness_principle) 是创作优秀软件需要遵循的准则之一。

通常的说法是这样的：

> “Be conservative with what you do, be liberal with you accept”

如果翻译到 Go 语言的语境中：

> “Accept interfaces, return structs”

By and large, this is a very good maxim on designing things to be robust*. The main unit of code in Go is a function. The pattern to follow when designing functions/methods is the following:

```go
func funcName(a INTERFACETYPE) CONCRETETYPE
```

Here we see we accept anything that implements an interface - could be any interface, or a blank one, and return a value that is a concrete value. Of course, there is value in constraining what a can be. As it goes in the Go proverbs,

> “the empty interface says nothing“ - Rob Pike

So it’s preferable not to have functions take interface{}.


## 使用案例：Mocking

An excellent demonstration of the usefulness of the Postel’s Law maxim is in the case of testing. If you have a function that looks like this:

```go
func Takes(db Database) error
```

If Database is an interface then in testing code, you can just provide a mock implementation of Database without having to pass in a real database object.


## When Is It Acceptable To Define An Interface Upfront

Truth be told, programming is pretty free form - there’s no real hard and fast rules. You can of course define an interface upfront. No correctness police is going to show up and arrest you. In the context of multiple packages, if you know your functions are going take a certain interface within the package then by all means do that.

Defining an interface upfront is usually a code smell for overengineering. But there are clearly situations where you need define an interface upfront. I can think of several:

* 封闭接口
* 抽象数据类型
* 递归接口

Here I shall briefly visit each.

## 封闭接口

Sealed interfaces can only be discussed in the context of having multiple packages. A sealed interface is an interface with unexported methods. This means users outside the package is unable to create types that fulfil the interface. This is useful for emulating a sum type as an exhaustive search for the types that fulfil the interface can be done.

So what you’d define something like this:

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

