class {$class_name} extends Cmd {

public function up() {
$table = '{$table_name}';
$tables = $this->getAllTables($table);
foreach ($tables as $table) {
if (!$this->hasTable($table)) {
continue;
}
if ($this->table($table)->hasIndex({$fields})) {
continue;
}
//判断是否可以添加索引
$can_add_index = true;
foreach({$fields} as $each_field){
if(!$this->table($table)->hasColumn($each_field)){
$can_add_index = false;
}
}
if(!$can_add_index){
return;
}
$this->table($table)
->addIndex({$fields}, ['type' => \Phinx\Db\Table\Index::{$index_type}, 'unique' => false, 'name' => '{$index_name}'])
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
if ($this->table($table)->hasIndex({$fields})) {
$this->table($table)->removeIndex({$fields});
}
}
}
}
