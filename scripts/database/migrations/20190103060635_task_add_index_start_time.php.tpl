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
