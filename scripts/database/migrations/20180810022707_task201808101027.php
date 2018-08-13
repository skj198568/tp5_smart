<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class Task201808101027 extends Cmd {

    public function up() {
        $table = 'task';
        if ($this->hasTable($table)) {
            return;
        }
        $this->table($table)
            ->setEngine('InnoDB')
            ->setComment(
                ClMigrateTable::instance()
                    ->usingCache(null)
                    ->createApi([])
                    ->fetch('后台任务')
            )
            ->addColumn('command', 'string', ['default' => '', 'comment' =>
                ClMigrateField::instance()
                    ->verifyIsRequire()
                    ->fetch('带有命名空间的任务调用地址')
            ])
            ->addColumn('create_time', 'integer', ['default' => 0, 'comment' =>
                ClMigrateField::instance()
                    ->showFormat("date('Y-m-d H:i:s', %s)", '_show')
                    ->verifyNumber()
                    ->fetch('创建时间')
            ])
            ->addColumn('update_time', 'integer', ['default' => 0, 'comment' =>
                ClMigrateField::instance()
                    ->showFormat("date('Y-m-d H:i:s', %s)", '_show')
                    ->verifyNumber()
                    ->fetch('更新时间')
            ])
            ->create();
    }

    public function down() {
        $table = 'task';
        if ($this->hasTable($table)) {
            $this->dropTable($table);
        }
    }
}
