
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
            $table_name_for_replace = config('database.prefix').$table;
            $up_sql = [<foreach name="up_sql" item="v"><php>echo "\n        ";</php>'{$key}' => "{$v}"<if condition="$key neq end($up_sql)">,</if></foreach><php>echo "\n    ";</php>];
            foreach($up_sql as $each_field => $each_sql){
                if ($this->table($table)->hasColumn($each_field)) {
                    $this->execute($each_sql);
                }
            }
        }
    }

    public function down() {

    }

}
