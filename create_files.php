<?php
/**
 * update或install之后执行复制文件
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/12/06
 * Time: 15:56
 */
include_once __DIR__ . "/../class_library/ClassLibrary/ClFile.php";
include_once __DIR__ . "/../class_library/ClassLibrary/ClSystem.php";
include_once __DIR__ . "/../class_library/ClassLibrary/ClString.php";

$files = \ClassLibrary\ClFile::dirGetFiles(__DIR__ . DIRECTORY_SEPARATOR . 'scripts');
//往上3个目录
$document_root_dir = explode(DIRECTORY_SEPARATOR, __DIR__);
$document_root_dir = array_slice($document_root_dir, 0, count($document_root_dir) - 3);
$document_root_dir = implode(DIRECTORY_SEPARATOR, $document_root_dir);
//var_dump($document_root_dir);
//循环覆盖文件
foreach ($files as $file) {
    $target_file = $document_root_dir . str_replace(__DIR__ . DIRECTORY_SEPARATOR . 'scripts', '', $file);
    //替换文件名
    $target_file = str_replace('.php.tpl', '.php', $target_file);
    //如果目标文件不存在，则新建
    \ClassLibrary\ClFile::dirCreate($target_file);
    //不可直接覆盖的文件特殊处理
    if ((strpos($target_file, 'BaseApiController') === false && strpos($target_file, 'ApiController') !== false) || strpos($target_file, 'task_run.ini') !== false) {
        if (!is_file($target_file)) {
            //如果文件不存在，则覆盖文件，存在则忽略
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'tags.php') !== false) {
        if (!is_file($target_file)) {
            //直接复制
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        } else {
            //更改内容
            $file_content = file_get_contents($target_file);
            $str          = \ClassLibrary\ClString::getBetween($file_content, 'view_filter', ']');
            //再次获取
            $str_params = \ClassLibrary\ClString::getBetween($str, '[', ']');
            if ($str_params == '[]') {
                //直接添加
                $str_target = str_replace($str_params, "['app\\common\\behavior\\MergeResource', 'app\\common\\behavior\\BrowserSyncJsMerge']", $str);
                //替换
                $file_content = str_replace($str, $str_target, $file_content);
                //回写
                file_put_contents($target_file, $file_content);
                echo 'modify file: ' . $target_file . PHP_EOL;
            } else {
                if (strpos($str_params, 'MergeResource') === false && strpos($str_params, 'BrowserSyncJsMerge') === false) {
                    //拼接添加
                    $str_target = str_replace($str_params, trim($str_params, ']') . ", 'app\\common\\behavior\\MergeResource', 'app\\common\\behavior\\BrowserSyncJsMerge']", $str);
                    //替换
                    $file_content = str_replace($str, $str_target, $file_content);
                    //回写
                    file_put_contents($target_file, $file_content);
                    echo 'modify file: ' . $target_file . PHP_EOL;
                }
            }
        }
    } else if (strpos($target_file, 'command.php') !== false) {
        $file_content = file_get_contents($target_file);
        //处理换行
        if (strpos($file_content, '[]') !== false) {
            $file_content = str_replace('];', "\n];", $file_content);
        }
        $comands = \ClassLibrary\ClString::getBetween(file_get_contents($file), 'return', ']', true);
        $comands = \ClassLibrary\ClString::getBetween($comands, '[', ']', false);
        $comands = explode(',', $comands);
        foreach ($comands as $each_command) {
            $each_command = trim($each_command);
            if (empty($each_command)) {
                continue;
            }
            //判断是否存在
            if (strpos($file_content, $each_command) === false) {
                $file_content = str_replace('];', "    $each_command,\n];", $file_content);
            }
        }
        //回写文件
        file_put_contents($target_file, $file_content);
        echo 'modify file: ' . $target_file . PHP_EOL;
    } else if (strpos($target_file, '.env') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'FileController') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'ErrorController') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'IndexBaseController') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'IndexController') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'Apps.php') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'TaskController.php') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else if (strpos($target_file, 'users.ini') !== false) {
        if (!is_file($target_file)) {
            //覆盖文件
            echo 'copy file: ' . $target_file . PHP_EOL;
            copy($file, $target_file);
        }
    } else {
        //覆盖文件
        echo 'copy file: ' . $target_file . PHP_EOL;
        copy($file, $target_file);
    }
}
//系统config文件修复
$file = $document_root_dir . '/config/app.php';
if (is_file($file)) {
    $file_content = file_get_contents($file);
    //控制器
    $search       = \ClassLibrary\ClString::getBetween($file_content, 'controller_suffix', ',');
    $file_content = str_replace($search, "controller_suffix' => true,", $file_content);
    //回写
    file_put_contents($file, $file_content);
}

//模板
$file = $document_root_dir . '/config/template.php';
if (is_file($file)) {
    $file_content = file_get_contents($file);
    $search       = \ClassLibrary\ClString::getBetween($file_content, 'taglib_begin', ',');
    $file_content = str_replace($search, "taglib_begin' => '<',", $file_content);
    $search       = \ClassLibrary\ClString::getBetween($file_content, 'taglib_end', ',');
    $file_content = str_replace($search, "taglib_end' => '>',", $file_content);
    //回写
    file_put_contents($file, $file_content);
}

//日志级别修改
$file = $document_root_dir . '/config/log.php';
if (is_file($file)) {
    $file_content = file_get_contents($file);
    $search       = \ClassLibrary\ClString::getBetween($file_content, 'level', ']');
    $replace      = \ClassLibrary\ClString::getBetween($search, '[', ']', false);
    $replace      = trim($replace, ',');
    foreach (['\think\Log::ERROR', '\think\Log::NOTICE', '\think\Log::SQL', '\think\Log::DEBUG'] as $each_level) {
        if (strpos($replace, $each_level) === false) {
            $replace .= ', ' . $each_level;
        }
    }
    $replace      = trim(trim($replace), ',');
    $file_content = str_replace($search, "level' => [$replace]", $file_content);
    file_put_contents($file, $file_content);
}

//加载函数库
$file = $document_root_dir . '/application/common.php';
if (is_file($file)) {
    $file_content = file_get_contents($file);
    if (strpos($file_content, 'common_for_smart') === false) {
        if (strpos($file_content, '// 应用公共文件') !== false) {
            $file_content = str_replace('// 应用公共文件', "//smart公共函数\nrequire_once ('common_for_smart.php');\n// 应用公共文件", $file_content);
        } else {
            $file_content .= "//smart公共函数\nrequire_once ('common_for_smart.php');";
        }
        file_put_contents($file, $file_content);
    }
}

//Index 文件处理
$file = $document_root_dir . '/application/index/controller/Index.php';
if (is_file($file)) {
    //删除
    unlink($file);
}
//public/index.php 文件处理
$file = $document_root_dir . '/public/index.php';
if (is_file($file)) {
    $file_content = file_get_contents($file);
    if (strpos($file_content, 'DOCUMENT_ROOT_PATH') === false) {
        //替换内容
        $file_content = str_replace('namespace think;', "namespace think;\n// 定义web根目录\ndefine('DOCUMENT_ROOT_PATH', __DIR__);", $file_content);
    }
    if(strpos($file_content, 'APP_PATH') === false){
        // 定义应用目录
        $file_content = str_replace('define(\'DOCUMENT_ROOT_PATH\', __DIR__);', "define('DOCUMENT_ROOT_PATH', __DIR__);\n// 定义应用目录\ndefine('APP_PATH', DOCUMENT_ROOT_PATH . '/../application/');", $file_content);
    }
    //回写
    file_put_contents($file, $file_content);
}
// think 文件处理
$file = $document_root_dir . '/think';
if (is_file($file)) {
    $file_content = file_get_contents($file);
    if (strpos($file_content, 'DOCUMENT_ROOT_PATH') === false) {
        //替换内容
        $file_content = str_replace('namespace think;', "namespace think;\n// 定义web根目录\ndefine('DOCUMENT_ROOT_PATH', __DIR__.'/public');", $file_content);
    }
    if(strpos($file_content, 'APP_PATH') === false){
        $file_content = str_replace("define('DOCUMENT_ROOT_PATH', __DIR__.'/public');", "define('DOCUMENT_ROOT_PATH', __DIR__.'/public');\n// 定义应用目录\ndefine('APP_PATH', DOCUMENT_ROOT_PATH . '/../application/');", $file_content);
    }
    //回写
    file_put_contents($file, $file_content);
}
