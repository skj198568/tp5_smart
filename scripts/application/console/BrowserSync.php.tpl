<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017-04-07
 * Time: 17:37
 */

namespace app\console;

use ClassLibrary\ClFile;
use ClassLibrary\ClMergeResource;
use ClassLibrary\ClString;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;
use think\facade\Env;
use Workerman\Lib\Timer;
use Workerman\Worker;

/**
 * 浏览器自动刷新
 * Class BrowserSync
 * @package app\console
 */
class BrowserSync extends Command {

    /**
     * socket端口
     * @var int
     */
    private $socket_port = 8000;

    /**
     * 实例对象
     * @var BrowserSync
     */
    private static $instance_instance = null;

    /**
     * 监听文件结果
     * @var array
     */
    private $scan_files = [];

    /**
     * 实例对象
     * @return BrowserSync
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
        return Env::get('runtime_path') . 'worker_man/browser_sync/pid.txt';
    }

    /**
     * pid文件地址
     * @return string
     */
    private function getLogSrc() {
        return Env::get('runtime_path') . 'worker_man/browser_sync/log.txt';
    }

    /**
     * pid文件地址
     * @return string
     */
    private function getPortSrc() {
        return Env::get('runtime_path') . 'worker_man/browser_sync/port.txt';
    }

    /**
     * 配置文件
     */
    protected function configure() {
        $this->setName('browser_sync')
            ->addOption('--file_types', '-f', Option::VALUE_REQUIRED, '监听变化的文件后缀名，例如：".html;.js;.css"', '".html;.js;.css"')
            ->addOption('--dirs', '-d', Option::VALUE_REQUIRED, '监听web根目录下变化的文件夹，分号分割，例如：application;public', 'application;public')
            ->addOption('--ignore_dirs', '-i', Option::VALUE_REQUIRED, '忽略监听的文件夹，例如：resource', 'resource')
            ->addOption('--port', '-p', Option::VALUE_REQUIRED, 'socket监听的端口，注意防火墙的设置', '8000')
            ->addOption('--command', '-c', Option::VALUE_REQUIRED, 'start/启动，start-d/启动（守护进程），status/状态, restart/重启，reload/平滑重启，stop/停止', 'start')
            ->setDescription('Monitor the server file, automatically refresh the browser when the file is modified[监听服务器文件，当文件修改时，自动同步刷新浏览器].');
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool
     */
    protected function execute(Input $input, Output $output) {
        set_time_limit(0);
        //创建文件夹
        ClFile::dirCreate($this->getPortSrc());
        $this->socket_port = $input->getOption('port');
        //校验文件类型
        $files_types = $input->getOption('file_types');
        $files_types = trim(trim($files_types, '"'), "'");
        if (empty($files_types)) {
            $output->error('请输入监听文件files的类型');
            return false;
        }
        $command = $input->getOption('command');
        $command = trim($command);
        if (in_array($command, ['start', 'start-d'])) {
            $output->highlight(sprintf('监听文件:%s', $files_types));
        }
        return $this->syncClient($input, $output);
    }

    /**
     * 同步客户端
     * @param Input $input
     * @param Output $output
     * @return bool
     */
    private function syncClient(Input $input, Output $output) {
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
        $worker::$logFile      = $this->getLogSrc();
        $worker->onWorkerStart = function (Worker $worker) use ($input) {
            //定时器定时监听
            Timer::add(1, function () use ($worker, $input) {
                //记录端口号，用于生成js自动刷新代码
                $this->port($this->socket_port);
                if ($this->fileIsModify($input)) {
                    //先清空页面缓存
                    ClMergeResource::clearCache();
                    foreach ($worker->connections as $connection_each) {
                        $connection_each->close('sync');
                        usleep(1000000);
                    }
                }
            });
        };
        $worker->onWorkerStop  = function ($worker) {
            //删除端口号
            $this->port(-1);
            //刷新页面
            foreach ($worker->connections as $connection_each) {
                $connection_each->close('sync');
                usleep(1000000);
            }
        };
        // 运行worker
        Worker::runAll();
        return true;
    }

    /**
     * 端口号
     * @param int $port 0/获取， < 0 / 删除，> 0 / 设置
     * @return bool|mixed
     */
    public function port($port = 0) {
        //清除缓存
        clearstatcache();
        if (empty($port)) {
            if (is_file($this->getPortSrc())) {
                //该文件修改时间小于安全时间，则判断当前监听无效
                if (filemtime($this->getPortSrc()) + 2 < time()) {
                    //清除无效文件
                    foreach ([$this->getPortSrc(), $this->getPidSrc(), $this->getLogSrc()] as $file) {
                        if (is_file($file)) {
                            unlink($file);
                        }
                    }
                    return null;
                } else {
                    return file_get_contents($this->getPortSrc());
                }
            } else {
                return null;
            }
        } else if ($port > 0) {
            return file_put_contents($this->getPortSrc(), $port);
        } else {
            return unlink($this->getPortSrc());
        }
    }

    /**
     * 获取js拼接内容
     * @return string
     */
    public function getJsContent() {
        $port = $this->port();
        //服务如果没有开启
        if (empty($port)) {
            return '';
        }
        //如果以端口方式访问
        $host = request()->host();
        if (strpos($host, ':') !== false) {
            return '';
        }
        if (input('browser_sync', 1) == 0 || cookie('?browser_sync')) {
            cookie('browser_sync', 0, 3600 * 10);
            return '';
        } else {
            //删除cookie
            cookie('browser_sync', null);
        }
        return sprintf('<script type="text/javascript">
    var ws = new WebSocket(\'ws://%s:%s\');
    ws.onopen = function(){
        console.log("connected for browser_sync");
    };
    ws.onclose = function(){
        window.location.reload();
    };
    ws.onerror = function(event){
        console.log(event.data);
    };
</script>', $host, $port);
    }

    /**
     * 获取监听的文件是否被修改
     * @param Input $input
     * @return bool
     */
    private function fileIsModify(Input $input) {
        //清除缓存
        clearstatcache();
        $last_scan_files = $this->scan_files;
        $files_types     = $input->getOption('file_types');
        //去除两端引号
        $files_types = explode(';', trim(trim(str_replace(['；', '"', "'"], [';', '', ''], $files_types)), ';'));
        array_walk($files_types, function (&$each) {
            $each = trim($each);
        });
        $root_path   = dirname(dirname(__DIR__));
        $dirs        = $input->getOption('dirs');
        $dirs        = explode(';', trim(trim(str_replace('；', ';', $dirs)), ';'));
        $ignore_dirs = $input->getOption('ignore_dirs');
        $ignore_dirs = explode(';', trim(trim(str_replace('；', ';', $ignore_dirs)), ';'));
        $files       = [];
        foreach ($dirs as $dir) {
            $dir = trim($dir);
            if (empty($dir) || !is_dir($root_path . '/' . $dir)) {
                continue;
            }
            $files = array_merge($files, ClFile::dirGetFiles($root_path . '/' . $dir, $files_types, $ignore_dirs));
        }
        $scan_files = [];
        //文件内容改变，md5_file计算时间较长，以文件最后修改的时间为判断依据
        if (!empty($files)) {
            foreach ($files as $file) {
                $scan_files[$file] = filemtime($file);
            }
        }
        //判断文件是否改变
        $has_modify = false;
        //文件不存在
        if (empty($last_scan_files)) {
            $has_modify = true;
        } else {
            foreach ($scan_files as $file => $modify_time) {
                if (!array_key_exists($file, $last_scan_files) || $last_scan_files[$file] != $modify_time) {
                    echo sprintf("[%s] %s\n", date('Y-m-d H:i:s'), $file);
                    $has_modify = true;
                    break;
                }
            }
        }
        //设置新文件记录
        $this->scan_files = $scan_files;
        return $has_modify;
    }

    /**
     * 析构函数
     */
    public function __destruct() {

    }

}