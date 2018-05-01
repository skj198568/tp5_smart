
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
        $sql = ClMigrateTable::instance()
            ->usingCache({$cache_seconds})
            ->createApi({:is_array($api_functions) ? json_encode($api_functions) : $api_functions})
            ->getUpdateCommentSql('{$table_name}', '{$table_desc}', '{$engine}');
        $this->execute($sql);
    }

    public function down() {
        $table = '{$table_name}';
        if (!$this->hasTable($table)) {
            return;
        }
        $sql = ClMigrateTable::instance()
            ->usingCache({$old_cache_seconds})
            ->createApi({:is_array($old_api_functions) ? json_encode($old_api_functions) : $old_api_functions})
            ->getUpdateCommentSql('{$table_name}', '{$old_table_desc}', '{$old_engine}');
        $this->execute($sql);
    }
}
