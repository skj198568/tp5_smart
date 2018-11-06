<?php

use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class UrlShort20181106170828 extends Cmd {

    public function up() {
        $table = 'url_short';
        if ($this->hasTable($table)) {
            return;
        }
        $this->table($table)
            ->setEngine('InnoDB')
            ->setComment(
                ClMigrateTable::instance()
                    ->usingCache(600)
                    ->createApi(["create", "get"])
                    ->fetch('短网址')
            )
            ->addColumn('short_url', 'string', ['default' => '', 'comment' =>
                ClMigrateField::instance()
                    ->fetch('短连接')
            ])
            ->addColumn('true_url', 'string', ['default' => '', 'comment' =>
                ClMigrateField::instance()
                    ->fetch('真实url')
            ])
            ->addColumn('create_time', 'integer', ['default' => 0, 'comment' =>
                ClMigrateField::instance()
                    ->showFormat("date('Y-m-d H:i:s', %s)", '_show')
                    ->verifyNumber()
                    ->fetch('创建时间')
            ])
            ->addIndex(['short_url'], ['unique' => false, 'name' => 'index_short_url'])
            ->create();
    }

    public function down() {
        $table = 'url_short';
        if ($this->hasTable($table)) {
            $this->dropTable($table);
        }
    }
}
