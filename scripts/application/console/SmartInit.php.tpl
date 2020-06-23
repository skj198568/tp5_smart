<?php
/**
 * Created by PhpStorm.
 * User: skj19
 * Date: 2017/2/21
 * Time: 17:33
 */

namespace app\console;


use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClMysql;
use ClassLibrary\ClString;
use ClassLibrary\ClSystem;
use ClassLibrary\ClVerify;
use think\Config;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;
use think\Exception;
use think\View;

/**
 * 依据数据库表创建Model
 * Class ModelInit
 * @package app\console
 */
class SmartInit extends Command {

    /**
     * @var \think\View 视图类实例
     */
    protected $view;

    /**
     * 待处理文件
     * @var array
     */
    protected $undo_files = [];

    protected function configure() {
        $this->setName('smart_init')
            ->addOption('--table_name', '-t', Option::VALUE_REQUIRED, '不带前缀的数据库表名，例如：user_goods，如果参数为空则创建所有表')
            ->setDescription('依据数据库表自动创建Model模型、ApiController接口');
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool|int|null
     */
    protected function execute(Input $input, Output $output) {
        try {
            return $this->doExecute($input, $output);
        } catch (Exception $exception) {
            echo_info([
                'message' => $exception->getMessage(),
                'file'    => $exception->getFile(),
                'line'    => $exception->getLine(),
                'code'    => $exception->getCode(),
                'data'    => $exception->getData()
            ]);
        }
        return true;
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool
     * @throws Exception
     */
    private function doExecute(Input $input, Output $output) {
        //设置view
        $this->view = View::instance(Config::get('template'), Config::get('view_replace_str'));
        //设置Mysql
        ClMysql::init(config('database.hostname'), config('database.hostport'), config('database.username'), config('database.password'), config('database.database'));
        //分割
        $output->highlight('');
        //定义换行
        $this->view->assign('wrap_str', "\n");
        //初始化Model
        $this->initModel($input, $output);
        //分割
        $output->question('');
        //初始化ApiController
        $this->initController($input, $output);
        //分割
        $output->highlight('');
        //处理文件版本
        $this->dealFilesVersion($output);
        //处理migrate
        $this->dealMigrate($output);
        //处理api doc
        $this->dealApiDoc($output);
        //修改目录权限为www
        if (!ClSystem::isWin()) {
            $cmd = sprintf('cd %s && chown www:www * -R', DOCUMENT_ROOT_PATH . '/../');
            exec($cmd);
        }
        $output->highlight('finished');
        return true;
    }

    /**
     * 初始化Model
     * @param Input $input
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    protected function initModel(Input $input, Output $output) {
        $table_name = $input->getOption('table_name');
        if (empty($table_name)) {
            //创建所有的
            $table_names = $this->getAllTables();
        } else {
            $table_names = [$table_name];
        }
        foreach ($table_names as $table_name) {
            //处理map
            $this->dealModelMap($table_name, $output);
            //处理model
            $this->dealModel($table_name, $output);
        }
        return true;
    }

    /**
     * 获取真实表名
     * @param $table_name
     * @return string
     */
    private function getTableNameWithPrefix($table_name) {
        return config('database.prefix') . $table_name;
    }

    /**
     * 表名格式化
     * @param $table_name
     * @return string
     */
    private function tableNameFormat($table_name) {
        if (strpos($table_name, '_')) {
            $table_name_array = explode('_', $table_name);
            $table_name       = '';
            foreach ($table_name_array as $v) {
                $table_name .= ucfirst($v);
            }
            return $table_name;
        } else {
            return ucfirst($table_name);
        }
    }

    /**
     * 获取表注释
     * @param $table_name
     * @return mixed
     */
    public function getTableComment($table_name) {
        $table_name    = $this->getTableNameWithPrefix($table_name);
        $table_comment = ClMysql::query(sprintf("SELECT TABLE_COMMENT FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'", config('database.database'), $table_name));
        $return        = [
            'name'     => '',
            'ignore'   => 0,
            'is_cache' => 'null'
        ];
        foreach ($table_comment as $each_comment) {
            $comment = json_decode($each_comment['TABLE_COMMENT'], true);
            if (empty($comment)) {
                $return['name'] = $each_comment['TABLE_COMMENT'];
            } else {
                if (!isset($comment['is_cache']) || is_null($comment['is_cache'])) {
                    $comment['is_cache'] = 'null';
                }
                $return = array_merge($return, $comment);
            }
        }
        return $return;
    }

    /**
     * 处理model map
     * @param $table_name
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    private function dealModelMap($table_name, Output $output) {
        $table_info = ClMysql::query('SHOW FULL FIELDS FROM `' . $this->getTableNameWithPrefix($table_name) . '`');
        if (empty($table_info)) {
            $output->highlight(sprintf('table name:%s is not exist.', $table_name));
            return false;
        }
        $map_template_file = __DIR__ . '/smart_init_templates/model_map.tpl';
        //所有字段
        $all_fields   = [];
        $const_fields = '';
        //额外展示字段
        $fields_show_map_fields = [];
        //字段格式化
        $fields_show_format = [];
        //字段存储格式
        $fields_store_format = [];
        //只读字段
        $fields_read_only = [];
        //不可见字段
        $fields_invisible = [];
        //校验器
        $fields_verifies = [];
        //字段注释关系
        $fields_names = [];
        //默认值
        $fields_default_values = [];
        //拼接域名
        $fields_append_domain = [];
        foreach ($table_info as $k => $each) {
            $all_fields[] = 'self::F_' . strtoupper($each['Field']);
            if ($each['Field'] == 'id') {
                continue;
            }
            $field_comment = json_decode($each['Comment'], true);
            if (empty($field_comment)) {
                $field_comment = ['name' => $each['Comment']];
            }
            $fields_names['self::F_' . strtoupper($each['Field'])] = $field_comment['name'];
            $const_fields                                          .= sprintf("
    /**
     * %s
     * Type: %s
     * Default: %s
     */
    const F_%s = '%s';
", $field_comment['name'], $each['Type'], $each['Default'] === '' ? "''" : $each['Default'], strtoupper($each['Field']), $each['Field']);
            //处理静态参数
            if (isset($field_comment['const_values']) && !empty($field_comment['const_values'])) {
                //处理格式化参数
                if (!isset($field_comment['show_format']) || empty($field_comment['show_format'])) {
                    $field_comment['show_format'] = [];
                }
                $format = [];
                foreach ($field_comment['const_values'] as $const_value_array) {
                    $format[] = [$const_value_array[1], $const_value_array[2]];
                }
                //新增格式化字段
                $field_comment['show_format'][] = [$format, '_show'];
                //处理静态变量
                if (isset($field_comment['const_values'])) {
                    $map_relation = '';
                    foreach ($field_comment['const_values'] as $const_value_array) {
                        $const_fields .= sprintf("
    /**
     * %s
     */
    const V_%s_%s = %s;
", $const_value_array[2], strtoupper($each['Field']), strtoupper($const_value_array[0]), $const_value_array[1]);
                        $map_relation .= (empty($map_relation) ? '' : ",\n        ") . sprintf($const_value_array[1] . " => '%s'", $const_value_array[2]);
                    }
                    //处理字段关系映射
                    foreach ($field_comment['const_values'] as $const_value_array) {
                    }
                    $const_fields .= sprintf("
    /**
     * 字段配置
     */
    const C_%s = [
        %s
    ];\n", strtoupper($each['Field']), $map_relation);
                }
            }
            //设置校验器，默认有长度限制
            if (isset($field_comment['verifies'])) {
                $has_verify_length_max = false;
                foreach ($field_comment['verifies'] as $each_verify) {
                    if ($each_verify[0] == 'length_max') {
                        $has_verify_length_max = true;
                        break;
                    }
                }
                if (!$has_verify_length_max) {
                    $max_length = ClString::getBetween($each['Type'], '(', ')', false);
                    if (is_numeric($max_length) && $max_length > 0) {
                        $field_comment['verifies'] = array_merge($field_comment['verifies'], ClFieldVerify::instance()->verifyStringLengthMax($max_length)->fetchVerifies());
                    }
                }
            } else {
                $max_length = ClString::getBetween($each['Type'], '(', ')', false);
                if (is_numeric($max_length) && $max_length > 0) {
                    $field_comment['verifies'] = ClFieldVerify::instance()->verifyStringLengthMax($max_length)->fetchVerifies();
                }
            }
            if (isset($field_comment['verifies'])) {
                $fields_verifies['self::F_' . strtoupper($each['Field'])] = $field_comment['verifies'];
            }
            //设置只读字段
            if (isset($field_comment['is_read_only'])) {
                $fields_read_only[] = 'self::F_' . strtoupper($each['Field']);
            }
            //设置不可见字段
            if (isset($field_comment['visible']) && $field_comment['visible'] == 0) {
                $fields_invisible[] = 'self::F_' . strtoupper($each['Field']);
            }
            //设置额外显示字段
            if (isset($field_comment['show_map_fields'])) {
                $fields_show_map_fields['self::F_' . strtoupper($each['Field'])] = json_encode($field_comment['show_map_fields'], JSON_UNESCAPED_UNICODE);
            }
            //设置字段格式化
            if (isset($field_comment['show_format'])) {
                $fields_show_format['self::F_' . strtoupper($each['Field'])] = json_encode($field_comment['show_format'], JSON_UNESCAPED_UNICODE);
            }
            //设置字段存储格式
            if (isset($field_comment['store_format'])) {
                $fields_store_format['self::F_' . strtoupper($each['Field'])] = json_encode($field_comment['store_format'], JSON_UNESCAPED_UNICODE);
            }
            //设置默认值
            if (in_array(strtolower($each['Type']), ['text', 'mediumtext', 'longtext'])) {
                $fields_default_values['self::F_' . strtoupper($each['Field'])] = '';
            }
            //拼接域名
            if (isset($field_comment['append_domain'])) {
                $fields_append_domain[] = 'self::F_' . strtoupper($each['Field']);
            }
        }
        //校验器
        $fields_verifies_string = '';
        //拼接校验器
        foreach ($fields_verifies as $field => $verify_array) {
            $fields_verifies_string .= sprintf('
        %s => %s, ', $field, json_encode($verify_array, JSON_UNESCAPED_UNICODE));
        }
        $use_file    = __DIR__ . '/smart_init_templates/model_map_extra/' . $table_name . '_use.tpl';
        $use_content = "\n";
        if (is_file($use_file)) {
            $use_content = "\n" . file_get_contents($use_file) . "\n";
        }
        $functions_file    = __DIR__ . '/smart_init_templates/model_map_extra/' . $table_name . '_functions.tpl';
        $functions_content = '';
        if (is_file($functions_file)) {
            $functions_content = "\n" . file_get_contents($functions_file) . "\n";
        }
        $cache_remove_trigger_file    = __DIR__ . '/smart_init_templates/model_map_extra/' . $table_name . '_cache_remove_trigger.tpl';
        $cache_remove_trigger_content = "\n";
        if (is_file($cache_remove_trigger_file)) {
            $cache_remove_trigger_content = "\n" . file_get_contents($cache_remove_trigger_file) . "\n";
        }
        $trigger_before_insert_file    = __DIR__ . '/smart_init_templates/model_map_extra/' . $table_name . '_trigger_before_insert.tpl';
        $before_insert_trigger_content = '';
        if (is_file($trigger_before_insert_file)) {
            $before_insert_trigger_content = file_get_contents($trigger_before_insert_file) . "\n";
        }
        $content     = "<?php\n" . $this->view->fetch($map_template_file, [
                'date'                          => date('Y/m/d') . "\n",
                'time'                          => date('H:i:s') . "\n",
                'table_comment'                 => $this->getTableComment($table_name),
                'table_name'                    => $table_name,
                'table_name_with_format'        => $this->tableNameFormat($table_name),
                'table_name_with_prefix'        => $this->getTableNameWithPrefix($table_name),
                'const_fields'                  => $const_fields,
                'fields_verifies'               => empty($fields_verifies_string) ? '' : trim($fields_verifies_string, ',') . "\n    ",
                'fields_read_only'              => empty($fields_read_only) ? '' : implode(', ', $fields_read_only),
                'all_fields_str'                => implode(', ', $all_fields),
                'fields_show_map_fields'        => $fields_show_map_fields,
                'fields_show_map_fields_keys'   => array_keys($fields_show_map_fields),
                'fields_show_format'            => $fields_show_format,
                'fields_show_format_keys'       => array_keys($fields_show_format),
                'fields_store_format'           => $fields_store_format,
                'fields_store_format_keys'      => array_keys($fields_store_format),
                'fields_invisible'              => empty($fields_invisible) ? '' : implode(', ', $fields_invisible),
                'fields_names'                  => $fields_names,
                'fields_names_keys'             => array_keys($fields_names),
                'fields_default_values'         => $fields_default_values,
                'fields_default_values_keys'    => array_keys($fields_default_values),
                'fields_append_domain'          => empty($fields_append_domain) ? '' : implode(', ', $fields_append_domain),
                'use_content'                   => $use_content,
                'functions_content'             => $functions_content,
                'cache_remove_trigger_content'  => $cache_remove_trigger_content,
                'before_insert_trigger_content' => $before_insert_trigger_content,
            ]);
        $map_file    = APP_PATH . 'index/map/' . $this->tableNameFormat($table_name) . 'Map.php';
        $old_content = '';
        if (is_file($map_file)) {
            $old_content = file_get_contents($map_file);
        } else {
            //创建文件夹
            ClFile::dirCreate($map_file);
        }
        //写入
        file_put_contents($map_file, $content);
        if ($content != $old_content) {
            if (empty($old_content)) {
                $output->highlight('[Map]:create ' . $map_file . " ok");
                $this->undo_files[] = [
                    'file' => $map_file,
                    'type' => 'create'
                ];
            } else {
                $output->info('[Map]:modify ' . $map_file . " ok");
                $this->undo_files[] = [
                    'file' => $map_file,
                    'type' => 'update'
                ];
            }
        }
        return true;
    }

    /**
     * 处理model
     * @param $table_name
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    private function dealModel($table_name, Output $output) {
        $model_name_file = APP_PATH . 'index/model/' . $this->tableNameFormat($table_name) . 'Model.php';
        if (is_file($model_name_file)) {
            //仅更改Model名称
            $model_content = file_get_contents($model_name_file);
            $class_desc    = ClString::getBetween($model_content, '/**', ' extends ', false);
            $class_desc    = explode("\n", $class_desc);
            //第一行即Model注释
            $desc          = $class_desc[0];
            $table_comment = $this->getTableComment($table_name);
            if ($table_comment['name'] != ClString::getBetween($desc, '*', '', false)) {
                $new_model_desc = '* ' . $table_comment['name'];
                //替换Model name
                $model_content = str_replace($desc, $new_model_desc, $model_content);
                //写入文件
                file_put_contents($model_name_file, $model_content);
                //输出
                $output->info('[Model]:modify model name ' . $model_name_file);
                $this->undo_files[] = [
                    'file' => $model_name_file,
                    'type' => 'update'
                ];
            }
            return false;
        }
        $template_file         = __DIR__ . '/smart_init_templates/model.tpl';
        $table_comment         = $this->getTableComment($table_name);
        $table_comment['name'] .= "\n";
        $content               = "<?php\n" . $this->view->fetch($template_file, [
                'date'          => date('Y/m/d') . "\n",
                'time'          => date('H:i:s') . "\n",
                'table_name'    => $this->tableNameFormat($table_name),
                'table_comment' => $table_comment
            ]);
        if (!empty($content)) {
            //写入
            file_put_contents($model_name_file, $content);
            $output->highlight('[Model]:create ' . $model_name_file . " ok");
            $this->undo_files[] = [
                'file' => $model_name_file,
                'type' => 'create'
            ];
        }
        return true;
    }

    /**
     * 获取所有的表格
     * @return array
     */
    private function getAllTables() {
        $database_prefix = config('database.prefix');
        $tables          = ClMysql::query("SHOW TABLES LIKE '" . $database_prefix . "%'");
        $table_names     = [];
        foreach ($tables as $k => $table_name) {
            $table_name = array_pop($table_name);
            if (!empty($database_prefix) && strpos($table_name, $database_prefix) !== 0) {
                continue;
            }
            $table_name = ClString::replaceOnce($database_prefix, '', $table_name);
            if ($table_name == 'migrations' || $table_name == 'phinxlog') {
                continue;
            }
            //comment
            $comment = $this->getTableComment($table_name);
            //忽略表
            if (isset($comment['ignore']) && $comment['ignore']) {
                continue;
            }
            $table_comment = json_encode($comment, JSON_UNESCAPED_UNICODE);
            if (!array_key_exists($table_comment, $table_names)) {
                $table_names[$table_comment] = $table_name;
            } else {
                if (!isset($comment['partition'])) {
                    //非分表
                    $this->output->error('table_comment:' . $table_comment . ' is exist. table_name:' . $table_name);
                }
            }
        }
        return array_values($table_names);
    }

    /**处理ApiController
     *
     * @param Input $input
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    protected function initController(Input $input, Output $output) {
        ClMysql::init(config('database.hostname'), config('database.hostport'), config('database.username'), config('database.password'), config('database.database'));
        $table_name = $input->getOption('table_name');
        if (empty($table_name)) {
            //创建所有的
            $table_names = $this->getAllTables();
        } else {
            $table_names = [$table_name];
        }
        foreach ($table_names as $table_name) {
            //处理controller map
            $this->dealControllerApiBase($table_name, $output);
            //处理controller
            $this->dealController($table_name, $output);
        }
        return true;
    }

    /**
     * 处理 controller api base
     * @param $table_name
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    private function dealControllerApiBase($table_name, Output $output) {
//        if ($table_name != 'user') {
//            return;
//        }
        //如果不创建api，则忽略
        $table_comment = $this->getTableComment($table_name);
        $table_info    = ClMysql::query('SHOW FULL FIELDS FROM `' . $this->getTableNameWithPrefix($table_name) . '`');
        if (empty($table_info)) {
            $output->highlight(sprintf('table name:%s is not exist.', $table_name));
            return false;
        }
        $table_name_format = $this->tableNameFormat($table_name);
        $info              = [];
        //字段配置
        $fields_config       = [];
        $fields_update_ready = [];
        foreach ($table_info as $k => $each) {
            if (empty($each['Comment'])) {
                $comment = [];
            } else {
                $comment = json_decode($each['Comment'], true);
                if (empty($comment)) {
                    $comment = ['name' => $comment];
                }
            }
            //添加update只读字段方法
            if (isset($comment['is_read_only'])) {
                $function_name = $each['Field'];
                if (strpos($function_name, '_') !== false) {
                    $function_name = explode('_', $function_name);
                    array_walk($function_name, function (&$each) {
                        $each = ucfirst($each);
                    });
                    $function_name = implode('', $function_name);
                } else {
                    $function_name = ucfirst($function_name);
                }
                $field_comment         = (empty($comment) ? ($each['Field'] == 'id' ? '主键id' : '未定义') : $comment['name']);
                $fields_update_ready[] = [
                    'function_desc'        => '更新字段-' . $field_comment . '（' . $each['Field'] . '）',
                    'function_name'        => $function_name,
                    'field_name'           => $each['Field'],
                    'field_name_static'    => 'F_' . strtoupper($each['Field']),
                    'json_return'          => [
                        "status"      => 'api/' . $table_name . '/updatefield' . strtolower($function_name) . "/1",
                        "status_code" => 1,
                        "info"        => []
                    ],
                    'json_return_is_exist' => json_encode([
                        "status"      => 'api/' . $table_name . '/updatefield' . strtolower($function_name) . "/2",
                        "status_code" => 2,
                        "message"     => "不可重复操作"
                    ], JSON_UNESCAPED_UNICODE),
                ];
            }
            //如果是不可见字段，则忽略
            if (isset($comment['visible']) && $comment['visible'] == 0) {
                continue;
            }
            $info[$each['Field']] = empty($comment) ? ($each['Field'] == 'id' ? '主键id' : '未定义') : $comment['name'];
            //静态变量
            $const_str = '';
            //添加get配置方法
            if (isset($comment['const_values'])) {
                $json_return = [];
                foreach ($comment['const_values'] as $each_const_value) {
                    $const_str     .= sprintf(' %s/%s;', $each_const_value[1], $each_const_value[2]);
                    $json_return[] = [
                        'value' => $each_const_value[1],
                        'text'  => $each_const_value[2],
                    ];
                }
                if (!empty($const_str)) {
                    $info[$each['Field']] .= sprintf(':%s', $const_str);
                }
                $function_name = $each['Field'];
                if (strpos($function_name, '_') !== false) {
                    $function_name = explode('_', $function_name);
                    array_walk($function_name, function (&$each) {
                        $each = ucfirst($each);
                    });
                    $function_name = implode('', $function_name);
                } else {
                    $function_name = ucfirst($function_name);
                }
                if (in_array('get', $table_comment['create_api'])) {
                    $fields_config[] = [
                        'function_desc' => empty($comment) ? ($each['Field'] == 'id' ? '主键id' : '未定义') : $comment['name'],
                        'function_name' => $function_name,
                        'field_name'    => $each['Field'],
                        'json_return'   => json_encode([
                            "status"      => 'api/' . $table_name . '/getfieldconfig' . strtolower($function_name) . "/1",
                            "status_code" => 1,
                            "items"       => $json_return
                        ], JSON_UNESCAPED_UNICODE)
                    ];
                }
            }
            //额外字段
            if (isset($comment['show_map_fields'])) {
                foreach ($comment['show_map_fields'] as $each_field) {
                    $info[$each_field[1]] = $each_field[2];
                }
            }
            //拼接格式化字段
            if (isset($comment['show_format'])) {
                foreach ($comment['show_format'] as $each_field) {
                    $info[$each['Field'] . $each_field[1]] = $comment['name'];
                }
            }
        }
        foreach ($fields_update_ready as $k_field_update => $each_field_update) {
            $each_field_update['json_return']['info'] = $info;
            //json
            $each_field_update['json_return']     = json_encode($each_field_update['json_return'], JSON_UNESCAPED_UNICODE);
            $fields_update_ready[$k_field_update] = $each_field_update;
        }
        $ar_get_list_json   = [
            'status'      => strtolower(sprintf('api/%s/getList/1', $table_name)),
            'status_code' => 1,
            'limit'       => 10,
            'offset'      => 0,
            'total'       => 10,
            'items'       => [$info]
        ];
        $ar_get_json        = [
            'status'      => strtolower(sprintf('api/%s/get/1', $table_name)),
            'status_code' => 1,
            'info'        => $info
        ];
        $ar_get_by_ids_json = [
            'status'      => strtolower(sprintf('api/%s/getByIds/1', $table_name)),
            'status_code' => 1,
            'items'       => [$info]
        ];
        $ar_create_json     = [
            'status'      => strtolower(sprintf('api/%s/create/1', $table_name)),
            'status_code' => 1,
            'info'        => $info
        ];
        $ar_update_json     = [
            'status'      => strtolower(sprintf('api/%s/update/1', $table_name)),
            'status_code' => 1,
            'info'        => $info
        ];
        $ar_update_ids_json = [
            'status'      => strtolower(sprintf('api/%s/updateByIds/1', $table_name)),
            'status_code' => 1,
            'ids'         => '主键ids'
        ];
        $ar_delete_json     = [
            'status'      => strtolower(sprintf('api/%s/delete/1', $table_name)),
            'status_code' => 1,
            'id'          => '主键id'
        ];
        $map_template_file  = __DIR__ . '/smart_init_templates/controller_base.tpl';
        $use_content_file   = __DIR__ . '/smart_init_templates/controller_base_extra/' . $table_name . '_use.tpl';
        $use_content        = "\n";
        if (is_file($use_content_file)) {
            $use_content = "\n" . file_get_contents($use_content_file);
        }
        $functions_content_file = __DIR__ . '/smart_init_templates/controller_base_extra/' . $table_name . '_functions.tpl';
        $functions_content      = "\n";
        if (is_file($functions_content_file)) {
            $functions_content = "\n" . file_get_contents($functions_content_file) . "\n\n";
        }
        $content = "<?php\n" . $this->view->fetch($map_template_file, [
                'date'                => date('Y/m/d') . "\n",
                'time'                => date('H:i:s') . "\n",
                'table_name'          => $table_name_format,
                'table_comment'       => $this->getTableComment($table_name),
                'ar_get_list_json'    => json_encode($ar_get_list_json, JSON_UNESCAPED_UNICODE),
                'ar_get_json'         => json_encode($ar_get_json, JSON_UNESCAPED_UNICODE),
                'ar_get_by_ids_json'  => json_encode($ar_get_by_ids_json, JSON_UNESCAPED_UNICODE),
                'ar_create_json'      => json_encode($ar_create_json, JSON_UNESCAPED_UNICODE),
                'ar_update_json'      => json_encode($ar_update_json, JSON_UNESCAPED_UNICODE),
                'ar_update_ids_json'  => json_encode($ar_update_ids_json, JSON_UNESCAPED_UNICODE),
                'ar_delete_json'      => json_encode($ar_delete_json, JSON_UNESCAPED_UNICODE),
                'create_api'          => $table_comment['create_api'],
                'fields_config'       => $fields_config,
                'use_content'         => $use_content,
                'functions_content'   => $functions_content,
                'fields_update_ready' => $fields_update_ready
            ]);
        if (!empty($content)) {
            $base_name_file = APP_PATH . 'api/base/' . $this->tableNameFormat($table_name) . 'BaseApiController.php';
            $old_content    = '';
            if (is_file($base_name_file)) {
                $old_content = file_get_contents($base_name_file);
            } else {
                //创建文件夹
                ClFile::dirCreate($base_name_file);
            }
            //存储
            file_put_contents($base_name_file, $content);
            if ($old_content != $content) {
                if (empty($old_content)) {
                    $output->highlight('[Base]:create ' . $base_name_file . " ok");
                    $this->undo_files[] = [
                        'file' => $base_name_file,
                        'type' => 'create'
                    ];
                } else {
                    $output->info('[Base]:modify ' . $base_name_file . " ok");
                    $this->undo_files[] = [
                        'file' => $base_name_file,
                        'type' => 'update'
                    ];
                }
            }
        }
        return true;
    }

    /**
     * 处理 controller
     * @param $table_name
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    private function dealController($table_name, Output $output) {
        $api_controller_file = APP_PATH . 'api/controller/' . $this->tableNameFormat($table_name) . 'Controller.php';
        if (is_file($api_controller_file)) {
            //仅更改名称
            $controller_content = file_get_contents($api_controller_file);
            $class_desc         = ClString::getBetween($controller_content, '/**', ' extends ', false);
            $class_desc         = explode("\n", $class_desc);
            //第一行即注释
            $desc          = $class_desc[0];
            $table_comment = $this->getTableComment($table_name);
            if ($table_comment['name'] != ClString::getBetween($desc, '*', '', false)) {
                $new_desc = '* ' . $table_comment['name'];
                //替换Model name
                $controller_content = str_replace($desc, $new_desc, $controller_content);
                //写入文件
                file_put_contents($api_controller_file, $controller_content);
                //输出
                $output->info('[Api]:modify controller name ' . $api_controller_file);
                $this->undo_files[] = [
                    'file' => $api_controller_file,
                    'type' => 'update'
                ];
            }
            return false;
        }
        $map_template_file     = __DIR__ . '/smart_init_templates/controller.tpl';
        $table_comment         = $this->getTableComment($table_name);
        $table_comment['name'] .= "\n";
        $content               = "<?php\n" . $this->view->fetch($map_template_file, [
                'date'          => date('Y/m/d') . "\n",
                'time'          => date('H:i:s') . "\n",
                'table_name'    => $this->tableNameFormat($table_name),
                'table_comment' => $table_comment
            ]);
        if (!empty($content)) {
            //写入
            file_put_contents($api_controller_file, $content);
            $output->highlight('[Api]:create ' . $api_controller_file . " ok");
            $this->undo_files[] = [
                'file' => $api_controller_file,
                'type' => 'create'
            ];
        }
        return true;
    }

    /**
     * 处理所有文件版本
     * @param Output $output
     */
    private function dealFilesVersion(Output $output) {
        if (empty($this->undo_files)) {
            return;
        }
        $cmd    = [];
        $is_svn = is_dir(DOCUMENT_ROOT_PATH . '/../.svn');
        foreach ($this->undo_files as $each) {
            $each_file = str_replace(DOCUMENT_ROOT_PATH . '/../', '', $each['file']);
            $file_name = ClFile::getName($each_file, true);
            if ($each['type'] == 'create') {
                if ($is_svn) {
                    $cmd[] = sprintf('cd %s && svn add %s && svn ci %s -m "%s"', DOCUMENT_ROOT_PATH . '/../', $each_file, $each_file, 'create ' . $file_name);
                }
            } else {
                if ($is_svn) {
                    $cmd[] = sprintf('cd %s && svn ci %s -m "%s"', DOCUMENT_ROOT_PATH . '/../', $each_file, 'update ' . $file_name);
                }
            }
        }
        if (empty($cmd)) {
            return;
        }
        array_unshift($cmd, '#!/bin/bash');
        //写入bash文件
        $sh_file_name = 'smart_init.sh';
        $file         = APP_PATH . 'console/' . $sh_file_name;
        file_put_contents($file, implode("\n", $cmd));
        //执行文件
        $cmd = sprintf('chmod 777 %s && %s', $file, $file);
        exec($cmd);
        $output->info('exec ' . $file);
        //删除
        unlink($file);
        $output->highlight('unlink ' . $file);
    }

    /**
     * 处理migrate文件
     * @param Output $output
     */
    private function dealMigrate(Output $output) {
        //处理migrate bash
        $file = DOCUMENT_ROOT_PATH . '/../database/migrate.sh';
        if (is_file($file)) {
            //执行
            exec(sprintf('chmod 777 %s && %s', $file, $file));
            //分割
            $output->info('');
            $output->info('exec ' . $file);
            //删除
            unlink($file);
            $output->highlight('unlink ' . $file);
        }
    }

    /**
     * 处理api_doc
     * @param Output $output
     */
    private function dealApiDoc(Output $output) {
        if (empty($this->undo_files)) {
            return;
        }
        $cmd = sprintf('cd %s && php think api_doc', DOCUMENT_ROOT_PATH . '/../');
        exec($cmd);
        //分割
        $output->info('');
        $output->info('deal api doc');
    }

}