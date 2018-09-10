<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class TaskStartTimeUpdate20180910143536 extends Cmd {

    public function up() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if (!$this->table($table)->hasColumn('start_time')) {
                continue;
            }
            //修改字段
            $this->table($table)
                ->changeColumn('start_time', 'integer', ['default' => 0, 'comment' =>
                    ClMigrateField::instance()
                        ->showFormat("date('Y-m-d H:i:s', %s)", '_show')
                        ->verifyNumber()
                        ->fetch('开始时间')
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
            //修改字段
            $this->table($table)
                ->changeColumn('start_time', 'integer', ['default' => 0, 'comment' =>
                    ClMigrateField::instance()
                        ->verifyNumber()
                        ->fetch('更新时间')
                ])
                ->update();
        }
    }

}
