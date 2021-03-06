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
        //设置状态
        AreaModel::instance()->setMoveDataBegin();
        //清空
        AreaModel::instance()->execute('TRUNCATE TABLE `' . config('database.prefix') . 'area`');
        //db存储文件
        $db_file    = DOCUMENT_ROOT_PATH . '/../database/data/20181031155109_area.json';
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
        if (!empty($items)) {
            //批量插入
            AreaModel::instance()->insertAll($items);
        }
        fclose($f_handle);
        //回复状态
        AreaModel::instance()->setMoveDataEnd();
    }

}
