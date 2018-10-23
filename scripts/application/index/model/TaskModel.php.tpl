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
        log_info('task-start-' . $item[self::F_ID]);
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
                self::F_REMARK => json_encode([
                    'message' => $e->getMessage(),
                    'file'    => $e->getFile(),
                    'line'    => $e->getLine(),
                    'code'    => $e->getCode()
                ], JSON_UNESCAPED_UNICODE)
            ]);
        }
        //结束
        log_info('task-end-' . $item[self::F_ID]);
        return true;
    }

    /**
     * 创建任务
     * @param string $command 类似任务命令:app\index\model\AdminLoginLogModel::sendEmail();
     * @param int $within_seconds_ignore_this_cmd 在多长时间内忽略该任务，比如某些不需要太精确的统计任务，可以设置为60秒，即60秒内只执行一次任务
     * @return bool|int|string
     */
    public static function createTask($command, $within_seconds_ignore_this_cmd = 0) {
        $is_insert = true;
        if ($within_seconds_ignore_this_cmd > 0) {
            $last_create_time = self::instance()->where([
                self::F_COMMAND => $command
            ])->order([self::F_ID => self::V_ORDER_DESC])->value(self::F_CREATE_TIME);
            if (!is_numeric($last_create_time) || time() - $last_create_time > $within_seconds_ignore_this_cmd) {
                $is_insert = true;
            } else {
                $is_insert = false;
            }
        }
        if ($is_insert) {
            //新增
            return self::instance()->insert([
                self::F_COMMAND => $command
            ]);
        } else {
            return false;
        }
    }

}