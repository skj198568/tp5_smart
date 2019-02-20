<?php

use think\migration\Migrator;
use think\migration\db\Column;

class TaskAddIndexCommand extends Migrator {

    public function up() {
        $table = 'task';
        if (!$this->hasTable($table)) {
            return;
        }
        if ($this->table($table)->hasIndex(['command'])) {
            return;
        }
        //判断是否可以添加索引
        $can_add_index = true;
        foreach (['start_time'] as $each_field) {
            if (!$this->table($table)->hasColumn($each_field)) {
                $can_add_index = false;
            }
        }
        if (!$can_add_index) {
            return;
        }
        $this->table($table)
            ->addIndex(['command'], ['type' => \Phinx\Db\Table\Index::INDEX, 'unique' => false, 'name' => 'index_command'])
            ->update();
    }

    public function down() {
        $table = 'task';
        if (!$this->hasTable($table)) {
            return;
        }
        if ($this->table($table)->hasIndex(['command'])) {
            return $this->table($table)->removeIndex(['command']);
        }
    }

}
