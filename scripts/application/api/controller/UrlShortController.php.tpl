<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/11/06
 * Time: 17:08:46
 */

namespace app\api\controller;

use app\api\base\UrlShortBaseApiController;
use app\index\model\UrlShortModel;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClHttp;

/**
 * 短网址
 * 如果有需要，请重写父类接口，不可直接修改父类函数，会被自动覆盖掉。
 * Class UrlShortController
 * @package app\api\controller
 */
class UrlShortController extends UrlShortBaseApiController {

    /**
     * 跳转地址
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function jump() {
        $short_url = get_param('short_url', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '短连接地址');
        //获取
        $info = UrlShortModel::getByShortUrl($short_url);
        //默认跳转地址
        $jump_url = ClHttp::getServerDomain() . '/';
        if (!empty($info)) {
            //判断超时时间
            if (empty($info[UrlShortModel::F_END_TIME]) || $info[UrlShortModel::F_END_TIME] > time()) {
                $jump_url = $info[UrlShortModel::F_TRUE_URL];
                if (strpos($info[UrlShortModel::F_TRUE_URL], '/') === 0) {
                    $jump_url = ClHttp::getServerDomain() . $info[UrlShortModel::F_TRUE_URL];
                }
            }
        }
        //跳转地址
        $this->redirect($jump_url);
    }

}