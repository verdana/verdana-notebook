---
title: "C++ dynamic cast"
tags: ["C++"]
categories: ["C++"]
date: 2018-03-20
---


## RTTI

RTTI 全称运行时类型信息（Run-time Type Identification）。

RTTI 提供了一个标准的方法用来检测运行时对象的类型。

换句话说，RTTI（运行时类型识别）允许“用指向基类的指针或引用来操纵对象”的程序能够获取到“这些指针或引用所指对象”的实际派生类型。

RTTI 通过两种操作符来实现：

1. typeid        返回指针或引用所指向的对象的实际派生类型
2. dynamic_cast  将基类指针或引用安全地转换为派生类的指针或引用
<!--more-->

## dynamic_cast

尝试将一个对象转换成类型更具体的对象。

下面的代码如果不明白，没有关系，后面会详细说明。

```cpp
#include <iostream>
using namespace std;

class A
{
public:
    virtual void f(){cout << "A::f()" << endl;}
};

class B : public A
{
public:
    void f(){cout << "B::f()" << endl;}
};

int main()
{
    A a;
    B b;
    a.f();        // A::f()
    b.f();        // B::f()

    A *pA = &a;
    B *pB = &b;
    pA->f();      // A::f()
    pB->f();      // B::f()

    pA = &b;
    // pB = &a;      // not allowed
    pB = dynamic_cast<B*>(&a;); // allowed but it returns NULL

    return 0;
}
```

dynamic_cast 在 RTTI 组件中使用最为频繁。它无法告诉我们指针对象的确切类型，但是却可以让我们判断是否可以将一个对象的地址安全的赋值给一个特殊类型的指针。

与其它类型转换不同的是，dynamic_cast 涉及运行时类型检查。 如果绑定到指针的对象不是目标类型的对象，则它会失败并且值为0.如果它在失败时是引用类型，则会抛出 bad_cast 异常。 所以，如果我们想让 dynamic_cast 抛出一个异常而不是返回 0，那么将其转换为引用而不是指针。 还要注意，dynamic_cast 是唯一依赖运行时检查的强制转换。

Scott Meyers 在其着作“Effective C ++”中提到过：

> The need for dynamic_cast generally arises because you want to perform derived class operation on a derived class object, but you have only a pointer or reference-to-base

> 对 dynamic_cast 的需求通常是因为你想对派生类对象执行派生类操作，但你只有一个指向基类的指针或者引用。

请看下面的示例代码：

```cpp
class Base {};

class Derived : public Base {};

int main() {
  Base b;
  Derived d;

  Base *pb = dynamic_cast<Base *>(&d;);        // #1
  Derived *pd = dynamic_cast<Derived *>(&b;);  // #2

  return 0;
}
```

#1 运行 OK，因为将一个类强制转换成其父类肯定是没有问题的。

#2 则会编译错误：

```error
 error C2683: 'dynamic_cast' : 'Base' is not a polymorphic type.
```

这是因为 dynamic_cast 不允许父类 -> 派生类的转换，除非父类是多态的。

因此，如果我们给父类 Base 添加一个虚函数使其多态化，那么就能编译通过了。

```cpp
class Base {virtual void vf(){}};

class Derived : public Base { };

int main()
{
    Base b;
    Derived d;

    Base *pb = dynamic_cast<Base*>(&d;);        // #1
    Derived *pd = dynamic_cast<Derived*>(&b;);  // #2

    return 0;
}
```

但是在运行时，#2 会转换失败并且产生空指针，来看另一个例子：

```cpp
class Base { virtual void vf(){} };

class Derived : public Base { };

int main()
{
    Base *pBDerived = new Derived;
    Base *pBBase = new Base;
    Derived *pd;

    pd = dynamic_cast<Derived*>(pBDerived);     // #1
    pd = dynamic_cast<Derived*>(pBBase);        // #2

    return 0;
}
```

该示例具有两个从 Base 类型的指针到 Derived 类型的指针的动态强制类型转换。 但只有 ＃1 会成功。

尽管 pBDerive d和 pBBase 是 Base * 类型的指针，但 pBDerived 指向 Derived 类型的对象，而 pBBase 指向 Base 类型的对象。

因此，当使用 dynamic_cast 执行相应的类型转换时，pBDerived 指向类 Derived 的完整对象，而 pBBase 指向 Base类的对象，该类是 Derived 类的不完整对象。


```cpp
dynamic_cast<Type *>(ptr)
```

通常，如果指针对象 ptr 的类型为 Type 或者直接或间接从 Type 类型派生，则上述表达式将指针 ptr 转换为 Type* 类型的指针。 否则，表达式的计算结果为 0，成为空指针。


## dynamic_cast - 例子

下面的额代码中，有个 main() 函数不工作，是哪个呢？

```cpp
#include <iostream>

using namespace std;

class A
{
public:
    virtual void g(){}
};
class B : public A
{
public:
    virtual void g(){}
};
class C : public B
{
public:
    virtual void g(){}
};
class D : public C
{
public:
    virtual void g(){}
};

A* f1()
{
    A *pa = new C;
    B *pb = dynamic_cast<B*>(pa);
    return pb;
}

A* f2()
{
    A *pb = new B;
    C *pc = dynamic_cast<C*>(pb);
    return pc;
}

A* f3()
{
    A *pa = new D;
    B *pb = dynamic_cast<B*>(pa);
    return pb;
}

int main()
{
    f1()->g();   // (1)
    f2()->g();   // (2)
    f3()->g();   // (3)

    return 0;
}
```
答案是 (2)，这是个向下转型（downcast）。


## dynamic_cast - 其他例子

在这个例子中，DoSomething(Window* w) 传入 Windows 指针，它调用了只能从 Scroll 对象中获得的 scroll() 方法。因此，在这种情况下，我们需要在调用 scroll() 方法之前检查对象是否为 Scroll 类型。

```cpp
#include <iostream>
#include <string>
using namespace std;

class Window
{
public:
    Window(){};
    Window(const string s):name(s) {};
    virtual ~Window() {};
    void getName() {
        cout << name << endl;
    };
private:
    string name;
};

class ScrollWindow : public Window
{
public:
    ScrollWindow(string s) : Window(s) {};
    ~ScrollWindow() {};
    void scroll() { cout << "scroll()" << endl;};
};

void DoSomething(Window *w)
{
    w->getName();
    // w->scroll();  // class "Window" has no member scroll

    // check if the pointer is pointing to a scroll window
    ScrollWindow *sw = dynamic_cast<ScrollWindow*>(w);

    // if not null, it's a scroll window object
    if(sw) sw->scroll();
}

int main()
{
    Window *w = new Window("plain window");
    ScrollWindow *sw = new ScrollWindow("scroll window");

    DoSomething(w);
    DoSomething(sw);

    return 0;
}
```

## 向上转型和向下转型

将派生类引用或指针转换为基类引用或指针称为向上转型。 它始终允许公共继承，而不需要明确的类型转换。

其实这条规则是表达 is-a 关系的一部分。 派生对象是一个 Base 对象，它继承了 Base 对象的所有数据成员和成员函数。

因此，任何我们可以对 Base 对象做的事情，也可以对它的派生类对象做同样的操作。

向下转换，与向上转换相反，是一个将基类指针或引用转换为派生类指针或引用的过程。

没有明确类型的转换是不允许的。这是因为派生类可能会添加新的数据成员，并且使用这些数据成员的类成员函数将不适用于基类。

以下是例子：

```cpp
#include <iostream>

using namespace std;

class Employee {
private:
    int id;
public:
    void show_id(){}
};

class Programmer : public Employee {
public:
    void coding(){}
};

int main()
{
    Employee employee;
    Programmer programmer;

    // upcast - implicit upcast allowed
    Employee *pEmp = &programmer;

    // downcast - explicit type cast required
    Programmer *pProg = (Programmer *)&employee;


    // Upcasting: safe - progrommer is an Employee
    // and has his id to do show_id().
    pEmp->show_id();
    pProg->show_id();

    // Downcasting: unsafe - Employee does not have
    // the method, coding().
    // compile error: 'coding' : is not a member of 'Employee'
    // pEmp->coding();
    pProg->coding();

    return 0;
}
```

## typeid

typeid 能让我们检测两个对象是否相同。

在前面的转型的示例中，Employee 调用了不应该得到的方法 coding()。因此，在我们使用方法 coding() 之前，我们需要检查指针是否指向 Programmer 对象。

以下是显示如何使用typeid的新代码：

```cpp
class Employee {
private:
    int id;
public:
    void show_id(){}
};

class Programmer : public Employee {
public:
    void coding(){}
};

#include <typeinfo>

int main()
{
    Employee lee;
    Programmer park;

    Employee *pEmpA = &lee;
    Employee *pEmpB = &park;

    // check if two object is the same
    if(typeid(Programmer) == typeid(lee)) {
        Programmer *pProg = (Programmer *)&lee;
        pProg->coding();
    }
    if(typeid(Programmer) == typeid(park)) {
        Programmer *pProg = (Programmer *)&park;
        pProg->coding();
    }

    pEmpA->show_id();
    pEmpB->show_id();

    return 0;
}
```

所以，只有 Programmer 使用了 coding() 方法。

要注意的是，我们在示例中包含了<typeinfo>。 typeid 运算符返回对 type_info 对象的引用，其中 type_info 是 typeinfo 头文件中定义的类。


### 原文来源

<a id="ref01">[C++ TUTORIAL - DYNAMIC CAST - 2018](http://www.bogotobogo.com/cplusplus/dynamic_cast.php)</a>
