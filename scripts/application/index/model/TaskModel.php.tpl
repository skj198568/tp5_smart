<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2020/01/31
 * Time: 13:19:05
 */

namespace app\index\model;

use app\index\map\TaskMap;

/**
 * 后台任务
 * 如果有需要，请重写父类接口，不可直接修改父类函数，会被自动覆盖掉。
 * Class TaskModel
 * @package app\index\model
 */
class TaskModel extends TaskMap {

    /**
     * 初始化
     */
    public function initialize() {
        parent::initialize();
    }

    /**
     * 在插入之前处理数据
     * @param array $info
     * @return array
     */
    protected function triggerBeforeInsert($info) {
        return parent::triggerBeforeInsert($info);
    }

    /**
     * 在插入之后处理数据，调用父类triggerGetItems获取数据
     * @param array|int $insert_id_or_ids
     */
    protected function triggerAfterInsert($insert_id_or_ids) {
        parent::triggerAfterInsert($insert_id_or_ids);
    }

    /**
     * 在更新之前处理数据
     * @param array $info
     * @return array
     */
    protected function triggerBeforeUpdate($info) {
        return parent::triggerBeforeUpdate($info);
    }

    /**
     * 在更新之后处理数据，调用父类triggerGetItems获取数据
     * @param string $sql
     */
    protected function triggerAfterUpdate($sql) {
        parent::triggerAfterUpdate($sql);
    }

    /**
     * 在删除数据之前处理数据
     * @param array $items
     */
    protected function triggerBeforeDelete($items) {
        parent::triggerBeforeDelete($items);
    }

    /**
     * 在删除数据之后处理数据
     * @param array $items
     */
    protected function triggerAfterDelete($items) {
        parent::triggerAfterDelete($items);
    }

    /**
     * 缓存清除器，调用父类triggerGetItems获取数据
     * @param string $sql 查询sql
     * @param array $ids id数组
     * @param array $items 数据数组
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     * @throws \think\exception\PDOException
     */
    protected function triggerRemoveCache($sql = '', $ids = [], $items = []) {
        parent::triggerRemoveCache($sql, $ids, $items);
    }

}