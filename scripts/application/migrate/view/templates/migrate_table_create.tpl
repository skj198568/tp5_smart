
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
            if ($this->hasTable($table)) {
                return;
            }
            $this->table($table)
                ->setEngine('{$engine}')
                ->setComment(
                    ClMigrateTable::instance()
                        ->usingCache({$cache_seconds})
                        ->createApi({:json_encode($api_functions)})
                        ->fetch('{$table_desc}')
                )
                {$fields_str}
                ->create();
        }
    }

    public function down() {
        $table = '{$table_name}';
        if ($this->hasTable($table)) {
            $this->dropTable($table);
        }
    }
}
