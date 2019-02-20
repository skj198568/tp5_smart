<?php

use think\migration\Migrator;
use think\migration\db\Column;

class TaskAddIndexStartTime extends Migrator {

    public function up() {
        $table = 'task';
        if (!$this->hasTable($table)) {
            return;
        }
        if ($this->table($table)->hasIndex(['start_time'])) {
            return;
        }
        //判断是否可以添加索引
        $can_add_index = true;
        foreach(['start_time'] as $each_field){
            if(!$this->table($table)->hasColumn($each_field)){
                $can_add_index = false;
            }
        }
        if(!$can_add_index){
            return;
        }
        $this->table($table)
            ->addIndex(['start_time'], ['type' => \Phinx\Db\Table\Index::INDEX, 'unique' => false, 'name' => 'index_start_time'])
            ->update();
    }

    public function down() {
        $table = 'task';
        if (!$this->hasTable($table)) {
            return;
        }
        if ($this->table($table)->hasIndex(['start_time'])) {
            return $this->table($table)->removeIndex(['start_time']);
        }
    }
}
