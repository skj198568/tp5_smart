<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/5/4
 * Time: 10:23
 */

namespace app\console;

use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClString;
use ClassLibrary\ClSystem;
use ClassLibrary\ClVerify;
use think\Config;
use think\console\Command;
use think\console\Input;
use think\console\Output;
use think\Exception;
use think\exception\ErrorException;
use think\exception\ThrowableError;
use think\View;

/**
 * Api文档
 * Class ApiDoc
 * @package app\console
 */
class ApiDoc extends Command {

    /**
     * @var \think\View 视图类实例
     */
    protected $view;

    protected function configure() {
        $this->setName('api_doc')
            ->setDescription('自动生成api文档');
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool|int|null
     */
    protected function execute(Input $input, Output $output) {
        if (ClSystem::isWin()) {
            $output->error('请在Linux环境下执行');
            return false;
        }
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
     * 处理
     * @param Input $input
     * @param Output $output
     * @return bool
     * @throws Exception
     */
    private function doExecute(Input $input, Output $output) {
        //设置view
        $this->view = View::instance(Config::get('template'), Config::get('view_replace_str'));
        //处理base
        $base_dir = APP_PATH . 'api/controller';
        $files    = ClFile::dirGetFiles($base_dir, [], ['ApiController.php']);
        $api      = [];
//        echo_info('$files:', $files);
        foreach ($files as $each_file) {
//            if (strpos($each_file, '/GroupC') === false) {
//                continue;
//            }
            $output->info($each_file);
            //获取所有函数，包括所有继承的父类
            $functions = $this->getAllFunctions($each_file);
//            echo_info('$functions:', $functions);
            foreach ($functions as $key => $each_function) {
                $functions[$key] = [$each_file, $each_function];
            }
            $each_file_temp = 'each_file_temp';
            while (!empty($each_file_temp)) {
                if ($each_file_temp == 'each_file_temp') {
                    $each_file_temp = $each_file;
                }
                $each_file_temp = $this->getFatherFileAbsoluteUrl($each_file_temp);
                if (!empty($each_file_temp)) {
                    $functions_temp = $this->getAllFunctions($each_file_temp);
                    foreach ($functions_temp as $function_name => $each_function) {
                        if (!array_key_exists($function_name, $functions)) {
                            $functions[$function_name] = [$each_file_temp, $each_function];
                        }
                    }
                }
            }
            $class_desc = $this->getClassDesc($each_file);
//            echo_info('$class_desc:', $class_desc);
            foreach ($functions as $k => $each_function) {
                list($each_file_temp, $each_function) = $each_function;
                //忽略的函数
                $ignore = false;
                foreach (['public function _empty'] as $each_ignore_function) {
                    if (strpos($each_function, $each_ignore_function) !== false) {
                        $ignore = true;
                        break;
                    }
                }
                if ($ignore) {
                    continue;
                }

//                if(strpos($each_file_temp, 'UserFocusController') === false){
//                    continue;
//                }
//                if ($k !== 'getList') {
//                    continue;
//                }
//                echo_info($k);
//                echo_info($each_file_temp, $each_function);
                $desc              = $this->getDescByFunctionContent($each_function);
                $params            = $this->getParamsByFunctionContent($each_file_temp, $each_function);
                $ar_items          = $this->getAjaxReturnByFunctionContent($each_function, $each_file);
                $ajax_return_items = [];
                foreach ($ar_items as $status => $content) {
                    $ajax_return_items[sprintf('api-%s-%s', $this->getClassName($each_file), $status)] = $content;
                }
                $api[sprintf('/api/%s/%s', $this->formatRequestControllerName($this->getClassName($each_file)), $this->getFunctionName($each_function))] = [sprintf('%s / %s', $class_desc, $desc), $params, $ajax_return_items];
            }
        }
//        echo_info($api);
        $api_items         = '';
        $api_item_template = __DIR__ . '/api_doc_templates/api_item.html';
        $id                = 0;
//        echo_info($api);
        $item_index    = 0;
        $menu          = [];
        $color         = 'black';
        $last_api_desc = '';
        foreach ($api as $request_url => $each_content) {
            $id++;
            foreach ($each_content[1] as $param_key => $param_item) {
                if (strpos($param_item['filters'], ';') !== false) {
                    $each_content[1][$param_key]['filters'] = str_replace(';', '<span style="color: blue;">; </span>', $param_item['filters']);
                }
            }
            //美化api_desc
            $api_desc                 = $each_content[0];
            $api_desc_controller_name = ClString::getBetween($api_desc, '', '/', false);
            if (!empty($last_api_desc)) {
                if ($api_desc_controller_name != ClString::getBetween($last_api_desc, '', '/', false)) {
                    $color = ($color == 'black') ? 'blue' : 'black';
                }
            }
            //赋值给上一个接口
            $last_api_desc = $api_desc;
            //替换
            $api_desc  = str_replace($api_desc_controller_name, sprintf('<span style="color:%s;">%s</span>', $color, $api_desc_controller_name), $api_desc);
            $a_name    = 'name' . str_replace('/', '_', $request_url);
            $api_items .= $this->view->fetch($api_item_template, [
                'id'         => ClString::append($id, 0, 3),
                'api_desc'   => $api_desc,
                'url'        => str_replace('/', '<span style="color: blue;">/</span>', $request_url),
                'params'     => $each_content[1],
                'ar_returns' => $each_content[2],
                'a_name'     => $a_name,
                'item_index' => $item_index
            ]);
            $item_index++;
            $request_url_array = explode('/', trim($request_url, '/'));
            if (!isset($menu[$request_url_array[1]])) {
                $menu[$request_url_array[1]]['name']       = ClString::getBetween($each_content[0], '', '/', false);
                $menu[$request_url_array[1]]['controller'] = $request_url_array[1];
                $menu[$request_url_array[1]]['sons']       = [];
            }
            $menu[$request_url_array[1]]['sons'][] = [
                'id'   => $item_index,
                'name' => $each_content[0],
                'href' => $a_name
            ];
        }
//        echo_info($menu);
        $api_item_template = __DIR__ . '/api_doc_templates/api.html';
        $api_content       = $this->view->fetch($api_item_template, [
            'api_items'   => $api_items,
            'create_time' => date('Y-m-d H:i:s'),
            'api_count'   => $item_index,
            'menu'        => array_values($menu)
        ]);
        //处理api
        $file_absolute_url = sprintf(DOCUMENT_ROOT_PATH . '/../doc/api/%s.html', date('y.m.d.H.i'));
        //创建文件夹
        ClFile::dirCreate($file_absolute_url);
        file_put_contents($file_absolute_url, $api_content);
        $output->highlight(sprintf('create %s ok.', $file_absolute_url));
        //修改目录权限为www
        $cmd = sprintf('cd %s && chown www:www * -R', DOCUMENT_ROOT_PATH . '/../');
        exec($cmd);
        return true;
    }

    /**
     * 获取类库定义
     * @param $file_absolute_url
     * @return string
     */
    private function getClassDesc($file_absolute_url) {
        $file_content = file_get_contents($file_absolute_url);
        $file_content = ClString::getBetween($file_content, 'namespace', 'class ', true);
        $file_content = ClString::getBetween($file_content, '/**', 'class', false);
        $file_content = explode('*', $file_content);
        $class_desc   = '';
        foreach ($file_content as $line) {
            $line = trim($line);
            if (!empty($line)) {
                $class_desc = $line;
                break;
            }
        }
        return $class_desc;
    }

    /**
     * 获取类名
     * @param $file_absolute_url
     * @return string
     */
    public function getClassName($file_absolute_url) {
        $file_content       = file_get_contents($file_absolute_url);
        $file_content_array = explode("\n", $file_content);
        $class_name         = '';
        foreach ($file_content_array as $line) {
            if (strpos($line, 'class ') !== false && strpos($line, 'Controller') !== false) {
                $class_name = ClString::getBetween($line, 'class ', 'Controller', false);
                break;
            }
        }
        return trim($class_name);
    }

    /**
     * 获取类库方法
     * @param string $file_absolute_url 类库文件，绝对地址
     * @param string $function_name 单独获取某一个方法
     * @param array $function_types 方法类型，默认取public公共方法
     * @return array|mixed
     */
    private function getAllFunctions($file_absolute_url, $function_name = '', $function_types = ['public']) {
//        if(strpos($file_absolute_url, 'AreaBase') === false){
//            return [];
//        }
        if (empty($file_absolute_url)) {
            return [];
        }
        if (empty($function_types)) {
            $function_types = ['public', 'protected', 'private'];
        }
        $content = file_get_contents($file_absolute_url);
//        echo_info('$content:', $content);
        $return        = [];
        $all_functions = [];
        foreach ($function_types as $function_type) {
            $all_functions = array_merge($all_functions, ClString::parseToArray($content, sprintf('%s ', $function_type), ')'));
        }
        $lines = explode("\n", $content);
        $temp  = '';
        foreach ($lines as $line) {
            $line = trim($line);
            if (strpos($line, 'class ') === 0) {
                //类名
                //新的函数
                $temp = '';
                continue;
            }
            if (strpos($line, ' function ') !== false && !empty(trim(ClString::getBetween($line, 'function', '(', false)))) {
                if (!empty($temp)) {
                    foreach ($all_functions as $each_function) {
                        if (strpos($temp, $each_function) !== false) {
                            //去除所有注释
                            if (strpos($temp, '/**') !== false) {
                                $temp = str_replace(ClString::getBetween($temp, '/**', '*/'), '', $temp);
                            }
                            $return[trim(ClString::getBetween($each_function, 'function', '(', false))] = $this->getFunctionDesc($file_absolute_url, $temp) . $temp;
                        }
                    }
                    //新的函数
                    $temp = '';
                } else {
                    $temp = $line . "\n";
                }
            }
            $temp .= $line . "\n";
        }
        if (!empty($temp)) {
            foreach ($all_functions as $each_function) {
                if (strpos($temp, $each_function) !== false) {
//                    //去除多余的最后一个}
//                    $temp_array = explode("\n", trim($temp));
//                    array_pop($temp_array);
//                    $temp = implode("\n", $temp_array);
                    //去除所有注释
                    if (strpos($temp, '/**') !== false) {
                        $temp = str_replace(ClString::getBetween($temp, '/**', '*/'), '', $temp);
                    }
                    $return[trim(ClString::getBetween($each_function, 'function', '(', false))] = $this->getFunctionDesc($file_absolute_url, $temp) . $temp;
                }
            }
        }
        if (empty($function_name)) {
            //去除默认执行函数
            foreach ($return as $k => $each_function) {
                if (strpos($each_function, ' _initialize') !== false || strpos($each_function, ' __destruct') !== false) {
                    unset($return[$k]);
                    continue;
                }
            }
            return $return;
        } else {
            while (!isset($return[$function_name]) && !empty($file_absolute_url)) {
                $file_absolute_url = $this->getFatherFileAbsoluteUrl($file_absolute_url);
                $return            = $this->getAllFunctions($file_absolute_url, '', $function_types);
            }
            return isset($return[$function_name]) ? $return[$function_name] : '';
        }
    }

    /**
     * 获取函数定义
     * @param $file_absolute_url
     * @param $function_content
     * @return string
     */
    private function getFunctionDesc($file_absolute_url, $function_content) {
        $function_content_array = explode("\n", $function_content);
        $function_name_line     = '';
        foreach ($function_content_array as $line) {
            if (strpos($line, ' function ') !== false) {
                $function_name_line = $line;
                break;
            }
        }
        $content = file_get_contents($file_absolute_url);
        $desc    = ClString::getBetween($content, '/**', $function_name_line);
        return str_replace($function_name_line, '', $desc);
    }

    /**
     * 获取函数描述
     * @param $function_content
     * @return string
     */
    private function getDescByFunctionContent($function_content) {
        $desc       = ClString::getBetween($function_content, '/**', '*/');
        $desc       = str_replace(['/**', '* ', '*/'], ['', '', ''], $desc);
        $desc       = explode("\n", trim($desc));
        $desc_array = [];
        foreach ($desc as $line) {
            $line = trim($line);
            if (strpos($line, '@') === 0) {
                continue;
            } else {
                $desc_array[] = $line;
            }
        }
        return empty($desc_array) ? '-' : implode('; ', $desc_array);
    }

    /**
     * 获取方法的参数
     * @param $class_file_absolute_url
     * @param $function_content
     * @return array
     */
    private function getParamsByFunctionContent($class_file_absolute_url, $function_content) {
        $return_array = [];
        //获取get_param方式参数
        $params = ClString::parseToArray($function_content, 'get_param', ');', false);
//        echo_info($params);
        foreach ($params as $param) {
//            if (strpos($param, 'not_allow_subject_ids') === false) {
//                continue;
//            }
            $param = ClString::spaceTrim($param);
            $param = trim($param);
            $param = ClString::spaceTrim($param);
//            echo_info($param);
            if (strpos($param, 'ClFieldVerify') === false || strpos($param, 'fetchVerifies') === false) {
                $filters = [];
            } else {
                $filters = ClString::getBetween($param, 'ClFieldVerify', 'fetchVerifies()');
            }
            $param = str_replace($filters, '', $param);
            if (strpos($param, ',,') === false) {
                $desc_index = 2;
            } else {
                $desc_index = 1;
            }
            $param       = str_replace([',,', '\''], [',', '"'], $param);
            $param       = trim($param, ')');
            $param       = trim($param, '(');
            $param       = trim($param, ',');
            $param_temp  = [];
            $param_array = explode('","', trim($param, '"'));
//            echo_info($param_array);
            foreach ($param_array as $each) {
                if (strpos($each, ',') !== false) {
                    foreach (explode(',', $each) as $each_param) {
                        $param_temp[] = $each_param;
                    }
                } else {
                    $param_temp[] = $each;
                }
            }
//            echo_info($param_temp);
            //参数名
            $name = $param_temp[0];
            if (strpos($name, '"') !== false) {
                $name = ClString::getBetween($name, '', '"', false);
            }
            if (strpos($name, "'") === 0) {
                //参数定义
                $name = trim($name, "'");
            } else if (strpos($name, '::') !== false) {
                //静态变量
                $name_array = explode('::', $name);
                $name       = $this->getWithNameSpace($class_file_absolute_url, $name_array[0]);
                eval(sprintf('$name = %s::%s;', $name, trim($name_array[1], '.')));
            }
            if (strpos($name, '/') !== false) {
                $name = ClString::getBetween($name, '', '/', false);
            }
//            if ($name == 'not_allow_subject_ids') {
//                echo_info($name, $filters);
//            }
            //过滤器
            if (!empty($filters)) {
                $sub_filters = ClString::getBetween($filters, 'instance', 'fetchVerifies', false);
                if (strpos($sub_filters, '::') !== false) {
                    $sub_filters = explode('::', $sub_filters);
                    $classes     = [];
                    foreach ($sub_filters as $each_sub_filters_class) {
                        $each_sub_filters_class = ClString::toArray($each_sub_filters_class);
                        $sub_class              = '';
                        foreach ($each_sub_filters_class as $each_sub_character) {
                            if (preg_match('/^[A-Za-z0-9\\\_]+$/', $each_sub_character) === 1) {
                                $sub_class .= $each_sub_character;
                            } else {
                                $sub_class = '';
                            }
                        }
                        if (!empty($sub_class) && !in_array($sub_class, $classes) && strpos($sub_class, '\\') === false) {
                            $classes[] = $sub_class;
                        }
                    }
                    if (count($classes) > 0) {
                        $classes_replace = [];
                        foreach ($classes as $each_class) {
                            $classes_replace[] = $this->getWithNameSpace($class_file_absolute_url, $each_class);
                        }
                        //替换
                        $filters = str_replace($classes, $classes_replace, $filters);
                    }
                }
                //去除带参数的校验器
                $filters = explode('->', $filters);
//                if ($name == 'not_allow_subject_ids') {
//                    echo_info($name, $filters);
//                }
                foreach ($filters as $k_each_filter => $v_each_filter) {
                    if (strpos($v_each_filter, '$') !== false) {
                        unset($filters[$k_each_filter]);
                    }
                }
                $filters = implode('->', $filters);
                $filters = '$filters = ClassLibrary\\' . $filters . ";";
                eval($filters);
                //转换为数组
                $filters = (array)$filters;
//                if ($name == 'not_allow_subject_ids') {
//                    echo_info($name, $filters);
//                }
            } else {
                $filters = [];
            }
            //注释
            $remark = '';
            if (isset($param_temp[$desc_index])) {
                $remark = trim($param_temp[$desc_index], '"');
                if (strpos($remark, '->getPk')) {
                    $remark = '主键';
                } elseif (strpos($remark, 'sprintf') !== false) {
                    $remark = '';
                }
            }
            $return_array[] = [
                'name'    => $name,
                'filters' => ClFieldVerify::getNamesStringByVerifies($filters),
                'remark'  => $remark
            ];
        }
        //获取model静态方法获取参数
        $function_content_array = explode("\n", $function_content);
        foreach ($function_content_array as $each_line) {
            if (strpos($each_line, '::getAllFields') !== false) {
                $each_line_array = ClString::parseToArray(str_replace('=', ',', $each_line), ',', ')');
//                echo_info($each_line_array);
                $params_functions = '';
                foreach ($each_line_array as $each_line_item) {
                    if (strpos($each_line_item, '::getAllFields') !== false) {
                        $params_functions = trim(trim(trim($each_line_item, ';'), ','));
                        break;
                    }
                }
//                while(strpos($params_functions, ',') !== false){
//                    $params_functions = ClString::getBetween($params_functions, ',', '', false);
//                }
//                echo_info('1', $params_functions);
                $class_name                    = ClString::getBetween($params_functions, '', '::', false);
                $class_name_with_namespace     = $this->getWithNameSpace($class_file_absolute_url, $class_name);
                $class_const_file_absolute_url = $this->getFileAbsoluteUrlByNamespace($class_name_with_namespace);
                //替换为map文件
                $class_const_file_absolute_url = str_replace(['Model', 'model'], ['Map', 'map'], $class_const_file_absolute_url);
                if (!is_file($class_const_file_absolute_url)) {
                    continue;
                }
                $class_const_file_absolute_url_content = file_get_contents($class_const_file_absolute_url);
                $class_const_content                   = ClString::parseToArray($class_const_file_absolute_url_content, '/**', ';');
                foreach ($class_const_content as $k => $v) {
                    if (strpos($v, 'const F_') === false) {
                        unset($class_const_content[$k]);
                    }
                }
                $class_const_content = array_values($class_const_content);
//                    le_info($class_const_content);
                $params_functions = str_replace($class_name, $class_name_with_namespace, $params_functions);
//                echo_info(sprintf('$params=%s;', $params_functions));
                eval(sprintf('$params=%s;', $params_functions));
                $fields_verifies = sprintf('%s::$fields_verifies', $class_name_with_namespace);
//                echo_info($fields_verifies);
                eval(sprintf('$fields_verifies=%s;', $fields_verifies));
//                echo_info($params);
                foreach ($class_const_content as $each_const_param) {
                    foreach ($params as $each_param) {
                        if (strpos($each_const_param, sprintf("'%s'", $each_param)) !== false) {
                            $each_const_param_temp = ClString::getBetween($each_const_param, '/**', '*/', false);
                            $each_const_param_temp = trim(str_replace('*', '', $each_const_param_temp));
                            $each_const_param_temp = explode("\n", $each_const_param_temp);
                            $remark                = [];
                            foreach ($each_const_param_temp as $each_const_param_line) {
                                $each_const_param_line = trim($each_const_param_line);
                                $remark[]              = $each_const_param_line;
                            }
                            //丰富remark信息
                            if (strpos($class_const_file_absolute_url_content, 'const C_' . strtoupper($each_param) . ' ') !== false) {
                                $field_config  = sprintf('%s::C_' . strtoupper($each_param), $class_name_with_namespace);
                                $remark_append = [];
                                $command       = sprintf('$field_config=%s;', $field_config);
                                eval($command);
                                foreach ($field_config as $each_field_key => $each_field_config) {
                                    $remark_append[] = $each_field_key . '/' . $each_field_config;
                                }
                                $remark[] = 'Config: ' . implode('、', $remark_append);
                            }
                            //美化
                            foreach ($remark as $k_remark => $v_remark) {
                                if (strpos($v_remark, ':') !== false) {
                                    $v_remark_pre = ClString::getBetween($v_remark, ':', '', false);
                                    $v_remark     = str_replace($v_remark_pre, '<span style="color: red;">' . $v_remark_pre . '</span>', $v_remark);
                                }
                                $remark[$k_remark] = $v_remark;
                            }
                            $remark         = implode('<span style="color: blue;">; </span>', $remark);
                            $return_array[] = [
                                'name'    => $each_param,
                                'filters' => isset($fields_verifies[$each_param]) ? ClFieldVerify::getNamesStringByVerifies($fields_verifies[$each_param]) : '无',
                                'remark'  => $remark
                            ];
                        }
                    }
                }
            }
        }
        //获取内部调用的函数
        $inner_functions = ClString::parseToArray($function_content, '$this->', '(');
        foreach ($inner_functions as $k => $v) {
            if (strpos($v, ',') !== false || strpos($v, ';') !== false) {
                continue;
            }
            $function         = trim(trim(trim($v, '$this->'), '('));
            $function_content = $this->getAllFunctions($class_file_absolute_url, $function, ['public', 'protected']);
            //本类内存在该方法
            $return_array = array_merge($return_array, $this->getParamsByFunctionContent($class_file_absolute_url, $function_content));
        }
        //去重，避免多继承函数参数的重复问题
        $true_return = [];
        foreach ($return_array as $each_param) {
            $is_include = false;
            foreach ($true_return as $each_true_param) {
                if ($each_true_param['name'] == $each_param['name']) {
                    $is_include = true;
                }
            }
            if (!$is_include) {
                //设置获取参数类型问题
                if (strpos($each_param['name'], '/') !== false) {
                    $each_param['name'] = ClString::getBetween($each_param['name'], '', '/', false);
                }
                //忽略create_time、update_time
                if (in_array($each_param['name'], ['create_time', 'update_time'])) {
                    continue;
                }
                $true_return[] = $each_param;
            }
        }
        return $true_return;
    }

    /**
     * 获取父类的绝对地址
     * @param $class_file_absolute_url
     * @return mixed|string
     */
    private function getFatherFileAbsoluteUrl($class_file_absolute_url) {
        if (empty($class_file_absolute_url)) {
            return '';
        }
        $class_content       = file_get_contents($class_file_absolute_url);
        $class_content_array = explode("\n", $class_content);
        $father_class_name   = '';
        foreach ($class_content_array as $line) {
            if (strpos($line, 'class ') !== false && strpos($line, ' extends ') !== false) {
                if (strpos($line, '{')) {
                    $father_class_name = trim(ClString::getBetween($line, 'extends ', '{', false));
                } else {
                    $father_class_name = trim(ClString::getBetween($line, 'extends ', '', false));
                }
                break;
            }
        }
        if (!empty($father_class_name)) {
            $father_class_name = $this->getWithNameSpace($class_file_absolute_url, $father_class_name);
            if (strpos($father_class_name, 'app\\') !== false) {
                $father_class_name = sprintf('%s%s.php', APP_PATH, $father_class_name);
                $father_class_name = str_replace(['\\', 'app/'], ['/', ''], $father_class_name);
            } else {
                $father_class_name = '';
            }
        }
        return $father_class_name;
    }

    /**
     * 依据命名空间获取文件绝对地址
     * @param $class_name_space
     * @return mixed
     */
    private function getFileAbsoluteUrlByNamespace($class_name_space) {
        $class_name_space = sprintf('%s%s.php', APP_PATH, $class_name_space);
        return str_replace(['\\', 'app/'], ['/', ''], $class_name_space);
    }

    /**
     * 获取命名空间
     * @param $class_file_absolute_url
     * @param $class_name
     * @return string
     */
    private function getWithNameSpace($class_file_absolute_url, $class_name) {
        $class_name_temp = ClString::getBetween(trim($class_name), '', '::', false);
        if (!empty($class_name_temp)) {
            $class_name = $class_name_temp;
        }
        $class_content = file_get_contents($class_file_absolute_url);
        $class_content = explode("\n", $class_content);
        $namespace     = '';
        foreach ($class_content as $line) {
            if (strpos($line, 'use ') !== false) {
                if (strpos($line, sprintf('\%s', $class_name)) !== false) {
                    $namespace = trim(ClString::getBetween($line, 'use ', $class_name, false));
                    break;
                }
            }
        }
        if (!empty($namespace)) {
            $namespace .= $class_name;
        }
        return $namespace;
    }

    /**
     * 获取返回值
     * @param $function_content
     * @param $file_absolute_url
     * @return array
     */
    private function getAjaxReturnByFunctionContent($function_content, $file_absolute_url) {
        $ar_functions  = ClString::parseToArray($function_content, '->ar', "}'");
        $ar_return     = [];
        $function_name = $this->getFunctionName($function_content);
        foreach ($ar_functions as $each) {
            $each     = ClString::spaceTrim($each);
            $each     = rtrim($each, ';');
            $each     = rtrim($each, ')');
            $each     = str_replace(["'{", "}'"], ['"{', '}"'], $each);
            $json_str = '';
            if (strpos($each, '"{') !== false) {
                $json_str = ClString::getBetween($each, '"{', '}"');
                $json_str = trim($json_str, '"');
                $json_str = ClString::jsonFormat($json_str, true);
            }
            $ar_return[sprintf('%s-%s', $function_name, ClString::getBetween($each, '(', ',', false))] = $json_str;
        }
        //拼接扩展返回
        $ar_functions = ClString::parseToArray($function_content, 'static::', 'ReturnExample');
        foreach ($ar_functions as $each) {
            $each_function_name                                        = ClString::getBetween($each, '::', '', false);
            $function_content                                          = $this->getAllFunctions($file_absolute_url, $each_function_name, []);
            $function_content                                          = ClString::getBetween($function_content, "'{", "}'");
            $function_content                                          = trim($function_content, "'");
            $status_code                                               = json_decode($function_content, true);
            $status_code                                               = $status_code['status_code'];
            $ar_return[sprintf('%s-%s', $function_name, $status_code)] = $json_str = ClString::jsonFormat($function_content, true);
        }
        return $ar_return;
    }

    /**
     * 获取函数名称
     * @param $function_content
     * @return string
     */
    private function getFunctionName($function_content) {
        $function_name = ClString::getBetween($function_content, 'function', '(', false);
        return strtolower(trim($function_name));
    }

    /**
     * 格式化请求名称
     * @param $controller_name
     * @return string
     */
    private function formatRequestControllerName($controller_name) {
        $controller_name = ClString::toArray($controller_name);
        foreach ($controller_name as $k => $each) {
            if (ClVerify::isAlphaCapital($each)) {
                $controller_name[$k] = '_' . $each;
            }
        }
        $controller_name = implode('', $controller_name);
        return trim(strtolower($controller_name), '_');
    }

}