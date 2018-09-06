# tp5_smart
基于tp5，实现智能化、敏捷化开发。
#### 修改composer.json php版本要求
```
"require": {
    "php": ">=7.0.0",
}
```
#### 添加composer.json 配置文件及执行脚本
```
"repositories": [
    {
        "type": "git",
        "url": "https://github.com/skj198568/class_library.git"
    },
    {
        "type": "git",
        "url": "https://github.com/skj198568/tp5_smart.git"
    }
],
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
1. tp5.0
```
composer require "skj198568/tp5_smart:1.0.*"
```
2. tp5.1
```
composer require "skj198568/tp5_smart:1.1.*"
```
#### 帮助手册
[https://www.kancloud.cn/songkejing/tp5-smart/506234](https://www.kancloud.cn/songkejing/tp5-smart/506234)
