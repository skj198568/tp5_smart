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
use think\Config;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;
use think\View;

/**
 * 依据数据库表创建Model
 * Class ModelInit
 * @package app\console
 */
class SmartInit extends Command
{

    /**
     * @var \think\View 视图类实例
     */
    protected $view;

    protected function configure()
    {
        $this->setName('smart_init')
            ->addOption('--table_name', '-t', Option::VALUE_REQUIRED, '不带前缀的数据库表名，例如：user_goods，如果参数为空则创建所有表')
            ->setDescription('依据数据库表自动创建Model模型、ApiController接口');
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return int|null|void
     * @throws \think\Exception
     */
    protected function execute(Input $input, Output $output)
    {
        //设置view
        $this->view = View::instance(Config::get('template'), Config::get('view_replace_str'));
        //设置Mysql
        ClMysql::init(config('database.hostname'), config('database.hostport'), config('database.username'), config('database.password'), config('database.database'));
        //分割
        $output->highlight('');
        //初始化Model
        $this->initModel($input, $output);
        //分割
        $output->question('');
        //初始化ApiController
        $this->initController($input, $output);
        //分割
        $output->highlight('');
    }

    /**
     * 初始化Model
     * @param Input $input
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    protected function initModel(Input $input, Output $output)
    {
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
    private function getTableNameWithPrefix($table_name)
    {
        return config('database.prefix') . $table_name;
    }

    /**
     * 表名格式化
     * @param $table_name
     * @return string
     */
    private function tableNameFormat($table_name)
    {
        if (strpos($table_name, '_')) {
            $table_name_array = explode('_', $table_name);
            $table_name = '';
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
    public function getTableComment($table_name)
    {
        $table_name = $this->getTableNameWithPrefix($table_name);
        $table_comment = ClMysql::query(sprintf("SELECT TABLE_COMMENT FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_NAME = '%s'", $table_name));
        if(empty($table_comment[0]['TABLE_COMMENT'])){
            $table_comment = [
                'name' => '',
                'is_cache' => 0
            ];
        }else{
            $table_comment = json_decode($table_comment[0]['TABLE_COMMENT'], true);
            if(empty($table_comment)){
                $table_comment = [
                    'name' => $table_comment
                ];
            }
            if(!isset($table_comment['is_cache'])){
                $table_comment['is_cache'] = 0;
            }
        }
        return $table_comment;
    }

    /**
     * 处理model map
     * @param $table_name
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    protected function dealModelMap($table_name, Output $output)
    {
        $table_info = ClMysql::query('SHOW FULL FIELDS FROM `' . $this->getTableNameWithPrefix($table_name) . '`');
        if (empty($table_info)) {
            $output->highlight(sprintf('table name:%s is not exist.', $table_name));
            return false;
        }
        $map_template_file = __DIR__ . '/smart_init_templates/model_map.tpl';
        //所有字段
        $all_fields = [];
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
        foreach ($table_info as $k => $each) {
            $all_fields[] = 'self::F_' . strtoupper($each['Field']);
            if ($each['Field'] == 'id') {
                continue;
            }
            $field_comment = json_decode($each['Comment'], true);
            if(empty($field_comment)){
                $field_comment = ['name' => $each['Comment']];
            }
            $const_fields .= sprintf("
    /**
     * %s
     * Type: %s
     * Default: %s
     */
    const F_%s = '%s';
", $field_comment['name'], $each['Type'], $each['Default'] === '' ? "''" : $each['Default'], strtoupper($each['Field']), $each['Field']);
            //处理静态参数
            if (isset($field_comment['const_values']) && !empty($field_comment['const_values'])) {
                foreach ($field_comment['const_values'] as $const_value_array) {
                    $const_fields .= sprintf("
    /**
     * %s
     */
    const V_%s_%s = '%s';
", $const_value_array[2], strtoupper($each['Field']), strtoupper($const_value_array[0]), $const_value_array[1]);
                }
            }
            //设置校验器，默认有长度限制
            if (isset($field_comment['verifies'])) {
                $has_verify_length_max = false;
                foreach($field_comment['verifies'] as $each_verify){
                    if($each_verify[0] == 'length_max'){
                        $has_verify_length_max = true;
                        break;
                    }
                }
                if(!$has_verify_length_max){
                    $max_length = ClString::getBetween($each['Type'], '(', ')', false);
                    if(is_numeric($max_length) && $max_length > 0){
                        $field_comment['verifies'] = array_merge($field_comment['verifies'], ClFieldVerify::instance()->verifyStringLengthMax($max_length)->fetchVerifies());
                    }
                }
            }else{
                $max_length = ClString::getBetween($each['Type'], '(', ')', false);
                if(is_numeric($max_length) && $max_length > 0){
                    $field_comment['verifies'] = ClFieldVerify::instance()->verifyStringLengthMax($max_length)->fetchVerifies();
                }
            }
            if(isset($field_comment['verifies'])){
                $fields_verifies['self::F_' . strtoupper($each['Field'])] = $field_comment['verifies'];
            }
            //设置只读字段
            if (isset($field_comment['is_read_only'])) {
                $fields_read_only[] = 'self::F_' . strtoupper($each['Field']);
            }
            //设置不可见字段
            if(isset($field_comment['visible']) && $field_comment['visible'] == 0){
                $fields_invisible[] = 'self::F_' . strtoupper($each['Field']);
            }
            //设置额外显示字段
            if(isset($field_comment['show_map_fields'])){
                $fields_show_map_fields['self::F_' . strtoupper($each['Field'])] = json_encode($field_comment['show_map_fields'], JSON_UNESCAPED_UNICODE);
            }
            //设置字段格式化
            if(isset($field_comment['show_format'])){
                $fields_show_format['self::F_' . strtoupper($each['Field'])] = json_encode($field_comment['show_format'], JSON_UNESCAPED_UNICODE);
            }
            //设置字段存储格式
            if(isset($field_comment['store_format'])){
                $fields_store_format['self::F_' . strtoupper($each['Field'])] = json_encode($field_comment['store_format'], JSON_UNESCAPED_UNICODE);
            }
        }
        //校验器
        $fields_verifies_string = '';
        //拼接校验器
        foreach ($fields_verifies as $field => $verify_array) {
            $fields_verifies_string .= sprintf('
        %s => %s, ', $field, json_encode($verify_array, JSON_UNESCAPED_UNICODE));
        }
        $content = "<?php\n" . $this->view->fetch($map_template_file, [
                'date' => date('Y/m/d') . "\n",
                'time' => date('H:i:s') . "\n",
                'table_comment' => $this->getTableComment($table_name),
                'table_name' => $this->tableNameFormat($table_name),
                'table_name_with_prefix' => $this->getTableNameWithPrefix($table_name),
                'const_fields' => $const_fields,
                'fields_verifies' => empty($fields_verifies_string) ? '' : trim($fields_verifies_string, ',') . "\n    ",
                'fields_read_only' => empty($fields_read_only) ? '' : implode(', ', $fields_read_only),
                'all_fields_str' => implode(', ', $all_fields),
                'fields_show_map_fields' => $fields_show_map_fields,
                'fields_show_format' => $fields_show_format,
                'fields_store_format' => $fields_store_format,
                'fields_invisible' => empty($fields_invisible) ? '' : implode(', ', $fields_invisible)
            ]);
        $map_file = APP_PATH . 'index/map/' . $this->tableNameFormat($table_name) . 'Map.php';
        //创建文件夹
        ClFile::dirCreate($map_file);
        //写入
        file_put_contents($map_file, $content);
        $output->info('[Map]:create ' . $map_file . " ok");
        return true;
    }

    /**
     * 处理model
     * @param $table_name
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    protected function dealModel($table_name, Output $output)
    {
        $model_name_file = APP_PATH . 'index/model/' . $this->tableNameFormat($table_name) . 'Model.php';
        if (is_file($model_name_file)) {
            $output->highlight('[Model]:' . $model_name_file . " is exist");
            return false;
        }
        $template_file = __DIR__ . '/smart_init_templates/model.tpl';
        $content =  "<?php\n" . $this->view->fetch($template_file, [
                'date' => date('Y/m/d') . "\n",
                'time' => date('H:i:s') . "\n",
                'table_name' => $this->tableNameFormat($table_name),
                'table_comment' => $this->getTableComment($table_name)
            ]);
        if (!empty($content)) {
            //写入
            file_put_contents($model_name_file, $content);
            $output->highlight('[Model]:create ' . $model_name_file . " ok");
        }
        return true;
    }

    /**
     * 获取所有的表格
     * @return array
     */
    private function getAllTables()
    {
        $tables = ClMysql::query("SHOW TABLES LIKE '" . config('database.prefix') . "%'");
        $table_names = [];
        foreach ($tables as $k => $table_name) {
            $table_name = array_pop($table_name);
            if(!empty(config('database.prefix')) && strpos($table_name, config('database.prefix')) !== 0){
                continue;
            }
            $table_name = ClString::replaceOnce(config('database.prefix'), '', $table_name);
            if ($table_name != 'migrations') {
                $table_names[] = $table_name;
            }
        }
        return $table_names;
    }

    /**处理ApiController
     *
     * @param Input $input
     * @param Output $output
     * @return bool
     * @throws \think\Exception
     */
    protected function initController(Input $input, Output $output)
    {
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
    private function dealControllerApiBase($table_name, Output $output){
        //如果不创建api，则忽略
        $table_comment = $this->getTableComment($table_name);
        $table_info = ClMysql::query('SHOW FULL FIELDS FROM `' . $this->getTableNameWithPrefix($table_name) . '`');
        if (empty($table_info)) {
            $output->highlight(sprintf('table name:%s is not exist.', $table_name));
            return false;
        }
        $table_name_format = $this->tableNameFormat($table_name);
        $info = [];
        foreach($table_info as $k => $each){
            if(empty($each['Comment'])){
                $comment = [];
            }else{
                $comment = json_decode($each['Comment'], true);
                if(empty($comment)){
                    $comment = ['name' => $comment];
                }
            }
            //如果是不可见字段，则忽略
            if(isset($comment['visible']) && $comment['visible'] == 0){
                continue;
            }
            $info[$each['Field']] = empty($comment) ? ($each['Field'] == 'id' ? '主键id' : '未定义') : $comment['name'];
            //静态变量
            $const_str = '';
            if(isset($comment['const_values'])){
                foreach($comment['const_values'] as $each_const_value){
                    $const_str .= sprintf(' %s/%s;', $each_const_value[1], $each_const_value[2]);
                }
                if(!empty($const_str)){
                    $info[$each['Field']] .= sprintf(':%s', $const_str);
                }
            }
            //额外字段
            if(isset($comment['show_map_fields'])){
                foreach($comment['show_map_fields'] as $each_field){
                    $info[$each_field[1]] = $each_field[2];
                }
            }
        }
        $ar_get_json = [
            'status' => strtolower(sprintf('api-%s-get-1', $table_name_format)),
            'info' => $info
        ];
        $ar_get_list_json = [
            'status' => strtolower(sprintf('api-%s-getList-1', $table_name_format)),
            'items' => [$info]
        ];
        $map_template_file = __DIR__ . '/smart_init_templates/controller_base.tpl';
        $content = "<?php\n" . $this->view->fetch($map_template_file, [
                'date' => date('Y/m/d') . "\n",
                'time' => date('H:i:s') . "\n",
                'table_name' => $table_name_format,
                'table_comment' => $this->getTableComment($table_name),
                'ar_get_json' => json_encode($ar_get_json, JSON_UNESCAPED_UNICODE),
                'ar_get_list_json' => json_encode($ar_get_list_json, JSON_UNESCAPED_UNICODE),
                'create_api' => $table_comment['create_api']
            ]);
        if(!empty($content)){
            $base_name_file = APP_PATH . 'api/base/' . $this->tableNameFormat($table_name) . 'BaseApiController.php';
            //创建文件夹
            ClFile::dirCreate($base_name_file);
            //存储
            file_put_contents($base_name_file, $content);
            $output->info('[ApiBaseController]:create ' . $base_name_file . " ok");
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
    private function dealController($table_name, Output $output){
        $api_controller_file = APP_PATH . 'api/controller/' . $this->tableNameFormat($table_name).'Controller.php';
        if (is_file($api_controller_file)) {
            $output->highlight('[ApiController]:' . $api_controller_file . " is exist.");
            return false;
        }
        $map_template_file = __DIR__ . '/smart_init_templates/controller.tpl';
        $table_comment = $this->getTableComment($table_name);
        $table_comment['name'] .= "\n";
        $content = "<?php\n" . $this->view->fetch($map_template_file, [
                'date' => date('Y/m/d') . "\n",
                'time' => date('H:i:s') . "\n",
                'table_name' => $this->tableNameFormat($table_name),
                'table_comment' => $table_comment
            ]);
        if (!empty($content)) {
            //写入
            file_put_contents($api_controller_file, $content);
            $output->info('[ApiController]:create ' . $api_controller_file . " ok");
        }
        return true;
    }

}

