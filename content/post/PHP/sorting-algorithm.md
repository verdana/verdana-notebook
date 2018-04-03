---
title: "使用 PHP 实现的常见排序算法"
tags: ["php", "sort"]
categories: ["PHP"]
date: 2018-04-01
draft: true
---


```php
<?php
// 冒泡排序
function bubble_sort(&$arr)
{
    for ($i = 0; $i < count($arr); $i++) {
        for ($j = $len - 1; $j > $i; $j--) {
            if ($arr[$j - 1] > $arr[$j]) {
                $tmp = $arr[$j - 1];
                $arr[$j - 1] = $arr[$j];
                $arr[$j] = $tmp;
            }
        }
    }
}
```
