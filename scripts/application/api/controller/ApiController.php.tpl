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
use app\index\model\BaseModel;
use ClassLibrary\ClArray;
use ClassLibrary\ClCrypt;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClVerify;

/**
 * 基础Api接口
 * Class ApiController
 * @package app\api\controller
 */
class ApiController extends BaseApiController {

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
        } else {
            $token = get_param('token', ClFieldVerify::instance()->fetchVerifies(), '校验token', '');
        }
        if (!empty($token)) {
            $uid = ClCrypt::decrypt($token, CRYPT_KEY);
            if (empty($uid)) {
                if (ClVerify::isLocalIp(request()->ip()) && is_numeric($token)) {
                    //本机请求
                    $uid = $token;
                } else {
                    $response = $this->ar(-2, '无效token');
                    $response->send();
                    exit;
                }
            }
            //设置uid
            setUid($uid);
        }
    }

}