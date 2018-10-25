<?php

/**
 * Cmd基础类
 * Class Cmd
 */
class Cmd extends \think\migration\Migrator {

    /**
     * 初始化
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function init() {
        parent::init();
        //校验
        $this->checkExecFunction();
        //获取当前链接数
        if (!is_numeric(cache('migrate_max_connections'))) {
            $query           = new \think\db\Query();
            $max_connections = $query->query("show variables like '%max_connections%';");
            cache('migrate_max_connections', $max_connections[0]['Value']);
            //设置最大连接数
            $query->query('set GLOBAL max_connections = 16384;');
        }
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

    /**
     * 获取所有的表名
     * @param $table_name_without_prefix
     * @return array
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    protected function getAllTables($table_name_without_prefix) {
        $table_comment = $this->getTableComment($this->getTableNameWithPrefix($table_name_without_prefix));
        $database      = config('database.database');
        $query         = new \think\db\Query();
        $result        = $query->query("select table_name from information_schema.TABLES where TABLE_SCHEMA='$database'");
        $tables        = [];
        foreach ($result as $each) {
            if ($this->getTableComment($each['table_name']) == $table_comment) {
                $tables[] = $this->getTableNameWithoutPrefix($each['table_name']);
            }
        }
        return $tables;
    }

    /**
     * 获取表注释
     * @param $table_name_with_prefix
     * @return string
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    protected function getTableComment($table_name_with_prefix) {
        $query         = new \think\db\Query();
        $table_comment = $query->query(sprintf("SELECT TABLE_COMMENT,ENGINE FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'", config('database.database'), $table_name_with_prefix));
        $comment       = '';
        if (!empty($table_comment)) {
            $comment = $table_comment[0]['TABLE_COMMENT'];
        }
        return $comment;
    }

    /**
     * 获取带前缀的表名
     * @param $table_name
     * @return string
     */
    protected function getTableNameWithPrefix($table_name) {
        return config('database.prefix') . $table_name;
    }

    /**
     * 获取不带前缀的表名
     * @param $table_name
     * @return mixed
     */
    protected function getTableNameWithoutPrefix($table_name) {
        return \ClassLibrary\ClString::replaceOnce(config('database.prefix'), '', $table_name);
    }

    /**
     * 析构函数
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function __destruct() {
        if (is_numeric(cache('migrate_max_connections')) && cache('migrate_max_connections') > 0) {
            //恢复原最大链接数
            $query = new \think\db\Query();
            $query->query(sprintf('set GLOBAL max_connections = %s;', cache('migrate_max_connections')));
            cache('migrate_max_connections', null);
        }
    }

}
