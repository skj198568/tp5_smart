<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2018/4/10
 * Time: 14:23
 */

namespace app\migrate\controller;

use ClassLibrary\ClCrypt;
use ClassLibrary\ClFieldVerify;

/**
 * 用户相关
 * Class UserController
 * @package app\migrate\controller
 */
class UserController extends MigrateBaseController {

    /**
     * 登录
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function login() {
        $users_file = __DIR__ . '/../data/users.ini';
        $users      = parse_ini_file($users_file, true);
        $account    = get_param('account', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '账号');
        $password   = get_param('password', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '密码');
        foreach ($users['users'] as $each_user) {
            $each_user = explode(',', $each_user);
            array_walk($each_user, function (&$each) {
                $each = trim($each);
            });
            if ($each_user[0] == $account) {
                if ($each_user[1] == md5(md5($password))) {
                    $each_user['token'] = ClCrypt::encrypt($each_user[0], CRYPT_KEY);
                    return $this->ar(1, ['info' => $each_user]);
                } else {
                    return $this->ar(2, ['message' => '密码错误']);
                }
                break;
            }
        }
        return $this->ar(3, ['message' => '账号不存在']);
    }

    /**
     * 获取个人信息
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function get() {
        $users_file = __DIR__ . '/../data/users.ini';
        $users      = parse_ini_file($users_file, true);
        foreach ($users['users'] as $each_user) {
            $each_user = explode(',', $each_user);
            array_walk($each_user, function (&$each) {
                $each = trim($each);
            });
            if ($each_user[0] == $this->account) {
                return $this->ar(1, ['info' => $each_user]);
            }
        }
        return $this->ar(2, ['message' => '不存在当前用户']);
    }

}