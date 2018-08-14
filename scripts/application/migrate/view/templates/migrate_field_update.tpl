
use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class {$class_name} extends Cmd {

    public function up() {
        $table = '{$table_name}';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if(!$this->table($table)->hasColumn('{$field_name}')){
                continue;
            }
            //修改字段
            $this->table($table)
                {$field_str}
                ->update();
        }
    }

    public function down() {
        $table = '{$table_name}';
        $tables = $this->getAllTables($table);
        foreach ($tables as $table) {
            if (!$this->hasTable($table)) {
                continue;
            }
            if(!$this->table($table)->hasColumn('{$field_name}')){
                continue;
            }
            //修改字段
            $this->table($table)
                {$old_field_str}
                ->update();
        }
    }

}
