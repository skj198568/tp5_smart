<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2018/4/13
 * Time: 18:04
 */

namespace app\migrate\controller;

use ClassLibrary\ClArray;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClString;
use ClassLibrary\ClVerify;
use think\db\Query;

/**
 * 字段
 * Class FieldController
 * @package app\migrate\controller
 */
class FieldController extends MigrateBaseController {

    /**
     * 创建字段，如果存在，则替换
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function create() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        get_param('field_desc', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段注释');
        $fields = ClArray::getByKeys(input(), [
            'field_name',
            'field_desc',
            'field_default_value',
            'field_type',
            'field_scale',
            'is_sortable',
            'is_searchable',
            'visible',
            'is_read_only',
            'const_values',
            'show_map_fields',
            'show_format',
            'store_format',
            'verifies'
        ]);
        //缓存
        $key = $this->getKey([$table_name]);
        //获取
        $table_fields = cache($key);
        if (empty($table_fields)) {
            $table_fields = [];
        }
        $has_field = false;
        foreach ($table_fields as $k => $v) {
            if ($v['field_name'] == $field_name) {
                //编辑
                $has_field        = true;
                $table_fields[$k] = $fields;
            }
        }
        if (!$has_field) {
            //新增
            $table_fields[] = $fields;
        }
        //缓存
        cache($key, $table_fields, 3600 * 24);
        return $this->ar(1, ['items' => $table_fields]);
    }

    /**
     * 获取字段列表
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function getList() {
        $table_name   = get_param('table_name', ClFieldVerify::instance()->fetchVerifies(), '表名', '');
        $table_fields = [];
        if (!empty($table_name)) {
            //缓存
            $key = $this->getKey([$table_name]);
            //获取
            $table_fields = cache($key);
            $table_fields = [];
            if (empty($table_fields)) {
                $table_fields = [];
                if ($this->tableIsExist($table_name)) {
                    //尝试从数据库获取
                    $fields = $this->getAllFields($table_name);
                    foreach ($fields as $each_field) {
                        if ($each_field['Field'] == 'id') {
                            continue;
                        }
                        //字段名
                        $cache_filed = [
                            'field_name'          => $each_field['Field'],
                            'field_default_value' => $each_field['Default']
                        ];
                        //类型
                        if (strpos($each_field['Type'], 'decimal') !== false) {
                            $cache_filed['field_type'] = 'decimal';
                            $field_detail              = '';
                            if (strpos($each_field['Type'], '(') !== false) {
                                $field_detail = ClString::getBetween($each_field['Type'], '(', ')', false);
                            }
                            $field_detail               = explode(',', $field_detail);
                            $cache_filed['field_scale'] = $field_detail[1];
                        } else if (strpos($each_field['Type'], 'bigint') !== false) {
                            $cache_filed['field_type'] = 'int_big';
                        } else if (strpos($each_field['Type'], 'tinyint') !== false) {
                            $cache_filed['field_type'] = 'int_tiny';
                        } else if (strpos($each_field['Type'], 'smallint') !== false) {
                            $cache_filed['field_type'] = 'int_small';
                        } else if (strpos($each_field['Type'], 'int') !== false) {
                            $cache_filed['field_type'] = 'int';
                        } else if (strpos($each_field['Type'], 'longtext') !== false) {
                            $cache_filed['field_type'] = 'text_long';
                        } else if (strpos($each_field['Type'], 'text') !== false) {
                            $cache_filed['field_type'] = 'text';
                        } else if (strpos($each_field['Type'], 'varchar') !== false) {
                            $cache_filed['field_type'] = 'string';
                        }
                        if (ClVerify::isJson($each_field['Comment'])) {
                            $comment = json_decode($each_field['Comment'], true);
                            //字段描述
                            $cache_filed['field_desc'] = $comment['name'];
                            unset($comment['name']);
                            $cache_filed = array_merge($cache_filed, $comment);
                        } else {
                            $cache_filed['field_desc'] = $each_field['Comment'];
                        }
                        //json_encode
                        if (isset($cache_filed['show_map_fields'])) {
                            $cache_filed['show_map_fields'] = json_encode($cache_filed['show_map_fields'], JSON_UNESCAPED_UNICODE);
                        }
                        if (isset($cache_filed['show_format'])) {
                            $cache_filed['show_format'] = json_encode($cache_filed['show_format'], JSON_UNESCAPED_UNICODE);
                        }
                        $table_fields[] = $cache_filed;
                    }
                }
                //记录缓存
                cache($key, $table_fields, 3600 * 24);
            }
        }
        $return = [
            'limit'  => 1000,
            'offset' => 0,
            'total'  => count($table_fields),
            'items'  => $table_fields
        ];
        return $this->ar(1, $return);
    }

    /**
     * 字段删除
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function delete() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('field_name', $field_name);
        $class_name       = $this->getClassName([$table_name, 'delete', $field_name]);
        $key              = $this->getKey([$table_name]);
        $fields           = cache($key);
        $field_change_str = '';
        foreach ($fields as $k => $each_field) {
            if ($each_field['field_name'] == $field_name) {
                $last_field = '';
                if (isset($fields[$k - 1])) {
                    $last_field = $fields[$k - 1]['field_name'];
                }
                $field_change_str = $this->getFieldExecute('addColumn', $each_field, $last_field);
                unset($fields[$k]);
                break;
            }
        }
        //设置执行修改命令
        $this->assign('field_change_str', $field_change_str);
        $file    = $this->getMigrateFilePath($class_name);
        $content = $this->fetch($this->getTemplateFilePath('migrate_field_delete.tpl'));
        //写入文件
        file_put_contents($file, "<?php\n" . $content);
        //执行
        $this->run($table_name);
        return $this->ar(1, ['file_name' => $this->getMigrateFileName($class_name)]);
    }

    /**
     * 创建表的过程中删除字段
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function deleteForCreateTable() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $key        = $this->getKey([$table_name]);
        $fields     = cache($key);
        foreach ($fields as $k => $each_field) {
            if ($each_field['field_name'] == $field_name) {
                unset($fields[$k]);
                break;
            }
        }
        $fields = array_values($fields);
        //写入缓存
        cache($key, $fields, 3600 * 24);
        return $this->ar(1, ['message' => '删除成功']);
    }

    /**
     * 移动位置
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function move() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $type       = get_param('type', ClFieldVerify::instance()->verifyInArray(['up', 'down'])->verifyIsRequire()->fetchVerifies(), '类型');
        //缓存
        $key = $this->getKey([$table_name]);
        //获取
        $table_fields = cache($key);
        foreach ($table_fields as $k => $v) {
            if ($v['field_name'] == $field_name) {
                //设置顺序
                if ($type == 'up') {
                    $temp                 = $table_fields[$k - 1];
                    $table_fields[$k - 1] = $v;
                    $table_fields[$k]     = $temp;
                } else {
                    $temp                 = $table_fields[$k + 1];
                    $table_fields[$k + 1] = $v;
                    $table_fields[$k]     = $temp;
                }
            }
        }
        $table_fields = array_values($table_fields);
        //缓存
        cache($key, $table_fields, 3600 * 24);
        return $this->ar(1);
    }

    /**
     * 字段重命名
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function rename() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $old_name = get_param('old_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('old_name', $old_name);
        $new_name = get_param('new_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('new_name', $new_name);
        $class_name       = $this->getClassName([$table_name, 'rename', $old_name, 'to', $new_name]);
        $key              = $this->getKey($table_name);
        $fields           = cache($key);
        $field_change_str = '';
        foreach ($fields as $k => $each_field) {
            if ($each_field['field_name'] == $old_name) {
                $field_change_str         = $this->getFieldExecute('changeColumn', $each_field);
                $each_field['field_name'] = $new_name;
                $fields[$k]               = $each_field;
                break;
            }
        }
        //设置执行修改命令
        $this->assign('field_change_str', $field_change_str);
        $file    = $this->getMigrateFilePath($class_name);
        $content = $this->fetch($this->getTemplateFilePath('migrate_field_rename.tpl'));
        //写入文件
        file_put_contents($file, "<?php\n" . $content);
        //执行
        $this->run($table_name);
        return $this->ar(1, ['file_name' => $this->getMigrateFileName($class_name)]);
    }

    /**
     * 获取所有字段
     * @param $table_name
     * @return mixed
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    private function getAllFields($table_name) {
        $query = new Query();
        return $query->query('SHOW FULL FIELDS FROM `' . $this->getTableNameWithPrefix($table_name) . '`');
    }

    /**
     * 移动位置
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function changePosition() {
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('field_name', $field_name);
        $after_field_name = get_param('after_field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $table_name       = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $key            = $this->getKey($table_name);
        $fields         = cache($key);
        $fields_str     = '';
        $old_fields_str = '';
        foreach ($fields as $k => $each) {
            if ($each['field_name'] == $field_name) {
                $fields_str = $this->getFieldExecute('changeColumn', $each, $after_field_name);
                if ($k == 0) {
                    $old_after_field = 'id';
                } else {
                    $old_after_field = $fields[$k - 1]['field_name'];
                }
                $old_fields_str = $this->getFieldExecute('changeColumn', $each, $old_after_field);
            }
        }
        $this->assign('field_str', $fields_str);
        $this->assign('old_field_str', $old_fields_str);
        //写入文件
        $class_name    = $this->getClassName([$table_name, $field_name, 'change_position']);
        $file_path     = $this->getMigrateFilePath($class_name);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_field_change_position.tpl'));
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name);
        return $this->ar(1, ['file_name' => $this->getMigrateFileName($class_name)]);
    }

    /**
     * 更新
     */
    public function update() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('field_name', $field_name);
        get_param('field_desc', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段注释');
        $fields       = ClArray::getByKeys(input(), [
            'field_name',
            'field_desc',
            'field_default_value',
            'field_type',
            'field_scale',
            'is_sortable',
            'is_searchable',
            'visible',
            'is_read_only',
            'const_values',
            'show_map_fields',
            'show_format',
            'store_format',
            'verifies'
        ]);
        $key          = $this->getKey($table_name);
        $table_fields = cache($key);
        $old_fields   = [];
        foreach ($table_fields as $each_field) {
            if ($each_field['field_name'] == $field_name) {
                $old_fields = $each_field;
                break;
            }
        }
        $field_str = $this->getFieldExecute('changeColumn', $fields);
        $this->assign('field_str', $field_str);
        $old_field_str = $this->getFieldExecute('changeColumn', $old_fields);
        $this->assign('old_field_str', $old_field_str);
        //写入文件
        $class_name    = $this->getClassName([$table_name, $field_name, 'update']);
        $file_path     = $this->getMigrateFilePath($class_name);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_field_update.tpl'));
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name);
        return $this->ar(1, ['file_name' => $this->getMigrateFileName($class_name)]);
    }

    /**
     * 真实新增字段
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function createForExistTable() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('field_name', $field_name);
        $after_field = get_param('after_field', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '前一个字段');
        get_param('field_desc', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段注释');
        $fields    = ClArray::getByKeys(input(), [
            'field_name',
            'field_desc',
            'field_default_value',
            'field_type',
            'field_scale',
            'is_sortable',
            'is_searchable',
            'visible',
            'is_read_only',
            'const_values',
            'show_map_fields',
            'show_format',
            'store_format',
            'verifies'
        ]);
        $field_str = $this->getFieldExecute('addColumn', $fields, $after_field);
        $this->assign('field_str', $field_str);
        //写入文件
        $class_name    = $this->getClassName([$table_name, 'add', $field_name]);
        $file_path     = $this->getMigrateFilePath($class_name);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_field_add.tpl'));
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name);
        return $this->ar(1, ['file_name' => $this->getMigrateFileName($class_name)]);
    }

}