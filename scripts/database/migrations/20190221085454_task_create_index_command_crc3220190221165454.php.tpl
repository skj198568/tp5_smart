<?php


class TaskCreateIndexCommandCrc3220190221165454 extends Cmd {

    public function up() {
        $table  = 'task';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if ($this->table($table)->hasIndex(["command_crc32"])) {
                continue;
            }
            //判断是否可以添加索引
            $can_add_index = true;
            foreach (["command_crc32"] as $each_field) {
                if (!$this->table($table)->hasColumn($each_field)) {
                    $can_add_index = false;
                }
            }
            if (!$can_add_index) {
                return;
            }
            $this->table($table)
                ->addIndex(["command_crc32"], ['type' => \Phinx\Db\Table\Index::INDEX, 'unique' => false, 'name' => 'IndexCommandCrc32'])
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
            if ($this->table($table)->hasIndex(["command_crc32"])) {
                $this->table($table)->removeIndex(["command_crc32"]);
            }
        }
    }
}
