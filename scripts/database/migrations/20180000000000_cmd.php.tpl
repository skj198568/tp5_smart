<?php

use Phinx\Migration\AbstractMigration;
use ClassLibrary\ClMigrateTable;
use ClassLibrary\ClMigrateField;

class Cmd extends \think\migration\Migrator {

    /**
     * 执行
     */
    public function up() {
        $this->checkExecFunction();
    }

    /**
     * 回滚
     */
    public function down() {
        $this->checkExecFunction();
    }

    /**
     * 检查exec函数
     */
    private function checkExecFunction() {
        if (!function_exists('exec')) {
            exit("exec function is not allowed\n");
        }
    }

    /**
     * 执行命令
     * @param string $module_controller_action tools/controller/action
     */
    protected function execCmd($module_controller_action) {
        //命令行
        $cmd = sprintf('cd %s/../../ && php -f public/index.php %s', __DIR__, $module_controller_action);
        //执行
        exec($cmd);
    }

    /**
     * 清缓存，用于升级
     */
    protected function clearCache() {
        //文件缓存
        $cmd = sprintf('rm %s -rf', CACHE_PATH);
        //执行
        exec($cmd);
        $type = config('cache.type');
        $type = strtolower($type);
        //如果是redis缓存，再删除redis缓存
        if ($type == 'redis') {
            //redis缓存
            $redis_host = config('redis.host');
            if (empty($redis_host)) {
                $redis_host = '127.0.0.1';
            }
            $redis_port = config('redis.port');
            if (empty($redis_port)) {
                $redis_port = 6379;
            }
            $redis = new \think\cache\driver\Redis([
                'host' => $redis_host,
                'post' => $redis_port
            ]);
            $redis->clear();
        }
    }

}
