<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2019/01/23
 * Time: 17:29:27
 */

namespace app\index\model;

use app\index\map\AreaMap;

/**
 * 地址信息
 * 如果有需要，请重写父类接口，不可直接修改父类函数，会被自动覆盖掉。
 * Class AreaModel
 * @package app\index\model
 */
class AreaModel extends AreaMap {

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