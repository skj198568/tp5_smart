
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
        if(!$this->table($table)->hasColumn('{$old_name}')){
            return;
        }
        //修改字段名
        $this->table($table)
            ->renameColumn('{$old_name}', '{$new_name}')
            ->update();
        //修改注释
        $this->table($table)
            {:str_replace($old_name, $new_name, $field_change_str)}
            ->update();
    }

    public function down() {
        $table = '{$table_name}';
        if (!$this->hasTable($table)) {
            return;
        }
        if(!$this->table($table)->hasColumn('{$new_name}')){
            return;
        }
        //修改字段名
        $this->table($table)
            ->renameColumn('{$new_name}', '{$old_name}')
            ->update();
        //修改注释
        $this->table($table)
            {$field_change_str}
            ->update();
    }

}
