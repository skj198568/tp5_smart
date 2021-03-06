<?php
namespace app\index\controller;


use ClassLibrary\ClString;
use ClassLibrary\ClVerify;
use think\App;
use think\Controller;

/**
 * index 基础
 */
class IndexBaseController extends Controller {

    /**
     * 初始化函数
     */
    public function _initialize() {
        parent::_initialize();
        if (App::$debug) {
            log_info('$_REQUEST:', request()->request());
        }
    }

    /**
     * 空请求
     * @return string
     */
    public function _empty() {
        $file = request()->module() . DS . 'view' . DS . request()->controller() . DS . request()->action() . '.html';
        $file = ClString::toArray($file);
        foreach ($file as $k_char => $char) {
            if (ClVerify::isAlphaCapital($char)) {
                $file[$k_char] = '_' . $char;
            }
        }
        $file = implode('', $file);
        $file = str_replace([DS . '_'], [DS], $file);
        $file = strtolower($file);
        if (is_file(APP_PATH . $file)) {
            return $this->fetch(APP_PATH . $file);
        } else {
            if (ClVerify::isLocalIp()) {
                log_info(request()->controller(), request()->action());
                echo sprintf("the file '<span style=\"color: red;\">%s</span>' is not exist", $file);
                exit;
            } else {
                return '<h1 style="text-align: center;font-size: 5em;">404</h1>';
            }
        }
    }

}