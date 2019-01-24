<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2019/01/24
 * Time: 16:32:23
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
     * 在操作数据库之前预处理数据
     * @param array $data
     * @param string $operate_type 操作类型insert/update
     * @return array
     */
    protected function preprocessDataBeforeOperateDb($data, $operate_type) {
        $data = parent::preprocessDataBeforeOperateDb($data, $operate_type);
        return $data;
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