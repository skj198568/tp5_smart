<?php

use Phinx\Migration\AbstractMigration;
use ClassLibrary\ClMigrateTable;
use ClassLibrary\ClMigrateField;

/**
 * 创建AreaModel
 * Class AreaModel
 */
class AreaModel extends Cmd {

    public function up() {
        //命令行
        $cmd = sprintf('cd %s/../../ && php think smart_init', __DIR__);
        //执行
        exec($cmd);
    }

}
