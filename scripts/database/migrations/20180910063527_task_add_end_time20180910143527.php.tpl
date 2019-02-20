<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class TaskAddEndTime20180910143527 extends Cmd {

    public function up() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if ($this->table($table)->hasColumn('end_time')) {
                continue;
            }
            if ($this->table($table)->hasColumn('start_time')) {
                //新增字段名
                $this->table($table)
                    ->addColumn('end_time', 'integer', ['after' => 'start_time', 'default' => 0, 'comment' =>
                        ClMigrateField::instance()
                            ->showFormat("date('Y-m-d H:i:s', %s)", '_show')
                            ->verifyNumber()
                            ->fetch('结束时间')
                    ])
                    ->update();
            } else {
//新增字段名
                $this->table($table)
                    ->addColumn('end_time', 'integer', ['default' => 0, 'comment' =>
                        ClMigrateField::instance()
                            ->showFormat("date('Y-m-d H:i:s', %s)", '_show')
                            ->verifyNumber()
                            ->fetch('结束时间')
                    ])
                    ->update();
            }
        }
    }

    public function down() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if ($this->table($table)->hasColumn('end_time')) {
                //删除字段
                $this->table($table)->removeColumn('end_time');
            }
        }
    }

}
