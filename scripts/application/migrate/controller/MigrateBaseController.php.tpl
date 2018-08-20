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
use think\facade\App;
use think\Controller;
use think\db\Query;

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
     * 初始化函数
     */
    public function initialize() {
        //局域网或debug模式可访问
        if (!(ClVerify::isLocalIp() || App::isDebug())) {
            echo('<h1 style="text-align: center;font-size: 5em;">404</h1>');
            exit;
        }
        if (App::isDebug()) {
            log_info('$_REQUEST:', request()->request());
        }
        parent::initialize();
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
    }

    /**
     * 空请求
     * @return string
     */
    public function _empty() {
        $file = request()->module() . DIRECTORY_SEPARATOR . 'view' . DIRECTORY_SEPARATOR . request()->controller() . DIRECTORY_SEPARATOR . request()->action() . '.html';
        $file = ClString::toArray($file);
        foreach ($file as $k_char => $char) {
            if (ClVerify::isAlphaCapital($char)) {
                $file[$k_char] = '_' . $char;
            }
        }
        $file = implode('', $file);
        $file = str_replace([DIRECTORY_SEPARATOR . '_'], [DIRECTORY_SEPARATOR], $file);
        $file = strtolower($file);
        if (is_file(APP_PATH . $file)) {
            return $this->fetch(APP_PATH . $file);
        } else {
            if (ClVerify::isLocalIp() || App::isDebug()) {
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
            'status' => $status,
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
        $class_name = $class_name . date('YmdHi');
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
            $field_info['field_type']          = 'integer';
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
        return $this->fetch($this->getTemplateFilePath('migrate_field.tpl'), [], ['default_filter' => '']) . "\n";
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
     * @param $table_name
     */
    protected function run($table_name) {
        $cmd = sprintf("cd %s && php think migrate:run", DOCUMENT_ROOT_PATH . '/../');
        //执行
        exec($cmd);
        //清除缓存
        $key = $this->getKey($table_name);
        cache($key, null);
    }

}