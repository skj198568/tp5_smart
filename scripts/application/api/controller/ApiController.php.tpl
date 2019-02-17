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
use ClassLibrary\ClArray;
use ClassLibrary\ClCrypt;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClVerify;
use think\App;

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
    ];

    /**
     * 初始化
     */
    public function _initialize() {
        parent::_initialize();
        $token = '';
        //合并
        $this->uncheck_request = array_merge($this->default_uncheck_request, $this->uncheck_request);
        if (!ClArray::inArrayIgnoreCase(request()->controller() . '/' . request()->action(), $this->uncheck_request)) {
            $token = get_param('token', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '校验token');
        }
        if (!empty($token)) {
            $this->id = ClCrypt::decrypt($token, CRYPT_KEY);
            if (empty($this->id)) {
                if (ClVerify::isLocalIp(request()->ip()) && is_numeric($token)) {
                    //本机请求
                    $this->id = $token;
                } else {
                    $response = json_return([
                        'status'  => -2,
                        'message' => '无效token'
                    ]);
                    $response->send();
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
        if (strtolower(request()->controller() . DS . request()->action()) == 'index' . DS . 'index' && App::$debug) {
            $api_doc_dir = DOCUMENT_ROOT_PATH . '/../doc/api';
            $api_files   = ClFile::dirGetFiles($api_doc_dir, ['.html']);
            foreach ($api_files as $k => $each) {
                $api_files[$k] = ClFile::getName($each, true);
            }
            //倒序
            arsort($api_files);
            $newest_api_file = $api_files[0];
            return $this->fetch($api_doc_dir . '/' . $newest_api_file);
        } else {
            return '<h1 style="text-align: center;font-size: 5em;">404</h1>';
        }
    }

}