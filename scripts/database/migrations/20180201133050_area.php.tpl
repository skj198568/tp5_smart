<?php

use Phinx\Migration\AbstractMigration;
use ClassLibrary\ClMigrateTable;
use ClassLibrary\ClMigrateField;

class Area extends \think\migration\Migrator {

    public function up() {
        $table = 'area';
        if ($this->hasTable($table)) {
            return true;
        }
        $this->table($table)
            ->setComment(ClMigrateTable::instance()->createApi([
                ClMigrateTable::V_CREATE_API_GET
            ])->usingCache(3600)->fetch('地址信息'))
            ->addColumn('name', 'string', ['default' => '', 'comment' =>
                ClMigrateField::instance()
                    ->verifyIsRequire()
                    ->verifyChinese()
                    ->fetch('名称')
            ])
            ->addColumn('f_id', 'integer', ['default' => 0, 'comment' =>
                ClMigrateField::instance()
                    ->verifyIsRequire()
                    ->verifyNumber()
                    ->fetch('父类id')
            ])
            ->addColumn('type', 'integer', ['default' => 0, 'comment' =>
                ClMigrateField::instance()
                    ->verifyIsRequire()
                    ->verifyNumber()
                    ->verifyInArray([1, 2, 3])
                    ->constValues([['province', 1, '省/直辖市'], ['city', 2, '城市'], ['area', 3, '区县']])
                    ->fetch('类型，1/省、直辖市，2/城市，3/区县')
            ])
            ->addIndex(['f_id'], ['unique' => false, 'name' => 'index_f_id'])
            ->addIndex(['type'], ['unique' => false, 'name' => 'index_type'])
            ->create();
        //去掉id自增
        $this->table($table)->changeColumn('id', 'integer')->save();
    }

    public function down() {
        parent::down();
        $table = 'area';
        if ($this->hasTable($table)) {
            $this->dropTable($table);
        }
    }
}
