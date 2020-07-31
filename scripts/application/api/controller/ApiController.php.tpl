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
use ClassLibrary\ClVerify;

/**
 * 基础Api接口
 * Class ApiController
 * @package app\api\controller
 */
class ApiController extends BaseApiController {

    /**
     * 加密key
     * @var string
     */
    protected $api_token_crypt_key = 'key_api';

    /**
     * 不校验的请求
     * @var array
     */
    protected $uncheck_request = [
        
    ];

    /**
     * 初始化
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function _initialize() {
        parent::_initialize();
        //合并
        $this->uncheck_request = array_merge($this->default_uncheck_request, $this->uncheck_request);
        $ca_ignore_all         = request()->controller() . '/*';
        $ca                    = request()->controller() . '/' . request()->action();
        //忽略全部或忽略当前请求
        if (ClArray::inArrayIgnoreCase($ca_ignore_all, $this->uncheck_request) || ClArray::inArrayIgnoreCase($ca, $this->uncheck_request)) {
            $token = get_param('token', ClFieldVerify::instance()->fetchVerifies(), '校验token', '');
        } else {
            $token = get_param('token', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '校验token');
        }
        if (!empty($token)) {
            $uid = $this->getIdByToken($token);
            //设置uid
            setUid($uid);
        }
    }

    /**
     * 获取token
     * @param $id
     * @param bool $add_ip 是否添加ip
     * @return mixed
     */
    protected function getTokenById($id, $add_ip = false) {
        $ip = '';
        if ($add_ip) {
            $ip = request()->ip();
        }
        $value = json_encode([$id, $ip, rand(0, 999)]);
        return ClCrypt::encrypt($value, $this->api_token_crypt_key);
    }

    /**
     * 依据token获取id
     * @param $token
     * @return int|string
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    protected function getIdByToken($token) {
        if (ClVerify::isLocalIp(request()->ip()) && is_numeric($token)) {
            $id = $token;
        } else {
            $result = ClCrypt::decrypt($token, $this->api_token_crypt_key);
            if ($result === false) {
                $id = null;
            } else {
                list($id, $ip, $rand) = json_decode($result, true);
                //ip不一致
                if (!empty($ip)) {
                    //admin登录
                    if ($ip != request()->ip()) {
                        $id = null;
                    }
                } else {
                    //登陆类型为user

                }
            }
        }
        if (!is_numeric($id)) {
            $response = $this->ar(-2, '无效token');
            $response->send();
            exit;
        }
        return $id;
    }

}