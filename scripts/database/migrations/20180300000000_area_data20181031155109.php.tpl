<?php
use think\migration\Migrator;
use think\migration\db\Column;
use app\index\model\AreaModel;

class AreaData20181031155109 extends Cmd {

    /**
     * 备份
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function up() {
        //释放数据表信息，防止表结构修改导致的错误错误
        AreaModel::tableInfoFree();
        //临时取消字段password存储格式，防止数据变动
        foreach (AreaModel::$fields_store_format as $k => $v) {
            if (is_array($v) && $v[0] == 'password') {
                unset(AreaModel::$fields_store_format[$k]);
            }
        }
        //清空
        AreaModel::instance()->execute('TRUNCATE TABLE `t_area`');
        //db存储文件
        $db_file    = DOCUMENT_ROOT_PATH.'/../database/data/20181031155109_t_area.json';
        $f_handle   = fopen($db_file, 'r');
        $max_length = 1024 * 1024;
        $items      = [];
        while (!feof($f_handle)) {
            $line_content = fgets($f_handle);
            $line_content = json_decode($line_content, true);
            $items[]      = $line_content;
            if (strlen(json_encode($items)) > $max_length) {
                //批量插入
                AreaModel::instance()->insertAll($items);
                $items = [];
            }
        }
        if(!empty($items)){
            //批量插入
            AreaModel::instance()->insertAll($items);
        }
        fclose($f_handle);
    }

}
