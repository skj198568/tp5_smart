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
        //等待1秒，防止表结构修改，mysql还未执行完毕
        sleep(1);
        //清空
        {$model_name}::instance()->execute('TRUNCATE TABLE `{$table_name_with_prefix}`');
        //db存储文件
        $db_file    = DOCUMENT_ROOT_PATH.'{$db_file}';
        $f_handle   = fopen($db_file, 'r');
        $max_length = 1024 * 1024;
        $items      = [];
        while (!feof($f_handle)) {
            $line_content = fgets($f_handle);
            $line_content = json_decode($line_content, true);
            $items[]      = $line_content;
            if (strlen(json_encode($items)) > $max_length) {
                //批量插入
                {$model_name}::instance()->insertAll($items);
                $items = [];
            }
        }
        if(!empty($items)){
            //批量插入
            {$model_name}::instance()->insertAll($items);
        }
        fclose($f_handle);
    }

}
