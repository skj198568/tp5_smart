<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2018/4/10
 * Time: 13:40
 */

namespace app\migrate\controller;

use ClassLibrary\ClArray;
use ClassLibrary\ClCrypt;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClString;
use ClassLibrary\ClVerify;
use Phinx\Util\Util;
use think\App;
use think\Controller;
use think\db\Query;
use think\Exception;

/**
 * 基础类
 * Class MigrateBaseController
 * @package app\migrate\controller
 */
class MigrateBaseController extends Controller {

    /**
     * 账号
     * @var string
     */
    protected $account = '';

    /**
     * 不校验的请求
     * @var array
     */
    protected $uncheck_request = [
        'User/login'
    ];

    /**
     * 查询对象实例
     * @var Query
     */
    var $query_instance = null;

    /**
     * 初始化函数
     */
    public function _initialize() {
        //局域网或debug模式可访问
        if (!(ClVerify::isLocalIp() || App::$debug)) {
            echo('<h1 style="text-align: center;font-size: 5em;">404</h1>');
            exit;
        }
        if (App::$debug) {
            log_info('$_REQUEST:', request()->request());
        }
        parent::_initialize();
        $token = '';
        if (!ClArray::inArrayIgnoreCase(request()->controller() . '/' . request()->action(), $this->uncheck_request)) {
            $token = get_param('token', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '校验token', '');
        }
        if (!empty($token)) {
            $this->account = ClCrypt::decrypt($token, CRYPT_KEY);
            if (empty($this->account)) {
                if (ClVerify::isLocalIp(request()->ip())) {
                    //本机请求
                    $this->account = $token;
                } else {
                    $msg = json_encode([
                        'status'  => -1,
                        'message' => '无效token'
                    ], JSON_UNESCAPED_UNICODE);
                    if (request()->isAjax()) {
                        //输出结果并退出
                        header('Content-Type:application/json; charset=utf-8');
                        echo($msg);
                    } else {
                        echo($msg . PHP_EOL);
                    }
                    exit;
                }
            }
        }
        $this->assign('controller_name', request()->controller());
        $this->assign('action_name', request()->action());
        $this->setMenu();
        $this->query_instance = new Query();
    }

    /**
     * 空请求
     * @return string
     */
    public function _empty() {
        $file = request()->module() . DS . 'view' . DS . request()->controller() . DS . request()->action() . '.html';
        $file = ClString::toArray($file);
        foreach ($file as $k_char => $char) {
            if (ClVerify::isAlphaCapital($char)) {
                $file[$k_char] = '_' . $char;
            }
        }
        $file = implode('', $file);
        $file = str_replace([DS . '_'], [DS], $file);
        $file = strtolower($file);
        if (is_file(APP_PATH . $file)) {
            return $this->fetch(APP_PATH . $file);
        } else {
            if (ClVerify::isLocalIp() || App::$debug) {
                log_info(request()->controller(), request()->action());
                echo sprintf("the file '<span style=\"color: red;\">%s</span>' is not exist", $file);
                exit;
            } else {
                return '<h1 style="text-align: center;font-size: 5em;">404</h1>';
            }
        }
    }

    /**
     * 返回信息
     * @param int $code 返回码
     * @param array $data 返回的值
     * @param string $example 例子，用于自动生成api文档
     * @param bool $is_log
     * @return \think\response\Json|\think\response\Jsonp
     */
    protected function ar($code, $data = [], $example = '', $is_log = false) {
        $status = sprintf('%s/%s/%s/%s', request()->module(), request()->controller(), request()->action(), $code);
        //格式化
        $status = ClString::toArray($status);
        foreach ($status as $k_status => $v_status) {
            if (ClVerify::isAlphaCapital($v_status)) {
                $status[$k_status] = '_' . strtolower($v_status);
            }
        }
        //转换为字符串
        $status = implode('', $status);
        $status = str_replace('/_', '/', $status);
        $data   = is_array($data) ? $data : [$data];
        return json_return(array_merge([
            'status'      => $status,
            'status_code' => $code
        ], $data), $is_log);
    }

    /**
     * 设置菜单
     */
    protected function setMenu() {
        $default_page = '/migrate/tables/index.html';
        $this->assign('default_page', $default_page);
        $menu = [
            [
                'icon'  => '<i class="fa fa-table"></i>',
                'name'  => '首页',
                'url'   => $default_page,
                'items' => []
            ],
//            [
//                'icon'  => '<i class="fa fa-table"></i>',
//                'name'  => '资料',
//                'url'   => '',
//                'items' => [
//                    [
//                        'name'     => '商品管理',
//                        'url'      => url('Provider/Goods/index'),
//                        'right_id' => 12,
//                    ],
//                    [
//                        'name'     => '人员管理',
//                        'url'      => url('Provider/User/index'),
//                        'right_id' => 11,
//                    ]
//                ]
//            ]
        ];
        $this->assign('menu', $menu);
    }

    /**
     * 空内容的返回
     * @return array
     */
    protected function pagingGetEmptyReturn() {
        return [
            'limit'  => PAGES_NUM,
            'offset' => 0,
            'total'  => 0,
            'items'  => []
        ];
    }

    /**
     * 获取key
     * @param array $key
     * @return string
     */
    protected function getKey($key) {
        $pre = 'migrate';
        if (!is_array($key)) {
            $key = [$key];
        }
        array_unshift($key, $pre);
        return implode('_', $key);
    }

    /**
     * Model名
     * @param $table_name
     * @param bool $with_model
     * @return string
     */
    protected function getModelName($table_name, $with_model = true) {
        if (strpos($table_name, '_')) {
            $table_name_array = explode('_', $table_name);
            $table_name       = '';
            foreach ($table_name_array as $v) {
                $table_name .= ucfirst($v);
            }
            return $table_name . ($with_model ? 'Model' : '');
        } else {
            return ucfirst($table_name) . ($with_model ? 'Model' : '');
        }
    }

    /**
     * 获取表名
     * @param array $table_name table_name or array
     * @return string
     */
    protected function getClassName($table_name) {
        if (is_string($table_name)) {
            $table_name = [$table_name];
        }
        $class_name = implode('_', $table_name);
        $class_name = $this->getModelName($class_name, false);
        $class_name = $class_name . date('YmdHis');
        //赋值
        $this->assign('class_name', $class_name);
        return $class_name;
    }

    /**
     * 获取文件名
     * @param $class_name
     * @return string
     */
    protected function getMigrateFileName($class_name) {
        return Util::mapClassNameToFileName($class_name);
    }

    /**
     * 获取文件路径
     * @param $class_name
     * @return string
     */
    protected function getMigrateFilePath($class_name) {
        return DOCUMENT_ROOT_PATH . '/../database/migrations/' . $this->getMigrateFileName($class_name);
    }

    /**
     * 获取模板文件路径
     * @param $template_file_name
     * @return string
     */
    protected function getTemplateFilePath($template_file_name) {
        return APP_PATH . '/migrate/view/templates/' . $template_file_name;
    }

    /**
     * 获取字段执行
     * @param $field_deal_type
     * @param $field_info
     * @param string $after_field
     * @return string
     */
    protected function getFieldExecute($field_deal_type, $field_info, $after_field = '') {
        $this->assign('field_deal_type', $field_deal_type);
        if (!empty($after_field)) {
            $after_field = "'after' => '$after_field', ";
        }
        $field_info['after_field'] = $after_field;
        //处理limit
        $field_info['field_limit'] = '';
        switch ($field_info['field_type']) {
            case 'int_tiny':
                $field_info['field_limit'] = "'limit' => MysqlAdapter::INT_TINY, ";
                break;
            case 'int_small':
                $field_info['field_limit'] = "'limit' => MysqlAdapter::INT_SMALL, ";
                break;
            case 'int_big':
                $field_info['field_limit'] = "'limit' => MysqlAdapter::INT_BIG, ";
                break;
            case 'text':
                $field_info['field_limit'] = "'limit' => MysqlAdapter::TEXT_REGULAR, ";
                break;
            case 'text_long':
                $field_info['field_limit'] = "'limit' => MysqlAdapter::TEXT_LONG, ";
                break;
            case 'decimal':
                $field_info['field_limit'] = sprintf("'precision' => 11, 'scale' => %s, ", $field_info['field_scale']);
                break;
        }
        //处理字段类型
        if (in_array($field_info['field_type'], ['int', 'int_big', 'int_tiny', 'int_small'])) {
            //数字
            $field_info['field_type'] = 'integer';
            //数字类型的默认值，只能是数字
            $field_info['field_default_value'] = is_numeric($field_info['field_default_value']) ? $field_info['field_default_value'] : 0;
            $field_info['field_default_value'] = "'default' => " . $field_info['field_default_value'] . ", ";
        } else if (in_array($field_info['field_type'], ['string'])) {
            //字符串
            $field_info['field_type'] = 'string';
            if ($field_info['field_type'] == 'string') {
                if ($field_info['field_default_value'] == '空') {
                    $field_info['field_default_value'] = '';
                }
                $field_info['field_default_value'] = "'default' => '" . $field_info['field_default_value'] . "', ";
            }
        } else if ($field_info['field_type'] == 'decimal') {
            $field_info['field_default_value'] = "'default' => " . $field_info['field_default_value'] . ", ";
        } else if (in_array($field_info['field_type'], ['text', 'text_long'])) {
            $field_info['field_type']          = 'text';
            $field_info['field_default_value'] = '';
        }
        $this->assign('field_info', $field_info);
        return $this->fetch($this->getTemplateFilePath('migrate_field.tpl')) . "\n";
    }

    /**
     * 获取表注释
     * @param $table_name
     * @return array
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    protected function getTableComment($table_name) {
        $table_name    = $this->getTableNameWithPrefix($table_name);
        $query         = new Query();
        $table_comment = $query->query(sprintf("SELECT TABLE_COMMENT,ENGINE FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'", config('database.database'), $table_name));
        $return        = [
            'name'       => '',
            'is_cache'   => 'null',
            'engine'     => 'InnoDB',
            'create_api' => []
        ];
        foreach ($table_comment as $each_comment) {
            $comment = json_decode($each_comment['TABLE_COMMENT'], true);
            if (empty($comment)) {
                $return['name'] = $each_comment['TABLE_COMMENT'];
            } else {
                if (!isset($comment['is_cache'])) {
                    $comment['is_cache'] = 'null';
                }
                $comment['engine'] = $each_comment['ENGINE'];
                $return            = array_merge($return, $comment);
            }
        }
        return $return;
    }

    /**
     * 表是否存在
     * @param $table_name
     * @return bool
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    protected function tableIsExist($table_name) {
        $comment = $this->getTableComment($table_name);
        if (empty($comment['name'])) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * 获取真实表名
     * @param $table_name
     * @return string
     */
    protected function getTableNameWithPrefix($table_name) {
        return config('database.prefix') . $table_name;
    }

    /**
     * 运行
     * @param string $table_name 表名
     * @param string $migrate_absolute_file 执行文件绝对地址
     * @param string $svn_msg svn版本信息
     */
    protected function run($table_name, $migrate_absolute_file, $svn_msg) {
        $cmd = sprintf("cd %s && php think migrate:run", DOCUMENT_ROOT_PATH . '/../');
        try {
            //执行
            exec($cmd);
        } catch (Exception $exception) {
            log_info('migrate cmd error', [
                'message' => $exception->getMessage(),
                'file'    => $exception->getFile(),
                'line'    => $exception->getLine(),
                'code'    => $exception->getCode(),
                'data'    => $exception->getData()
            ]);
        }
        //清除缓存
        $key = $this->getKey($table_name);
        cache($key, null);
        //替换路径
        $migrate_absolute_file = str_replace(DOCUMENT_ROOT_PATH . '/../', '', $migrate_absolute_file);
        if (is_dir(DOCUMENT_ROOT_PATH . '/../.svn')) {
            //svn版本
            $cmd = sprintf('cd %s && svn add %s && svn ci -m "%s" %s', DOCUMENT_ROOT_PATH . '/../', $migrate_absolute_file, $svn_msg, $migrate_absolute_file);
        } else {
            $cmd = sprintf('cd %s && git add %s && git commit -m "%s" && git push', DOCUMENT_ROOT_PATH . '/../', $migrate_absolute_file, $svn_msg);
        }
        if (empty($cmd)) {
            return;
        }
        //写入shell脚本来处理版本问题
        $file = DOCUMENT_ROOT_PATH . '/../database/migrate.sh';
        if (is_file($file)) {
            $f_handle = fopen($file, 'a');
            //拼接
            fputs($f_handle, "\n" . $cmd);
            fclose($f_handle);
        } else {
            file_put_contents($file, "#!/bin/bash\n" . $cmd);
        }
    }

    /**
     * 查询
     * @param $sql
     * @return mixed
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    protected function query($sql) {
        return $this->query_instance->query($sql);
    }

    /**
     * 获取表所有的字段
     * @param $table_name
     * @return array|mixed
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    protected function getTableFields($table_name) {
        if (empty($table_name)) {
            $table_fields = [];
        } else {
            //缓存
            $key = $this->getKey([$table_name]);
            //获取
            $table_fields = cache($key);
            if (empty($table_fields)) {
                $table_fields = [];
                if ($this->tableIsExist($table_name)) {
                    //尝试从数据库获取
                    $fields = $this->getAllFields($table_name);
                    foreach ($fields as $each_field) {
                        if ($each_field['Field'] == 'id') {
                            continue;
                        }
                        //设置字段默认值
                        if (strtolower($each_field['Default']) == 'null' || is_null($each_field['Default'])) {
                            $each_field['Default'] = '';
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
        return $table_fields;
    }

    /**
     * 获取所有字段
     * @param $table_name
     * @return mixed
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    private function getAllFields($table_name) {
        return $this->query('SHOW FULL FIELDS FROM `' . $this->getTableNameWithPrefix($table_name) . '`');
    }

}