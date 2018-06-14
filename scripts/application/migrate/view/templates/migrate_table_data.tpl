use think\migration\Migrator;
use think\migration\db\Column;
use app\index\model\{$model_name};

class {$class_name} extends Cmd {

    /**
     * 备份
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function up() {
        //清空
        {$model_name}::instance()->execute('TRUNCATE TABLE `{$table_name_with_prefix}`');
<foreach name="all_items" item="items" key="k_all">
        //插入数据 {:count($items)} 条
        {$model_name}::instance()->insertAll(json_decode(stripslashes('{:addslashes(json_encode($items, JSON_UNESCAPED_UNICODE))}'), true));
</foreach>
    }

}
