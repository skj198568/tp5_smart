<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/8/30
 * Time: 18:22
 */

namespace app\api\controller;


use app\api\base\BaseApiController;
use ClassLibrary\ClCrypt;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClVerify;

/**
 * 基础Api接口
 * Class ApiController
 * @package app\api\controller
 */
class ApiController extends BaseApiController {

    /**
     * 用户uid
     * @var int
     */
    protected $id = 0;

    /**
     * 不校验的请求
     * @var array
     */
    protected $uncheck_request = [
        'Index/index'
    ];

    /**
     * 初始化
     */
    public function _initialize() {
        //转小写
        array_walk($this->uncheck_request, function (&$each) {
            $each = strtolower($each);
        });
        parent::_initialize();
        $token = '';
        if (!in_array(strtolower(request()->controller() . '/' . request()->action()), $this->uncheck_request)) {
            $token = get_param('token', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '校验token');
        }
        if (!empty($token)) {
            $this->id = ClCrypt::decrypt($token, CRYPT_KEY);
            if (empty($this->id)) {
                if (ClVerify::isLocalIp(request()->ip()) && is_numeric($token)) {
                    //本机请求
                    $this->id = $token;
                } else {
                    $msg = json_encode([
                        'status'  => -1,
                        'message' => '无效token'
                    ], JSON_UNESCAPED_UNICODE);
                    if (request()->isAjax()) {
                        //输出结果并退出
                        header('Content-Type:application/json; charset=utf-8');
                        echo($msg);
                    } else {
                        echo($msg . PHP_EOL);
                    }
                    exit;
                }
            }
        }
    }

    /**
     * 空请求
     * @return string
     */
    public function _empty() {
        if (strtolower(request()->controller() . DS . request()->action()) == 'index' . DS . 'index' && ClVerify::isLocalIp()) {
            $api_file_name = get_param('api_file_name', [], '接口文件名', '');
            $api_doc_dir   = DOCUMENT_ROOT_PATH . '/../doc/api';
            if (!empty($api_file_name)) {
                $api_file = $api_doc_dir . '/' . $api_file_name . '.html';
                if (is_file($api_file)) {
                    return $this->fetch($api_file);
                }
            }
            $api_files = ClFile::dirGetFiles($api_doc_dir, ['.html']);
            foreach ($api_files as $k => $each) {
                $api_files[$k] = ClFile::getName($each, true);
            }
            //倒序
            arsort($api_files);
            //赋值
            $this->assign('api_files', array_values($api_files));
            return $this->fetch(DOCUMENT_ROOT_PATH . '/../application/console/api_doc_templates/api_list.html');
        } else {
            return '<h1 style="text-align: center;font-size: 5em;">404</h1>';
        }
    }
}