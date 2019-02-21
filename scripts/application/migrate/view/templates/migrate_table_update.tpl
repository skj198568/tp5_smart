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
$sql = ClMigrateTable::instance()
->usingCache({$cache_seconds})
->createApi({:is_array($api_functions) ? json_encode($api_functions) : $api_functions})
->partition({:is_array($partition) ? json_encode($partition) : $partition})
->getUpdateCommentSql($table, '{$table_desc}', '{$engine}');
$this->execute($sql);
}
}

public function down() {
$table = '{$table_name}';
$tables = $this->getAllTables($table);
foreach ($tables as $table) {
if (!$this->hasTable($table)) {
continue;
}
$sql = ClMigrateTable::instance()
->usingCache({$old_cache_seconds})
->createApi({:is_array($old_api_functions) ? json_encode($old_api_functions) : $old_api_functions})
->partition({:is_array($old_partition) ? json_encode($old_partition) : $old_partition})
->getUpdateCommentSql($table, '{$old_table_desc}', '{$old_engine}');
$this->execute($sql);
}
}
}
