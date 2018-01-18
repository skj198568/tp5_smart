<?php
/**
 * update或install之后执行复制文件
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/12/06
 * Time: 15:56
 */
include_once __DIR__."/../class_library/ClassLibrary/ClFile.php";
include_once __DIR__."/../class_library/ClassLibrary/ClSystem.php";
include_once __DIR__."/../class_library/ClassLibrary/ClString.php";

$files = \ClassLibrary\ClFile::dirGetFiles(__DIR__.DIRECTORY_SEPARATOR.'scripts');
//往上3个目录
$document_root_dir = explode(DIRECTORY_SEPARATOR, __DIR__);
$document_root_dir = array_slice($document_root_dir, 0, count($document_root_dir)-3);
$document_root_dir = implode(DIRECTORY_SEPARATOR, $document_root_dir);
//var_dump($document_root_dir);
//循环覆盖文件
foreach($files as $file){
    $target_file = $document_root_dir.str_replace(__DIR__.DIRECTORY_SEPARATOR.'scripts', '', $file);
    //替换文件名
    $target_file = str_replace('.php.tpl', '.php', $target_file);
    //如果目标文件不存在，则新建
    \ClassLibrary\ClFile::dirCreate($target_file);
    //不可直接覆盖的文件特殊处理
    if(strpos($target_file, 'ApiController') !== false || strpos($target_file, 'task_run.ini') !== false){
        if(!is_file($target_file)){
            //如果文件不存在，则覆盖文件，存在则忽略
            echo 'copy file: '.$target_file.PHP_EOL;
            copy($file, $target_file);
        }
    }else if(strpos($target_file, 'tags.php') !== false){
        if(!is_file($target_file)){
            //直接复制
            echo 'copy file: '.$target_file.PHP_EOL;
            copy($file, $target_file);
        }else{
            //更改内容
            $file_content = file_get_contents($target_file);
            $str = \ClassLibrary\ClString::getBetween($file_content, 'view_filter', ']');
            //再次获取
            $str_params = \ClassLibrary\ClString::getBetween($str, '[', ']');
            if($str_params == '[]'){
                //直接添加
                $str_target = str_replace($str_params, "['app\\common\\behavior\\MergeResource', 'app\\common\\behavior\\BrowserSyncJsMerge']", $str);
                //替换
                $file_content = str_replace($str, $str_target, $file_content);
                //回写
                file_put_contents($target_file, $file_content);
                echo 'modify file: '.$target_file.PHP_EOL;
            }else{
                if(strpos($str_params, 'MergeResource') === false && strpos($str_params, 'BrowserSyncJsMerge') === false){
                    //拼接添加
                    $str_target = str_replace($str_params, trim($str_params, ']').", 'app\\common\\behavior\\MergeResource', 'app\\common\\behavior\\BrowserSyncJsMerge']", $str);
                    //替换
                    $file_content = str_replace($str, $str_target, $file_content);
                    //回写
                    file_put_contents($target_file, $file_content);
                    echo 'modify file: '.$target_file.PHP_EOL;
                }
            }
        }
    }else if(strpos($target_file, 'command.php') !== false){
        $file_content = file_get_contents($target_file);
        //处理换行
        if(strpos($file_content, '[]') !== false){
            $file_content = str_replace('];', "\n];", $file_content);
        }
        foreach(['app\console\SmartInit', 'app\console\BrowserSync', 'app\console\TaskRun', 'app\console\ApiDoc'] as $each_command){
            //判断是否存在
            if(strpos($file_content, $each_command) === false){
                $file_content = str_replace('];', "\t'$each_command',\n];", $file_content);
            }
        }
        //回写文件
        file_put_contents($target_file, $file_content);
        echo 'modify file: '.$target_file.PHP_EOL;
    }else{
        //覆盖文件
        echo 'copy file: '.$target_file.PHP_EOL;
        copy($file, $target_file);
    }
}
//linux 环境处理mkdir 755问题
$files = [
    //日志
    $document_root_dir.'/thinkphp/library/think/File.php',
    //日志
    $document_root_dir.'/thinkphp/library/think/log/driver/File.php',
    //缓存
    $document_root_dir.'/thinkphp/library/think/cache/driver/File.php',
    //模板缓存
    $document_root_dir.'/thinkphp/library/think/template/driver/File.php',
];
foreach($files as $file){
    //替换目录分隔符
    $file = str_replace('/', DIRECTORY_SEPARATOR, $file);
    if(!is_file($file)){
        echo $file.' not exist'.PHP_EOL;
        continue;
    }
    echo 'chown file: '.$file.PHP_EOL;
    $file_content = file_get_contents($file);
    if(strpos($file_content, 'chmod 0777 %s -R') !== false){
        //已经处理过，不再进行处理
        continue;
    }
    $file_content_array = explode("\n", $file_content);
    $file_content_array_new = [];
    foreach($file_content_array as $file_line){
        $file_content_array_new[] = $file_line;
        //新增文件夹，自动更改用户组
        if(strpos($file_line, 'mkdir') !== false){
            $dir = \ClassLibrary\ClString::getBetween($file_line, 'mkdir', ',', false);
            //去除左侧（
            $dir = \ClassLibrary\ClString::getBetween($dir, '(', '', false);
            //cli模式下文件夹权限修改
            $file_content_array_new[] = "IS_CLI && !IS_WIN && exec(sprintf('chmod 0777 %s -R', $dir));";
        }
    }
    $file_content = implode("\n", $file_content_array_new);
    //重新写入文件
    file_put_contents($file, $file_content);
}
//系统config文件修复
$file = $document_root_dir.'/application/config.php';
if(is_file($file)){
    $file_content = file_get_contents($file);
    //控制器
    $search = \ClassLibrary\ClString::getBetween($file_content, 'controller_suffix', ',');
    $file_content = str_replace($search, "controller_suffix' => true,", $file_content);
    //模板
    $search = \ClassLibrary\ClString::getBetween($file_content, 'taglib_begin', ',');
    $file_content = str_replace($search, "taglib_begin' => '<',", $file_content);
    $search = \ClassLibrary\ClString::getBetween($file_content, 'taglib_end', ',');
    $file_content = str_replace($search, "taglib_end' => '>',", $file_content);
    //日志级别修改
    $search = \ClassLibrary\ClString::getBetween($file_content, 'level', ']');
    $replace = \ClassLibrary\ClString::getBetween($search, '[', ']', false);
    $replace = trim($replace, ',');
    foreach(['\think\Log::ERROR', '\think\Log::NOTICE', '\think\Log::SQL', '\think\Log::LOG'] as $each_level){
        if(strpos($replace, $each_level) === false){
            $replace .= ', '. $each_level;
        }
    }
    $replace = trim(trim($replace), ',');
    $file_content = str_replace($search, "level' => [$replace]", $file_content);
    //回写
    file_put_contents($file, $file_content);
}
//Index 文件处理
$file = $document_root_dir.'/application/index/controller/Index.php';
if(is_file($file)){
    //替换内容
    $file_content = file_get_contents($file);
    $file_content = str_replace('class Index', 'class IndexController', $file_content);
    //回写
    file_put_contents($file, $file_content);
    //重命名
    rename($file, str_replace('Index.php', 'IndexController.php', $file));
}
//public/index.php 文件处理
$file = $document_root_dir.'/public/index.php';
if(is_file($file)){
    $file_content = file_get_contents($file);
    if(strpos($file_content, 'DOCUMENT_ROOT_PATH') === false){
        //替换内容
        $file_content = str_replace('// [ 应用入口文件 ]', "// [ 应用入口文件 ]\ndefine('DOCUMENT_ROOT_PATH', __DIR__);", $file_content);
        $file_content = str_replace("__DIR__ . '/../application/'", "DOCUMENT_ROOT_PATH . '/../application/'", $file_content);
        //回写
        file_put_contents($file, $file_content);
    }
}
// think 文件处理
$file = $document_root_dir.'/think';
if(is_file($file)){
    $file_content = file_get_contents($file);
    //替换内容
    $file_content = str_replace("define('APP_PATH', __DIR__ . '/application/');", "define('DOCUMENT_ROOT_PATH', __DIR__);\ndefine('APP_PATH', DOCUMENT_ROOT_PATH . '/application/');", $file_content);
    //回写
    file_put_contents($file, $file_content);
}
