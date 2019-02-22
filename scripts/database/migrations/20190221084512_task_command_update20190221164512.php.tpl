<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class TaskCommandUpdate20190221164512 extends Cmd {

    public function up() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if (!$this->table($table)->hasColumn('command')) {
                continue;
            }
            //修改字段
            $this->table($table)
                ->changeColumn('command', 'string', ['limit' => 10000, 'default' => '', 'comment' =>
                    ClMigrateField::instance()
                        ->verifyIsRequire()
                        ->fetch('带有命名空间的任务调用地址')
                ])
                ->update();
        }
    }

    public function down() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if (!$this->table($table)->hasColumn('command')) {
                continue;
            }
            //修改字段
            $this->table($table)
                ->changeColumn('command', 'string', ['limit' => 255, 'default' => '', 'comment' =>
                    ClMigrateField::instance()
                        ->verifyIsRequire()
                        ->fetch('带有命名空间的任务调用地址')
                ])
                ->update();
        }
    }

}
