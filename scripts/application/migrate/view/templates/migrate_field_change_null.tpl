
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
            $up_fields = [<foreach name="up_fields" item="v"><php>echo "\n        ";</php>'{$v['field']}' => "{$v['default_value']}"<if condition="$key neq end($up_fields)">,</if></foreach><php>echo "\n    ";</php>];
            foreach ($up_fields as $each_field => $default_value) {
                if ($this->table($table)->hasColumn($each_field)) {
                    //先设置已存在数据的默认值
                    $sql = sprintf("UPDATE `" . $table_name_for_replace . "` SET `%s`=%s WHERE `%s` IS NULL", $each_field, $default_value, $each_field);
                    $this->execute($sql);
                    //修改表定义
                    $sql = sprintf("ALTER TABLE `" . $table_name_for_replace . "`ALTER COLUMN `%s` SET DEFAULT %s;", $each_field, $default_value);
                    $this->execute($sql);
                }
            }
        }
        //清除缓存
        cache('{$cache_key}', null);
    }

    public function down() {

    }

}
