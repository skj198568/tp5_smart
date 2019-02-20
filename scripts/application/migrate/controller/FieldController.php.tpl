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
        $table_fields = $this->getTableFields($table_name);
        $return       = [
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
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function delete() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('field_name', $field_name);
        $class_name                        = $this->getClassName([$table_name, 'delete', $field_name]);
        $fields                            = $this->getTableFields($table_name);
        $field_change_str                  = '';
        $field_change_str_with_after_field = '';
        foreach ($fields as $k => $each_field) {
            if ($each_field['field_name'] == $field_name) {
                $last_field = '';
                if (isset($fields[$k - 1])) {
                    $last_field = $fields[$k - 1]['field_name'];
                }
                $this->assign('after_field', $last_field);
                $field_change_str                  = $this->getFieldExecute('addColumn', $each_field);
                $field_change_str_with_after_field = $this->getFieldExecute('addColumn', $each_field, $last_field);
                unset($fields[$k]);
                break;
            }
        }
        //设置执行修改命令
        $this->assign('field_change_str', $field_change_str);
        $this->assign('field_change_str_with_after_field', $field_change_str_with_after_field);
        $file    = $this->getMigrateFilePath($class_name);
        $content = $this->fetch($this->getTemplateFilePath('migrate_field_delete.tpl'));
        //写入文件
        file_put_contents($file, "<?php\n" . $content);
        //执行
        $this->run($table_name, $file, sprintf('%s delete field %s', $table_name, $field_name));
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
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function rename() {
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $old_name = get_param('old_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('old_name', $old_name);
        $new_name = get_param('new_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('new_name', $new_name);
        $class_name       = $this->getClassName([$table_name, 'rename', $old_name, 'to', $new_name]);
        $fields           = $this->getTableFields($table_name);
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
        $this->run($table_name, $file, sprintf('%s rename field %s to %s', $table_name, $old_name, $new_name));
        return $this->ar(1, ['file_name' => $this->getMigrateFileName($class_name)]);
    }

    /**
     * 移动位置
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function changePosition() {
        $field_name = get_param('field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('field_name', $field_name);
        $after_field_name = get_param('after_field_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段名');
        $this->assign('after_field', $after_field_name);
        $table_name = get_param('table_name', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '表名');
        $this->assign('table_name', $table_name);
        $fields                          = $this->getTableFields($table_name);
        $fields_str                      = '';
        $fields_str_with_after_field     = '';
        $old_fields_str                  = '';
        $old_fields_str_with_after_field = '';
        foreach ($fields as $k => $each) {
            if ($each['field_name'] == $field_name) {
                $fields_str                  = $this->getFieldExecute('changeColumn', $each);
                $fields_str_with_after_field = $this->getFieldExecute('changeColumn', $each, $after_field_name);
                if ($k == 0) {
                    $old_after_field = 'id';
                } else {
                    $old_after_field = $fields[$k - 1]['field_name'];
                }
                $this->assign('old_after_field', $old_after_field);
                $old_fields_str                  = $this->getFieldExecute('changeColumn', $each);
                $old_fields_str_with_after_field = $this->getFieldExecute('changeColumn', $each, $old_after_field);
            }
        }
        $this->assign('field_str', $fields_str);
        $this->assign('fields_str_with_after_field', $fields_str_with_after_field);
        $this->assign('old_field_str', $old_fields_str);
        $this->assign('old_field_str_with_after_field', $old_fields_str_with_after_field);
        //写入文件
        $class_name    = $this->getClassName([$table_name, $field_name, 'change_position']);
        $file_path     = $this->getMigrateFilePath($class_name);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_field_change_position.tpl'));
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name, $file_path, sprintf('%s change field position %s', $table_name, $field_name));
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
        $table_fields = $this->getTableFields($table_name);
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
        $this->run($table_name, $file_path, sprintf('%s update field %s', $table_name, $field_name));
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
        $this->assign('after_field', $after_field);
        get_param('field_desc', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '字段注释');
        $fields                     = ClArray::getByKeys(input(), [
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
        $field_str_with_after_field = $this->getFieldExecute('addColumn', $fields, $after_field);
        $this->assign('field_str_with_after_field', $field_str_with_after_field);
        $field_str = $this->getFieldExecute('addColumn', $fields);
        $this->assign('field_str', $field_str);
        //写入文件
        $class_name    = $this->getClassName([$table_name, 'add', $field_name]);
        $file_path     = $this->getMigrateFilePath($class_name);
        $table_content = $this->fetch($this->getTemplateFilePath('migrate_field_add.tpl'));
        file_put_contents($file_path, "<?php\n" . $table_content);
        //执行
        $this->run($table_name, $file_path, sprintf('%s add field %s', $table_name, $field_name));
        return $this->ar(1, ['file_name' => $this->getMigrateFileName($class_name)]);
    }

}