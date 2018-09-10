<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class TaskAddRemark20180910143601 extends Cmd {

    public function up() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if ($this->table($table)->hasColumn('remark')) {
                continue;
            }
            //新增字段名
            $this->table($table)
                ->addColumn('remark', 'text', ['after' => 'end_time', 'limit' => MysqlAdapter::TEXT_REGULAR, 'comment' =>
                    ClMigrateField::instance()
                        ->fetch('备注')
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
            if ($this->table($table)->hasColumn('remark')) {
                //删除字段
                $this->table($table)->removeColumn('remark');
            }
        }
    }

}
