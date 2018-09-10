<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/08/10
 * Time: 10:27:59
 */

namespace app\index\model;

use app\index\map\TaskMap;
use think\Exception;

/**
 * 后台任务 Model
 */
class TaskModel extends TaskMap {

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        //先执行父类
        parent::cacheRemoveTrigger($item);
    }

    /**
     * 处理任务
     * @return bool
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function deal() {
        //处理数据
        $item = self::instance()->where([
            self::F_START_TIME => 0
        ])->order([self::F_ID => self::V_ORDER_ASC])->find();
        if (empty($item)) {
            return true;
        }
        //设置正在执行
        self::instance()->where([
            self::F_ID => $item[self::F_ID]
        ])->setField([
            self::F_START_TIME => time()
        ]);
        //执行
        try {
            eval($item[self::F_COMMAND]);
            //设置执行的结束时间
            self::instance()->where([
                self::F_ID => $item[self::F_ID]
            ])->setField([
                self::F_END_TIME => time()
            ]);
        } catch (Exception $e) {
            self::instance()->where([
                self::F_ID => $item[self::F_ID]
            ])->setField([
                self::F_REMARK => $e->getMessage()
            ]);
        }
        return true;
    }

}