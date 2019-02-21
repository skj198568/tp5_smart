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
$this->table($table)->rename('{$new_table_name}')->update();
}

public function down() {
$table = '{$new_table_name}';
if (!$this->hasTable($table)) {
return;
}
$this->table($table)->rename('{$table_name}')->update();
}
}
