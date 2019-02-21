

class {$class_name} extends Cmd {

    public function up() {
        $table = '{$table_name}';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if ($this->table($table)->hasIndex({$fields})) {
                $this->table($table)->removeIndex({$fields});
            }
        }
    }

    public function down() {
        $table = '{$table_name}';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if ($this->table($table)->hasIndex({$fields})) {
                continue;
            }
            $this->table($table)
                ->addIndex({$fields}, ['type' => \Phinx\Db\Table\Index::{$index_type}, 'unique' => false, 'name' => '{$index_name}'])
                ->update();
        }
    }
    
}
