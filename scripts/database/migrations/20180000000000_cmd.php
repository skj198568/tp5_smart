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
}
