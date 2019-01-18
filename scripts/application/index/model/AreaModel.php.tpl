<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/05/05
 * Time: 19:58:34
 */

namespace app\index\model;

use app\index\map\AreaMap;

/**
 * 地址信息 Model
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