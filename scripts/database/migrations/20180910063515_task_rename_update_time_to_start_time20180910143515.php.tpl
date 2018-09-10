<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class TaskRenameUpdateTimeToStartTime20180910143515 extends Cmd {

    public function up() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if (!$this->table($table)->hasColumn('update_time')) {
                continue;
            }
            //修改字段名
            $this->table($table)
                ->renameColumn('update_time', 'start_time')
                ->update();
            //修改注释
            $this->table($table)
                ->changeColumn('start_time', 'integer', ['default' => 0, 'comment' =>
                    ClMigrateField::instance()
                        ->verifyNumber()
                        ->fetch('更新时间')
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
            if (!$this->table($table)->hasColumn('start_time')) {
                continue;
            }
            //修改字段名
            $this->table($table)
                ->renameColumn('start_time', 'update_time')
                ->update();
            //修改注释
            $this->table($table)
                ->changeColumn('update_time', 'integer', ['default' => 0, 'comment' =>
                    ClMigrateField::instance()
                        ->verifyNumber()
                        ->fetch('更新时间')
                ])
                ->update();
        }
    }

}
