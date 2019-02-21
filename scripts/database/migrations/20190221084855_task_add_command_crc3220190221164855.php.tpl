<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class TaskAddCommandCrc3220190221164855 extends Cmd {

    public function up() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if ($this->table($table)->hasColumn('command_crc32')) {
                continue;
            }
            //新增字段名
            if ($this->table($table)->hasColumn('command')) {
                $this->table($table)
                    ->addColumn('command_crc32', 'integer', [
                        'after'   => 'command',
                        'limit'   => 20,
                        'default' => 0,
                        'comment' => ClMigrateField::instance()
                            ->verifyNumber()
                            ->fetch('命令行crc32方式存储，用于索引')
                    ])
                    ->update();
            } else {
                $this->table($table)
                    ->addColumn('command_crc32', 'integer', ['limit' => 20, 'default' => 0, 'comment' =>
                        ClMigrateField::instance()
                            ->verifyNumber()
                            ->fetch('命令行crc32方式存储，用于索引')
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
            if ($this->table($table)->hasColumn('command_crc32')) {
                //删除字段
                $this->table($table)->removeColumn('command_crc32');
            }
        }
    }

}
