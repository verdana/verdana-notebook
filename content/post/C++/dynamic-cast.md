---
title: "C++ TUTORIAL - DYNAMIC CAST"
tags: ["C++"]
date: 2018-03-20
---


## RTTI

RTTI 全称运行时类型信息（Run-time Type Identification）。

RTTI 提供了一个标准的方法用来检测运行时对象的类型。

In other words, RTTI allows programs that use pointers or references to base classes to retrieve the actual derived types of the objects to which these pointers or references refer.

RTTI 通过两种运算符来实现：

1. typeid        返回指针或引用所绑定的对象的实际类型
2. dynamic_cast  将基类指针或引用安全地转换为派生类的指针或引用
<!--more-->

## The dynamic_cast Operator

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

The dynamic_cast operator is intended to be the most heavily used RTTI component. It doesn't give us what type of object a pointer points to. Instead, it answers the question of whether we can safely assign the address of an object to a pointer of a particular type.

Unlike other casts, a dynamic_cast involves a run-time type check. If the object bound to the pointer is not an object of the target type, it fails and the value is 0. If it's a reference type when it fails, then an exception of type bad_cast is thrown. So, if we want dynamic_cast to throw an exception (bad_cast) instead of returning 0, cast to a reference instead of to a pointer. Note also that the dynamic_cast is the only cast that relies on run-time checking.

"The need for dynamic_cast generally arises because you want to perform derived class operation on a derived class object, but you have only a pointer or reference-to-base" said Scott Meyers in his book "Effective C++".

Let's look at the example code:

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

The example has two dynamic casts from pointers of type Base to a point of type Derived. But only the #1 is successful.

Even though pBDerived and pBBase are pointers of type Base*, pBDerived points to an object of type Derived, while pBBase points to an object of type Base. Thus, when their respective type-castings are performed using dynamic_cast, pBDerived is pointing to a full object of class Derived, whereas pBBase is pointing to an object of class Base, which is an incomplete object of class Derived.

In general, the expression

```cpp
dynamic_cast<Type *>(ptr)
```

converts the pointer ptr to a pointer of type Type* if the pointer-to object (*ptr) is of type Type or else derived directly or indirectly from type Type. Otherwise, the expression evaluates to 0, the null pointer.


## Dynamic_cast - example

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


## Dynamic_cast - another example

In this example, the DoSomething(Window* w) is passed down Window pointer. It calls scroll() method which is only available from Scroll object. So, in this case, we need to check if the object is the Scroll type or not before the call to the scroll() method.

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

## Upcasting and Downcasting

Converting a derived-class reference or pointer to a base-class reference or pointer is called upcasting. It is always allowed for public inheritance without the need for an explicit type cast.

Actually this rule is part of expressing the is-a relationship. A Derived object is a Base object in that it inherits all the data members and member functions of a Base object. Thus, anything that we can do to a Base object, we can do to a Derived class object.

The downcasting, the opposite of upcasting, is a process converting a base-class pointer or reference to a derived-class pointer or reference.

It is not allowed without an explicit type cast. That's because a derived class could add new data members, and the class member functions that used these data members wouldn't apply to the base class.

Here is a self explanatory example

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

## The typeid

typeid 能让我们检测两个对象是否相同。

In the previous example for Upcasting and Downcasting, employee gets the method coding() which is not desirable.
So, we need to check if a pointer is pointing to the Programmer object before we use the method, coding().

Here is a new code showing how to use typeid:

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

So, only a programmer uses the coding() method.

Note that we included <typeinfo> in the example. The typeid operator returns a reference to a type_info object, where type_info is a class defined in the typeinfo header file.


### 原文来源

<a id="ref01">[C++ TUTORIAL - DYNAMIC CAST - 2018](http://www.bogotobogo.com/cplusplus/dynamic_cast.php)</a>
