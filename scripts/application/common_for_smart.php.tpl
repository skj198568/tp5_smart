<?php
// +----------------------------------------------------------------------
// | ThinkPHP [ WE CAN DO IT JUST THINK ]
// +----------------------------------------------------------------------
// | Copyright (c) 2006-2016 http://thinkphp.cn All rights reserved.
// +----------------------------------------------------------------------
// | Licensed ( http://www.apache.org/licenses/LICENSE-2.0 )
// +----------------------------------------------------------------------
// | Author: 流年 <liu21st@gmail.com>
// +----------------------------------------------------------------------

// 应用公共文件
use think\Log;

/**
 * 写日志函数
 */
function log_info()
{
    $args = func_get_args();
    if (!empty($args)) {
        $function = \ClassLibrary\ClCache::getFunctionHistory(2);
        //日志
        $str = '[' . $function . ']' . call_user_func_array(['\ClassLibrary\ClString', 'toString'], $args);
        Log::record($str, Log::LOG);
    }
}

/**
 * 输出信息
 */
function echo_info()
{
    $args = func_get_args();
    if (!empty($args)) {
        $function = \ClassLibrary\ClCache::getFunctionHistory(2);
        //日志
        $str = '[' . $function . ']' . call_user_func_array(['\ClassLibrary\ClString', 'toString'], $args);
        if (request()->isCli() || request()->isAjax()) {
            echo $str . "\n";
        } else {
            echo $str . '<br/>';
        }
    }
}

/**
 * 记录日志and输出
 */
function le_info()
{
    $args = func_get_args();
    if (!empty($args)) {
        $function = \ClassLibrary\ClCache::getFunctionHistory(2);
        //日志
        $str = '[' . $function . ']' . call_user_func_array(['\ClassLibrary\ClString', 'toString'], $args);
        Log::record($str, Log::LOG);
        //输出
        if (request()->isCli() || request()->isAjax()) {
            echo $str . "\n";
        } else {
            echo $str . '<br/>';
        }
    }
}

/**
 * 获取参数
 * @param string $key 键
 * @param array $verifies 校验器，请采用ClApiParams生成
 * @param string $desc 参数描述，用于自动生成api文档
 * @param null $default 默认值，参考input方法
 * @param string $filter 过滤器，参考input方法
 * @return mixed
 */
function get_param($key = '', $verifies = [], $desc = '', $default = null, $filter = '')
{
    if (strpos($desc, ',') !== false) {
        exit(sprintf('%s含有非法字符","，请改成中文"，"', $desc));
    }
    try {
        $value = input($key, $default, $filter);
    } catch (\InvalidArgumentException $exception) {
        if (strpos($key, '/') == false) {
            //尝试数组方式获取
            $value = input($key . '/a', $default, $filter);
        } else {
            throw $exception;
        }
    }
    //校验参数
    \ClassLibrary\ClFieldVerify::verifyFields([$key => $value], [$key => $verifies]);
    return $value;
}

/**
 * 分页数
 */
const PAGES_NUM = 15;

/**
 * json结果返回
 * @param $data
 * @param bool $is_log
 * @return \think\response\Json|\think\response\Jsonp
 */
function json_return($data, $is_log = false)
{
    //调试模式下，记录信息
    if (\think\App::$debug || $is_log) {
        //将请求地址加入返回数组中，用于区别请求内容
        log_info(json_encode($data, JSON_UNESCAPED_UNICODE), $data);
    }
    $type = isset($_GET['callback']) ? 'JSONP' : 'JSON';
    if ($type == 'JSON') {
        return json($data);
    } else if ($type == 'JSONP') {
        return jsonp($data);
    }
}

/**
 * 加解密key
 */
const CRYPT_KEY = 'Api';
