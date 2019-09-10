
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
        $new_table = '{$new_table_name}';
        if ($this->hasTable($new_table)) {
            return;
        }
        $this->table($table)->rename($new_table)->update();
    }

    public function down() {
        $table = '{$new_table_name}';
        if (!$this->hasTable($table)) {
            return;
        }
        $old_table = '{$table_name}';
        if ($this->hasTable($old_table)) {
            return;
        }
        $this->table($table)->rename($old_table)->update();
    }
}
