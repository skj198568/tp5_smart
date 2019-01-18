<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/11/06
 * Time: 17:08:46
 */

namespace app\index\model;

use app\index\map\UrlShortMap;

/**
 * 短网址 Model
 */
class UrlShortModel extends UrlShortMap {

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        //先执行父类
        parent::cacheRemoveTrigger($item);
    }

}