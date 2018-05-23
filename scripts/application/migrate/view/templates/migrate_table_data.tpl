use think\migration\Migrator;
use think\migration\db\Column;

class {$class_name} extends Cmd {

    public function up() {
        //设置大小
        $this->execute('set global max_allowed_packet = 1024*1024*1024*1024');
        //清空
        $this->execute('TRUNCATE TABLE `{$table_name}`');
        //插入数据
        $this->execute('INSERT INTO `{$table_name}`
(`{:implode('`, `', $fields)}`)
VALUES
<foreach name="items" item="info" key="k">
(\'{:implode("\\', \\'", $info)}\')<if condition="$k != count($items)-1">,
</if>
</foreach>

');
    }
}
