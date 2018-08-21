<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2018/4/13
 * Time: 16:00
 */

namespace app\migrate\controller;

use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClString;
use think\db\Query;

/**
 * 表
 * Class TableController
 * @package app\migrate\controller
 */
class TableController extends MigrateBaseController {

    /**
     * 获取列表
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function getList() {
        $query         = new Query();
        $tables_select = $query->query("SHOW TABLES");
        $tables        = [];
        foreach ($tables_select as $k => $table) {
            $table = array_pop($table);
            if (!empty(config('database.prefix')) && strpos($table, config('database.prefix')) === 0) {
                $table = substr($table, strlen(config('database.prefix')));
            }
            if ($table == 'migrations') {
                continue;
            }
            $comment = $this->getTableComment($table);
            $comment = json_encode($comment);
            if (!isset($tables[$comment]) || (isset($tables[$comment]) && strlen($table) < strlen($tables[$comment]['name']))) {
                $tables[$comment] = [
                    'name' => $table
                ];
            }
        }
        $tables = array_values($tables);
        $return = [
            'limit'  => 1000,
            'offset' => 0,
            'total'  => count($tables),
            'items'  => $tables
        ];
        return $this->ar(1, $return);
    }

    /**
     * 创建表migrate
     * @param string $type
     * @return string
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    private function createTableMigrate($type = 'create') {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        if ($type == 'create') {
            $class_name = $this->getClassName([$table_name]);
        } else {
            $class_name = $this->getClassName([$table_name, 'delete']);
        }
        $table_comment = $this->getTableComment($table_name);
        if ($type == 'create') {
            $table_desc = get_param('table_desc', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表注释');
        } else {
            $table_desc = $table_comment['name'];
        }
        $this->assign('table_desc', $table_desc);
        if ($type == 'create') {
            $cache_seconds = get_param('cache_seconds', ClFieldVerify::instance()->fetchVerifies(), '缓存时间', null);
        } else {
            $cache_seconds = $table_comment['is_cache'];
        }
        $this->assign('cache_seconds', $cache_seconds);
        //引擎
        if ($type == 'create') {
            $engine = get_param('engine', ClFieldVerify::instance()->verifyInArray(['MyISAM', 'InnoDB'])->fetchVerifies(), '表引擎');
        } else {
            $engine = $table_comment['engine'];
        }
        $this->assign('engine', $engine);
        if ($type == 'create') {
            $api_functions = get_param('api_functions', ClFieldVerify::instance()->verifyArray()->fetchVerifies(), '创建的接口函数', []);
        } else {
            $api_functions = $table_comment['create_api'];
        }
        $this->assign('api_functions', $api_functions);
        $key       = $this->getKey([$table_name]);
        $fields    = cache($key);
        $query     = new Query();
        $old_table = $query->query("SHOW TABLES LIKE '%$table_name'");
        $file_path = $this->getMigrateFilePath($class_name);
        if (empty($old_table)) {
            //create
            $table_is_exist = false;
        } else {
            //update
            $table_is_exist = true;
        }
        $fields_str = '';
        foreach ($fields as $each) {
            $fields_str .= $this->getFieldExecute('addColumn', $each);
        }
        $this->assign('fields_str', $fields_str);
        $this->assign('table_is_exist', $table_is_exist);
        $tpl_file_name = ($type == 'create') ? 'migrate_table_create.tpl' : 'migrate_table_delete.tpl';
        $table_content = $this->fetch($this->getTemplateFilePath($tpl_file_name));
        //写入文件
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name);
        return $this->getMigrateFileName($class_name);
    }

    /**
     * 创建
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function create() {
        return $this->ar(1, ['file_name' => $this->createTableMigrate()]);
    }

    /**
     * 单个信息
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function get() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $info       = $this->getTableComment($table_name);
        return $this->ar(1, ['info' => $info]);
    }

    /**
     * 删除
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function delete() {
        return $this->ar(1, ['file_name' => $this->createTableMigrate('delete')]);
    }

    /**
     * 表更新
     * @return string
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function update() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $table_desc = get_param('table_desc', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表注释');
        $this->assign('table_desc', $table_desc);
        $engine = get_param('engine', ClFieldVerify::instance()->verifyInArray(['MyISAM', 'InnoDB'])->fetchVerifies(), '表引擎');
        $this->assign('engine', $engine);
        $api_functions = get_param('api_functions', ClFieldVerify::instance()->verifyArray()->fetchVerifies(), '创建的接口函数', []);
        $this->assign('api_functions', $api_functions);
        $cache_seconds = get_param('cache_seconds', ClFieldVerify::instance()->fetchVerifies(), '缓存时间', null);
        $this->assign('cache_seconds', $cache_seconds);
        $old_table_comment = $this->getTableComment($table_name);
        $this->assign('old_table_desc', $old_table_comment['name']);
        $this->assign('old_engine', $old_table_comment['engine']);
        $this->assign('old_api_functions', $old_table_comment['create_api']);
        $this->assign('old_cache_seconds', $old_table_comment['is_cache']);
        //分表信息
        $partition = get_param('partition', ClFieldVerify::instance()->verifyArray()->fetchVerifies(), '分表规则', []);
        $this->assign('partition', $partition);
        $this->assign('old_partition', isset($old_table_comment['partition']) ? $old_table_comment['partition'] : []);
        $class_name    = $this->getClassName([$table_name, 'update']);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_table_update.tpl'));
        $file_path     = $this->getMigrateFilePath($class_name);
        //写入文件
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name);
        return $this->ar(1, ['file' => $this->getMigrateFileName($class_name)]);
    }

    /**
     * 重命名
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function rename() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $new_table_name = get_param('new_table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '新表名');
        $this->assign('new_table_name', $new_table_name);
        $class_name    = $this->getClassName([$table_name, 'rename']);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_table_rename.tpl'));
        $file_path     = $this->getMigrateFilePath($class_name);
        //写入文件
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name);
        return $this->ar(1, ['file' => $this->getMigrateFileName($class_name)]);
    }

    /**
     * 备份数据
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function backUpData() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('model_name', $this->getModelName($table_name));
        $class_name = $this->getClassName([$table_name, 'data']);
        $table_name = $this->getTableNameWithPrefix($table_name);
        $this->assign('table_name_with_prefix', $table_name);
        $query = new Query();
        $query->setTable($table_name);
        $all_count = $query->count();
        if (empty($all_count)) {
            return $this->ar(2, ['message' => '数据为空，不可备份']);
        }
        $limit    = 100;
        $all_page = ceil($all_count / $limit);
        $db_file  = '/../database/data/' . $table_name . date('YmdHi') . '.json';
        $this->assign('db_file', $db_file);
        $db_file = DOCUMENT_ROOT_PATH . $db_file;
        ClFile::dirCreate($db_file);
        $db_handle = fopen($db_file, 'w+');
        $is_write  = false;
        for ($page = 1; $page <= $all_page; $page++) {
            $items = $query->page($page)->limit($limit)->select();
            foreach ($items as $each_item) {
                fputs($db_handle, ($is_write ? "\n" : '') . json_encode($each_item, JSON_UNESCAPED_UNICODE));
                $is_write = true;
            }
        }
        fclose($db_handle);
        $this->assign('all_items', []);
        $this->assign('class_name', $class_name);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_table_data.tpl'));
        $file_path     = $this->getMigrateFilePath($class_name);
        //写入文件
        file_put_contents($file_path, "<?php\n" . $table_content);
        return $this->ar(1, ['file' => $this->getMigrateFileName($class_name)]);
    }

}