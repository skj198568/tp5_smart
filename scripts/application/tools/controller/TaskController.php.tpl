<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2018-7-6
 * Time: 10:16
 */

namespace app\tools\controller;

use app\index\model\TaskModel;
use think\facade\Log;

/**
 * 任务
 * Class TaskController
 * @package app\tools\controller
 */
class TaskController extends ToolsBaseController {

    /**
     * 初始化函数
     */
    public function _initialize() {
        if (!request()->isCli()) {
            echo_info('只能命令行访问');
            exit;
        }
        //取消日志相关兼容处理
        Log::init(['level' => ['task_run'], 'allow_key' => ['task_run']]);
        Log::key(time());
    }

    /**
     * 处理任务
     * @return int
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function deal() {
        $begin_time = time();
        //处理任务
        TaskModel::deal();
        return (time() - $begin_time) . "s\n";
    }

}