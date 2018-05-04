
use think\migration\Migrator;
use think\migration\db\Column;
use Phinx\Db\Adapter\MysqlAdapter;
use ClassLibrary\ClMigrateField;
use ClassLibrary\ClMigrateTable;

class {$class_name} extends Cmd {

    public function up() {
        $table = '{$table_name}';
        if (!$this->hasTable($table)) {
            return;
        }
        if(!$this->table($table)->hasColumn('{$field_name}')){
            return;
        }
        //修改字段名
        $this->table($table)
            {$field_str}
            ->update();
    }

    public function down() {
        $table = '{$table_name}';
        if (!$this->hasTable($table)) {
            return;
        }
        if(!$this->table($table)->hasColumn('{$field_name}')){
            return;
        }
        //修改字段名
        $this->table($table)
            {$old_field_str}
            ->update();
    }

}