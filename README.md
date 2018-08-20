# tp5_smart
基于tp5，实现智能化、敏捷化开发，仅支持5.0.*
#### 修改php版本要求
```
"require": {
    "php": ">=7.0.0",
}
```
#### 添加执行脚本
```
"scripts":{
    "post-install-cmd": [
        "php vendor/skj198568/tp5_smart/create_files.php"
    ],
    "post-update-cmd": [
        "php vendor/skj198568/tp5_smart/create_files.php"
    ]
}
```
#### 执行命令
```
composer require "skj198568/tp5_smart:1.0.*"
```
#### 帮助手册
[https://www.kancloud.cn/songkejing/tp5-smart/506234](https://www.kancloud.cn/songkejing/tp5-smart/506234)
