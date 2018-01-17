# tp5_smart
基于tp5，实现智能化、简化开发。
### composer使用
修改配置
```
"minimum-stability":"dev"
```
添加执行脚本
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
composer require "skj198568/tp5_smart"
```
#### 帮助手册
```
    http://
```
