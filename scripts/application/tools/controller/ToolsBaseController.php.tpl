<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/9/20
 * Time: 14:32
 */

namespace app\tools\controller;

use ClassLibrary\ClString;
use ClassLibrary\ClVerify;
use think\App;
use think\Controller;

/**
 * 工具
 * Class ToolsController
 * @package app\tools\controller
 */
class ToolsBaseController extends Controller {

    /**
     * 初始化函数
     */
    public function _initialize() {
        parent::_initialize();
        if (!request()->isCli()) {
            echo_info('只能命令行访问');
            exit;
        }
        if (App::$debug) {
            log_info('$_REQUEST:', $_REQUEST);
        }
    }

    /**
     * 返回信息
     * @param int $code 返回码
     * @param array $data 返回的值
     * @param string $example 例子，用于自动生成api文档
     * @param bool $is_log
     * @return \think\response\Json|\think\response\Jsonp
     */
    protected function ar($code, $data = [], $example = '', $is_log = false) {
        $status = sprintf('%s/%s/%s/%s', request()->module(), request()->controller(), request()->action(), $code);
        //格式化
        $status = ClString::toArray($status);
        foreach ($status as $k_status => $v_status) {
            if (ClVerify::isAlphaCapital($v_status)) {
                $status[$k_status] = '_' . strtolower($v_status);
            }
        }
        //转换为字符串
        $status = implode('', $status);
        $status = str_replace('/_', '/', $status);
        $data   = is_array($data) ? $data : [$data];
        return json_return(array_merge([
            'status' => $status,
        ], $data), $is_log);
    }

}