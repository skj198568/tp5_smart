<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2019/01/23
 * Time: 17:29:27
 */

namespace app\index\model;

use app\index\map\UrlShortMap;

/**
 * 短网址
 * 如果有需要，请重写父类接口，不可直接修改父类函数，会被自动覆盖掉。
 * Class UrlShortModel
 * @package app\index\model
 */
class UrlShortModel extends UrlShortMap {

    /**
     * 初始化
     */
    public function initialize() {
        parent::initialize();
    }

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        //先执行父类
        parent::cacheRemoveTrigger($item);
    }

}