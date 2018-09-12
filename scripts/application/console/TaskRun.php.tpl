<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/5/4
 * Time: 10:23
 */

namespace app\console;


use ClassLibrary\ClDataCronTab;
use ClassLibrary\ClFile;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;
use Workerman\Lib\Timer;
use Workerman\Worker;

/**
 * 任务列表
 * Class TaskRun
 * @package app\console
 */
class TaskRun extends Command {

    /**
     * 配置
     */
    protected function configure() {
        $this->setName('task_run')
            ->addOption('--command', '-c', Option::VALUE_REQUIRED, 'start/启动，start-d/启动（守护进程），status/状态, restart/重启，reload/平滑重启，stop/停止', 'start')
            ->setDescription(sprintf('执行定时任务，请配置:%s', __DIR__ . '/task_run.ini'));
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool
     */
    protected function execute(Input $input, Output $output) {
        $task_ini_file = __DIR__ . '/task_run.ini';
        if (!is_file($task_ini_file)) {
            file_put_contents($task_ini_file, ';执行命令=类似crontab的执行时间定义，支持到秒一级任务定义 */秒 */分 */时 */日 */月 */周
;index/article/capture=*/5 * * * * *');
            exit(sprintf("%s file is created, please editor it.\n", $task_ini_file));
        }
        $command = $input->getOption('command');
        $command = trim($command);
        if (!in_array($command, ['start', 'start-d', 'stop', 'restart', 'reload', 'status'])) {
            $this->help();
        }
        if ($command == 'start-d') {
            $GLOBALS['argv'][1] = 'start';
            $GLOBALS['argv'][2] = '-d';
        } else {
            $GLOBALS['argv'][1] = $command;
        }
        $task = new Worker();
        //进程名称
        $task->name = __FILE__;
        //设置进程id文件地址
        $pid_file = RUNTIME_PATH . 'worker_man/task_run/pid.txt';
        //创建文件夹
        ClFile::dirCreate($pid_file);
        $task::$pidFile = $pid_file;
        //设置日志文件
        $task::$logFile = RUNTIME_PATH . 'worker_man/task_run/log.txt';
        $task->onWorkerStart = function ($task) use ($task_ini_file) {
            $settings = parse_ini_file($task_ini_file);
            foreach ($settings as $command => $cron_date) {
                echo sprintf("[exec command]:%s\n", $command);
                Timer::add(1, function () use ($command, $cron_date) {
                    if (ClDataCronTab::check(time(), $cron_date) === true) {
                        pclose(popen(sprintf("cd %s && php public/index.php %s", DOCUMENT_ROOT_PATH.'/../', $command), 'r'));
                    }
                });
            }
        };
        // 运行worker
        Worker::runAll();
        return true;
    }

    /**
     * 配置文件
     */
    private function help() {
        echo <<<EOT
-h 使用帮助\n-c start/启动，start-d/启动（守护进程），status/状态, restart/重启，reload/平滑重启，stop/停止，default: start\n
EOT;
        exit;
    }

}