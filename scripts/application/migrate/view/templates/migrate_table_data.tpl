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
        //释放数据表信息，防止表结构修改导致的错误
        {$model_name}::tableInfoFree();
        //设置状态
        {$model_name}::$is_back_data = true;
        //清空
        {$model_name}::instance()->execute('TRUNCATE TABLE `' . config('database.prefix') . '{$table_name}`');
        //db存储文件
        $db_file    = DOCUMENT_ROOT_PATH.'{$db_file}';
        $f_handle   = fopen($db_file, 'r');
        $max_length = 1024 * 1024;
        $items      = [];
        while (!feof($f_handle)) {
            $line_content = fgets($f_handle);
            $line_content = json_decode($line_content, true);
            if (!is_array($line_content) || empty($line_content)) {
                continue;
            }
            $items[]      = $line_content;
            if (strlen(json_encode($items)) > $max_length) {
                //删除最后一个
                array_pop($items);
                //批量插入
                {$model_name}::instance()->insertAll($items);
                $items = [$line_content];
            }
        }
        if(!empty($items)){
            //批量插入
            {$model_name}::instance()->insertAll($items);
        }
        fclose($f_handle);
        //恢复状态
        {$model_name}::$is_back_data = false;
    }

}
