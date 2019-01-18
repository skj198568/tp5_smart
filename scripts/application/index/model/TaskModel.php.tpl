<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/08/10
 * Time: 10:27:59
 */

namespace app\index\model;

use app\index\map\TaskMap;

/**
 * 后台任务 Model
 */
class TaskModel extends TaskMap {

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