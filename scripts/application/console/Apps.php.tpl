<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2018-7-18
 * Time: 22:44
 */

namespace app\console;


use ClassLibrary\ClFile;
use ClassLibrary\ClString;
use ClassLibrary\ClSystem;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;
use Workerman\Connection\TcpConnection;
use Workerman\Worker;

/**
 * 小程序
 * Class Apps
 * @package app\console
 */
class Apps extends Command {

    /**
     * socket端口
     * @var int
     */
    private $socket_port = 9000;

    /**
     * 实例对象
     * @var Apps
     */
    private static $instance_instance = null;

    /**
     * 实例对象
     * @return Apps
     */
    public static function instance() {
        if (self::$instance_instance == null) {
            self::$instance_instance = new self();
        }
        return self::$instance_instance;
    }

    /**
     * pid文件地址
     * @return string
     */
    private function getPidSrc() {
        return RUNTIME_PATH . 'worker_man/apps/pid.txt';
    }

    /**
     * pid文件地址
     * @return string
     */
    private function getLogSrc() {
        return RUNTIME_PATH . 'worker_man/apps/log.txt';
    }

    /**
     * pid文件地址
     * @return string
     */
    private function getPortSrc() {
        return RUNTIME_PATH . 'worker_man/apps/port.txt';
    }

    /**
     * 配置文件
     */
    protected function configure() {
        $this->setName('apps')
            ->addOption('--port', '-p', Option::VALUE_REQUIRED, 'socket监听的端口，注意防火墙的设置', '9000')
            ->addOption('--command', '-c', Option::VALUE_REQUIRED, 'start/启动，start-d/启动（守护进程），status/状态, restart/重启，reload/平滑重启，stop/停止', 'start')
            ->setDescription('wx mini apps wss service[微信小程序wss服务]');
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool|int|null
     */
    protected function execute(Input $input, Output $output) {
        if (ClSystem::isWin()) {
            $output->error('请在Linux环境下执行');
            return false;
        }
        set_time_limit(0);
        //创建文件夹
        ClFile::dirCreate($this->getPortSrc());
        $this->socket_port = $input->getOption('port');
        $command           = $input->getOption('command');
        $command           = trim($command);
        if (in_array($command, ['start', 'start-d'])) {
            $output->highlight(sprintf('监听端口:%s', $this->socket_port));
        }
        return $this->service($input, $output);
    }

    /**
     * 服务处理
     * @param Input $input
     * @param Output $output
     * @return bool
     */
    private function service(Input $input, Output $output) {
        $command = $input->getOption('command');
        $command = trim($command);
        $command = ClString::spaceManyToOne($command);
        if (!in_array($command, ['start', 'start-d', 'stop', 'restart', 'reload', 'status'])) {
            $output->highlight('command input:' . $command . ' error，请输入如下命令：start/启动，start -d/启动（守护进程），status/状态, restart/重启，reload/平滑重启，stop/停止');
            exit;
        }
        if ($command == 'start-d') {
            $GLOBALS['argv'][1] = 'start';
            $GLOBALS['argv'][2] = '-d';
        } else {
            $GLOBALS['argv'][1] = $command;
        }
        $worker = new Worker(sprintf('websocket://0.0.0.0:%s', $this->socket_port));
        //进程名称
        $worker->name = __FILE__;
        //设置进程id文件地址
        $worker::$pidFile = $this->getPidSrc();
        //设置日志文件
        $worker::$logFile = $this->getLogSrc();

        /**
         * 启动
         * @param Worker $worker
         */
        $worker->onWorkerStart = function (Worker $worker) {

        };

        /**
         * 连接
         * @param TcpConnection $connection
         */
        $worker->onConnect = function (TcpConnection $connection) {
            $connection->send('hello ' . $connection->getRemoteIp());
        };

        /**
         * 接受信息
         * @param TcpConnection $connection
         * @param $data
         */
        $worker->onMessage = function (TcpConnection $connection, $data) {
            echo "recv: " . $connection->getRemoteIp() . $data . "\n";
        };

        /**
         * 停止
         * @param Worker $worker
         */
        $worker->onWorkerStop = function (Worker $worker) {
            //关闭所有连接
            foreach ($worker->connections as $connection_each) {
                $connection_each->close('apps close all');
            }
        };

        // 运行worker
        Worker::runAll();
        return true;
    }

    /**
     * 析构函数
     */
    public function __destruct() {

    }
}