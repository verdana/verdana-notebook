---
title: "Modern PHP Without a Framework"
tags: ["PHP"]
categories: ["PHP"]
date: 2018-04-10
---


## 无框架编程

读了来自 [Kevin Smith](https://twitter.com/_KevinSmith) 的文章 [Modern PHP Without a Framework](https://kevinsmith.io/modern-php-without-a-framework)，感觉很棒，这也是一直以来我个人追求的目标 —— 无框架 PHP 编程。

记得以前，想要脱离框架编写 Web 应用是比较麻烦的，很多东西需要自己来写，比如 `HTTP` 消息处理，路由，会话管理，权限校验，数据库操作等等。有了框架以后，我们就可以不关心这些，而把精力集中在业务逻辑上。

<!--more-->

不同的框架针对的应用场景也是不同的，有大而全的 [Laravel](https://laravel.com), [Symfony](https://symfony.com), [Zend Framework](https://framework.zend.com) 等等，基本上囊括了 Web 开发所需要的一切功能；如果只是想开发一个简单的应用，比如 Restful API 服务，也有类似 [Slim](https://www.slimframework.com)，[Lumen](https://lumen.laravel.com) 之类的精简框架；还有针对性能优化的使用 C 扩展作为核心的，比如 [Phalcon](https://phalconphp.com), [Yaf](https://github.com/laruence/yaf) ；还有最近诞生的异步通信框架 [Swoole](http://swoole.com) 等等。

还有很多流行的或者曾经流行过的框架没有列出来，在开发工作中，可以任意选择我们喜欢的框架来使用。我个人不是太喜欢框架，因为不管是哪种框架总有那么一些地方，功能不符合我的预期或者实现方式不那么优雅，让我觉得很别扭。如果说有个框架让我很满意，大概只有 Laravel 了。

换一个思路，如果我们只是想开发一个不那么复杂的应用，或许可以尝试抛弃框架。Kevin 的文章中作了尝试，但有很多地方没有讲清楚，有些地方还有错误，本文将把这个过程重新梳理一遍，重写样例代码，以作补充。


## 如何实现

- 感谢 [PHP-FIG](https://www.php-fig.org)，有了很多基于 PSR 标准实现的简洁的组件，可以供我们选择。
- 感谢 [Composer](https://getcomposer.org)，包管理器可以把需要的组件打包到一起以定制我们自己的框架。


## 从 FrontController 开始

首先，什么是 [Front Controller Design Pattern](https://en.wikipedia.org/wiki/Front_controller) 呢？

    The front controller design pattern means that all requests that come for a resource in an application will be handled by a single handler and then dispatched to the appropriate handler for that type of request.

简单的说，FrontController 是程序的入口，由上面的定义可以看出，FrontController 主要的功能是集中处理所有的客户端发来的请求，根据请求地址的不同，调用不用的控制器来处理，并将数据返回给客户端。

下面是一个极简版本的入口文件：

```php
<?php
$uri = isset($_SERVER['PATH_INFO']) ? $_SERVER['PATH_INFO'] : '/';
switch ($uri)
{
    case '/':
        $controller = "IndexController";
        break;
    case '/home':
        $controller = "HomeController";
        break;
    default:
        header("HTTP/1.1 404 Not Found");
        exit;
}

// 检查对应的 Controller 文件是否存在
$filename = $controller . '.php';
if (!file_exists($filename)) {
    exit('Controller file does not exists');
}

// 载入控制器文件，然后初始化并运行
require_once $filename;
new $controller();
```

在实际的项目中，入口文件会变得复杂的多，比如上面的 `$uri` 检测，PHP 运行环境和配置千差万别，很多时候可能 `$_SERVER` 中不会有 `PATH_INFO` 或者值可能是错误的，这个时候我们就要同时检测 `$_SERVER['REQUEST_URI']` 和 `$_SERVER['PHP_SELF']` 等变量，以此算出正确的请求 URL。再者，还会有很多其它的功能参杂在一起，灰常的麻烦！

如果每一个项目中都要写一次上面的这样代码，肯定是很乏味的，所以才有了框架帮我们完成这些琐碎的工作，但是如果不依赖框架该怎么做更好呢？

下面就我们开始我们的无框架之旅，首先需要一些准备工作，搭建运行环境：

* 安装 PHP 7.1，由于使用了一些新语法，所以版本不要低于 7.1
* 安装包管理器 Composer
* 创建我们的项目目录，比如 D:\Github\php-wof-skeleton
* 在项目目录中创建 public 和 src 目录，并创建文件 public/index.php
* 打开控制台，进入项目目录，运行命令 `php -S localhost:80 -t public/` 启动 PHP 的内置服务器

好了，现在我们有了一个基本的 PHP 运行环境了。 :)


### 自动加载技术以及第三方组件

原文中有介绍，这里我们直接运行命令 `composer init` 创建配置文件 `composer.json`。

然后我们随便添加一个依赖包，比如 `monolog`：

```
composer require monolog/monolog
```

这个命令会自动下载 `monolog`，你会看到项目下面多了一个 `vendor/` 目录和 `composer.lock`。

完成后打开 composer.json 加上 `autoload` 配置，大概是下面这个样子：
```json
{
    "name": "verdana/php-wof-skeleton",
    "description": "A simple boilerplate for php project",
    "type": "project",
    "license": "MIT",
    "authors": [
        {
            "name": "Verdana",
            "email": "verdana.cn@gmail.com"
        }
    ],
    "minimum-stability": "stable",
    "require": {
        "monolog/monolog": "^1.23"
    },
    "autoload": {
        "psr-4": {
            "PhpWof\\": "src/"
        }
    }
}
```

`autoload` 配置段的含义是，扫描 `src/` 目录下的所有类文件，使用 `Composer Autoload` 机制自动加载这些文件，PhpWof 是类的名字空间。

一些常用的命令：

* `composer install` 下载所有的依赖包，包的版本受到 `composer.lock` 的限制，如果这个文件不存在，那么会根据 `minimum-stability` 的定义下载最新的版本，之后重新生成 `composer.lock` 锁定版本。
* `composer dump-autoload` 刷新 autoload 文件，重新生成 `class-map`。

打开文件 `public/index.php`，引入 autoload 文件。

```php
<?php
require_once dirname(__DIR__) . '/vendor/autoload.php';
// 初始化 Monolog
$log = new Monolog\Logger('name');
// 查看加载的文件
var_dump(get_included_files());

```

现在还没有任何功能，但是已经可以看到 autoload 加载了一些文件进来了，其中包括 Monolog 的一些文件。

OK，现在搞定了自动加载和如何引入第三方的组件，下面介绍依赖注入。


### 什么是依赖注入？

    In software engineering, dependency injection is a technique whereby one object (or static method) supplies the dependencies of another object. A dependency is an object that can be used (a service). An injection is the passing of a dependency to a dependent object (a client) that would use it.

依赖注入是一种重要的解耦手段，通过控制反转来解决依赖性的设计模式。简单的说依赖注入也就是将类所依赖的对象在类的外部完成初始化，然后通过类的构造函数、属性或者方法传递给类。

来看一个不太好的例子：

```php
<?php
class IndexController
{
    private $pdo;

    public function __construct()
    {
        $this->pdo = new \PDO('pgsql:host=localhost;dbname=postgres', 'user', 'pass');
    }
}
```

很糟，控制器类完全的依赖 `PDO` 连接，如果数据库连接失败，后续的代码会完全停止运行。程序会运行一半后崩掉，很可能会显示给用户一个半残的页面，而且每一个控制器中可能都会有相同的代码，当然可以通过继承的方式解决，比如在父类中完成数据库连接，但是依然无法解决上面的问题，而且这些控制器因为依赖特定的数据库连接，其他人（比如 QA 人员）完全无法运行单元测试，除非他们也有一个和你一模一样的数据库以及用户密码。所以从职能上讲，这么做是很糟糕的。

上面的代码可能很傻，有经验的开发人员，大概不会写出这样的代码，但是我的确看到过很多比这更恐怖的...

让我们稍微的改进一下：

```php
<?php
class IndexController
{
    private $pdo;

    public function __construct(\PDO $pdo)
    {
        $this->pdo = $pdo;
    }
}
```

所有问题都解决了，数据库的连接被移到类的外部，只需要在初始化控制器的时候，将 `$pdo` 作为参数传入就可以了。其他人也可以通过模拟数据库连接进行单元测试，这样就与你的运行环境无关了。

实际项目中，控制器依赖的可能不只是数据库连接，可能还包括模板，服务以及一些工具类等等，这里我们就需要一个 `DI Container` 了，把这些被依赖的对象统统放入容器，在需要的时候自动初始化然后注入到控制器中。


### 依赖注入容器

目前最流行的是 [PHP-DI](http://php-di.org)，打开控制台安装：

```
composer require php-di/php-di
```

打开 `public/index.php`，更新下代码，首先需要配置容器：

```php
<?php
use function DI\create;
use DI\ContainerBuilder;

require_once dirname(__DIR__) . '/vendor/autoload.php';

$builder = new ContainerBuilder();
$builder->useAutowiring(false);
$builder->useAnnotations(false);
$builder->addDefinitions([
    PDO::class => create()->constructor(
        'pgsql:host=localhost;dbname=postgres',
        'user',
        'password',
        []),
]);

$container = $builder->build();
var_dump($container->get(PDO::class));
```

关于 `autowire`，原文中有提到，这里再提一下，这个特性很好用，但是如果你的项目有多人维护或者你开发的项目是一个开源项目，那么最好**明确的定义**你需要注入的对象。因为 `PHP-DI` 使用 [Type Hinting](http://php.net/manual/en/functions.arguments.php#functions.arguments.type-declaration) 来实现自动注入，所以你需要声明注入方法（比如构造函数或者 set() 方法）的参数类型，通常有可能是一个 `interface` ，举个例子：` Psr\Http\Message\ResponseInterface`，然后问题就来了，如果其他人或者新引入的库中也实现了这个接口，那么 `PHP-DI` 就会无法判断到底该将哪个实现类与这个接口绑定，程序就会出现很多莫名其妙且很难调试的问题。所以说，应该慎用 `autowire`，明确定义更好一些。

当项目变得复杂以后，可能定义的对象会越来越多，还可以将其全部以数组的形式放在额外的文件中，以避免 `index.php` 变得臃肿。

```php
<?php
// ...
$builder->addDefinitions('config.php');
// ...

// config.php
return [
    // ....
];
```

上面的例子中，容器会帮你自动初始化数据库连接，并注入到需要的类中，但是直接使用 `PDO` 不太好，使用一个连接管理类把它包装一下，处理连接异常等更好一些。

一个简单的数据库连接类，创建文件 `src/Database/Connection.php`，代码如下：

```php
<?php
declare (strict_types = 1);

namespace PhpWof\Database;

use PDO;
use PDOException;

class Connection
{
    private $params;
    private $options;
    private $pdo;

    public function __construct(string $dsn, string $user, string $password, array $options = null)
    {
        $this->params = [$dsn, $user, $password];
        $this->options = (array) $options;

        if (empty($options['lazy'])) {
            $this->connect();
        }
    }

    public function connect(): void
    {
        if ($this->pdo) {
            return;
        }

        try {
            $this->pdo = new PDO($this->params[0], $this->params[1], $this->params[2], $this->options);
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            throw $e;
        }
    }

    public function disconnect(): void
    {
        $this->pdo = null;
    }

    public function getPDO(): PDO
    {
        return $this->pdo;
    }
}
```

然后修改 `public/index.php` 中的定义。

```php
<?php
// ...
$builder->addDefinitions([
    PhpWof\Database\Connection::class => create()->constructor(
        'pgsql:host=localhost;dbname=postgres',
        'user',
        'password',
        []),
]);
//...
```

注入部分介绍到这里，目前的代码离真正的可用还有一段距离。我们还需要一个 `Router` 组件，有了路由才能将请求转发到控制器。在此之前，还要再介绍一个概念：Middleware，也就是中间件，这也是本文中除了 DI 以外最重要的部分。


### 中间件

在 Web 应用中，中间件通常是指在 `Request` 和 `Response` 的循环中按照顺序执行的实现各种功能的代码，整个中间件的执行过程是一个洋葱模型，如下图（网上扒来的）。

![洋葱模型](/media/posts/modern-php-wof/onion.png)

上图中有很多中间件，实际的工作中可能也会用到这么多，而要管理这些中间件按顺序正确的执行，就需要一个调度程序，也就是 `Dispatcher`（也叫做请求处理器，`Request Hander`）。调度程序以及所有的中间件都需要符合 [PSR-15](https://www.php-fig.org/psr/psr-15) 标准，以求互相兼容。

安装 [Relay](http://relayphp.com/2.x) 作为我们的调度器：
```
composer require relay/relay:2.x@dev
```

如果你看过 [PSR-15](https://www.php-fig.org/psr/psr-15)，里面有提到：

    A request handler is an individual component that processes a request and produces a response, as defined by PSR-7.

所以呢，我们还需要一个兼容 [PSR-7](https://www.php-fig.org/psr/psr-7) 的 `HTTP` 消息处理组件，使用原文中推荐的 [Zend Diactoros](https://zendframework.github.io/zend-diactoros/)。

```
composer require zendframework/zend-diactoros
```

最后，我们还需要一个路由和请求处理程序，安装号称最快的路由 —— [fast-route](https://github.com/middlewares/fast-route) 以及 [request-handler](https://github.com/middlewares/request-handler)：

```
composer require middlewares/fast-route middlewares/request-handler
```

fast-route 负责检查客户端请求是否符合路由定义的规则，并检测 URL 对应的控制器是否有效，然后 request-handler 负责启动控制器，并将 `Request` 对象传入控制器中。

然后，我们看一下如何让这些组件能够协同工作，打开 `public/index.php`，运作一番：

```php
<?php
require_once dirname(__DIR__) . '/vendor/autoload.php';

// 依赖注入
$builder = new DI\ContainerBuilder();
$builder->useAutowiring(false);
$builder->useAnnotations(false);
$builder->addDefinitions([
    PhpWof\Database\Connection::class => DI\create()->constructor(
        'pgsql:host=localhost;dbname=postgres',
        'Verdana',
        'postgres'),
]);
$container = $builder->build();

// 使用 fast-route 分配所有的请求
$dispatcher = FastRoute\simpleDispatcher(function (FastRoute\RouteCollector $r) {
    // $r->addRoute('GET', '/', 'PhpWof\Controllers\IndexController');
});

// Relay 以及中间件
$relay = new Relay\Relay([
	new Middlewares\FastRoute($dispatcher),
	new Middlewares\RequestHandler()
]);

$response = $relay->handle(Zend\Diactoros\ServerRequestFactory::fromGlobals());

// 输出
return (new Zend\Diactoros\Response\SapiEmitter())->emit($response);
```

> 为了代码行数更短一些，去掉了所有名字空间导入语句 use xxx;

`ServerRequestFactory::fromGlobals()` 是一切的入口，这个函数从 `$_GET, $_POST, $_REQUEST, $_SESSION, $_COOKIE` 等这些全局数组中导入所有 `Request` 所必需的数据，

`FastRoute` 和 `RequestHandler` 这两者的关系就好像是规则的制定者和执行者，你可以选择其它兼容 `PSR-15` 的类似组件，但是他们必须是存在的。

如果你在代码中使用了 `header()`, `http_response_code()` 之类的函数，那就需要保证这些函数之前没有任何输出，否则如果没有在 `php.ini` 中打开输出缓冲，程序就会报错。使用 `SapiEmitter` 就能保证 `Response` 的状态码、消息头和内容主体能以正确的顺序输出到浏览器，其中更多的细节，可以参考这篇文章 [Emitting Responses with Diactoros](https://framework.zend.com/blog/2017-09-14-diactoros-emitters.html)。


## 业务逻辑

到这里整体的框架差不多都搭建完了，还有最重要的一点没有讲，业务逻辑该怎么写？

再一次，我们还要继续的完善 `public/index.php` 文件：

```php
<?php
require_once dirname(__DIR__) . '/vendor/autoload.php';

// 依赖注入
$builder = new DI\ContainerBuilder();
$builder->useAutowiring(false);
$builder->useAnnotations(false);
$builder->addDefinitions([
    PhpWof\Database\Connection::class => DI\create()->constructor(
        'pgsql:host=localhost;dbname=postgres',
        'Verdana',
        'postgres'),

    Psr\Http\Message\ResponseInterface::class => function () {
        return new Zend\Diactoros\Response();
    },
]);
$container = $builder->build();

// 使用 fast-route 分配所有的请求
$dispatcher = FastRoute\simpleDispatcher(function (FastRoute\RouteCollector $r) {
    $r->addRoute('GET', '/', 'PhpWof\Controllers\IndexController');
});

// request handlers 容器
// 这里的参数会被用来创建路由器配置的类实例，也就是各种控制器
$requestHandlerContainer = new Middlewares\Utils\RequestHandlerContainer([
    $container->get(PhpWof\Database\Connection::class),
    $container->get(Psr\Http\Message\ResponseInterface::class)
]);

// Relay 以及中间件
$relay = new Relay\Relay([
	new Middlewares\FastRoute($dispatcher),
	new Middlewares\RequestHandler($requestHandlerContainer)
]);

$response = $relay->handle(Zend\Diactoros\ServerRequestFactory::fromGlobals());

// 输出
return (new Zend\Diactoros\Response\SapiEmitter())->emit($response);
```

在 `PHP-DI` 的定义中，多创建了一个 `Response` 对象作为接口 `ResponseInterface` 的实现类。

`RequestHandler` 则负责将 `RequestHandlerContainer` 容器中的 `Connection` 和 `Response` 对象作为参数传递给控制器的构造函数。

现在可以写一个控制器了，创建文件 `src/Controllers/IndexController.php`：

```php
<?php
declare(strict_types=1);

namespace PhpWof\Controllers;

use PhpWof\Database\Connection;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

class IndexController
{
    private $connection;
    private $response;

    public function __construct(Connection $conn, ResponseInterface $response)
    {
        $this->connection = $conn;
        $this->response = $response;
    }

    public function __invoke(ServerRequestInterface $request): ResponseInterface
    {
        // $_GET
        var_dump($request->getQueryParams());
        // $_POST
        var_dump($request->getParsedBody());
        // 路由参数
        var_dump($request->getAttributes());

        // 操作数据库
        $pdo = $this->connection->getPDO();
        $sth = $pdo->query('SELECT version()');
        ['version' => $version] = $sth->fetch(\PDO::FETCH_ASSOC);
        var_dump($version);

        return $this->response;
    }
}
```

除了需要注意构造函数中的参数外，就是魔术方法 `__invoke` 必须声明返回值为 `ResponseInterface`，然后返回 `Response` 对象。

完整的代码，可以在 [Github](https://github.com/verdana/php-wof-skeleton) 下载。

最后，如果想要加入模板引擎，比如 `Twig` `Plates`，该怎么做呢... 可以自己试试呢！

### 该去哪里找组件？

* 首先可以看看这里：https://github.com/middlewares/psr15-middlewares
* 或者 Composer 的仓库 https://packagist.org
* 善用 Google 搜索，试试关键字： `site:github.com PSR-15 middleware`
* 去 `Symfony` `Zend` 的官方网站去碰碰运气
* ...

好了，完了...
