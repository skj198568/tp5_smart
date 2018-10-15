<?php
/**
 * Created by PhpStorm.
 * User: skj19
 * Date: 2018-8-21
 * Time: 16:00
 */

namespace app\console;


use ClassLibrary\ClFile;
use ClassLibrary\ClString;
use think\Config;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;
use think\View;

/**
 * 日志统计
 * Class LogCount
 * @package app\console
 */
class LogCount extends Command {

    /**
     * @var \think\View 视图类实例
     */
    protected $view;

    /**
     * 配置
     */
    protected function configure() {
        $this->setName('log_count')
            ->addOption('start_day', 'd', Option::VALUE_REQUIRED, '日志统计开始时间，如不设置，则取所有的日志，格式为：20180808', 0)
            ->addOption('slow_microsecond', 'm', Option::VALUE_REQUIRED, '查询微秒数', 30)
            ->setDescription('日志统计');
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return int|null|void
     * @throws \think\Exception
     */
    protected function execute(Input $input, Output $output) {
        if ($input->hasOption('start_day')) {
            $start_day = intval($input->getOption('start_day'));
        } else {
            $start_day = 0;
        }
        //设置view
        $this->view = View::instance(Config::get('template'), Config::get('view_replace_str'));
        $log_dir    = DOCUMENT_ROOT_PATH . str_replace('/', DIRECTORY_SEPARATOR, '/../runtime/log/');
        $files      = ClFile::dirGetFiles($log_dir);
        //忽略cli日志
        foreach ($files as $k => $file) {
            if (strpos($file, 'cli') !== false) {
                unset($files[$k]);
                continue;
            }
            //判断日期
            if ($start_day > 0) {
                $day = ClString::getBetween($file, 'log/', '.log', false);
                $day = explode('/', $day);
                if (strpos($day[1], '-') !== false) {
                    $day[1] = ClString::getBetween($day[1], '-', '', false);
                }
                $day = intval(implode('', $day));
                if ($day < $start_day) {
                    unset($files[$k]);
                    continue;
                }
            }
        }
        $files = array_values($files);
        //request
        $this->dealRequest($output, $files);
        //sql
        $this->dealSql($output, $files);
        //处理慢查询
        $this->dealSqlSlowQuery($input, $output, $files);
        //修改目录权限为www
        $cmd = sprintf('cd %s && chown www:www * -R', DOCUMENT_ROOT_PATH . '/../');
        exec($cmd);
    }

    /**
     * 处理api
     * @param Output $output
     * @param $files
     * @throws \think\Exception
     */
    protected function dealRequest(Output $output, $files) {
        //统计接口请求次数
        $request = [];
        foreach ($files as $file) {
            $content = file_get_contents($file);
            $content = explode("\n", $content);
            foreach ($content as $line_source) {
                $line = $line_source;
                if (strpos($line, ' GET ') !== false) {
                    $line = ClString::getBetween($line, ' GET ', '', false);
                } else if (strpos($line, ' POST ') !== false) {
                    $line = ClString::getBetween($line, ' POST ', '', false);
                } else {
                    $line = '';
                }
                if (empty($line)) {
                    continue;
                }
                //?参数方式处理
                if (strpos($line, '?') !== false) {
                    $line = ClString::getBetween($line, '', '?', false);
                }
                //.html .htm处理
                $line = str_replace(['.html', '.htm'], ['', ''], $line);
                //获取请求module/controller/action
                $line = ClString::replaceOnce('/', '', $line);
                $line = trim($line);
                if (empty($line)) {
                    continue;
                }
                $line = explode('/', $line);
                $line = array_slice($line, 0, 3);
                $line = '/' . implode('/', $line);
                if (isset($request[$line])) {
                    $request[$line]++;
                } else {
                    $request[$line] = 1;
                }
            }
        }
        //倒序
        arsort($request);
        //整理数据
        $request_array = [];
        $all_count     = array_sum($request);
        foreach ($request as $controller_action => $count) {
            $request_array[] = [$controller_action, $count, number_format($count / $all_count * 100, 2)];
        }
        $request_item_template = __DIR__ . '/log_count_templates/index.html';
        $html_content          = $this->view->fetch($request_item_template, [
            'time'          => time(),
            'request_array' => $request_array
        ]);
        $target_file           = DOCUMENT_ROOT_PATH . '/log_count/index.html';
        ClFile::dirCreate($target_file);
        //写入文件
        file_put_contents($target_file, $html_content);
        $output->highlight('request_count:' . $target_file);
    }

    /**
     * 处理sql统计
     * @param Output $output
     * @param $files
     * @throws \think\Exception
     */
    protected function dealSql(Output $output, $files) {
        $sql = [];
        foreach ($files as $file) {
            $content = file_get_contents($file);
            $content = explode("\n", $content);
            foreach ($content as $line) {
                if (strpos($line, '[ SQL ]') === false) {
                    continue;
                }
                $line = strtolower($line);
                if (strpos($line, 'select') === false) {
                    continue;
                }
                $table_name = ClString::getBetween($line, 'from ', ' ', false);
                if (strpos($table_name, '.') !== false) {
                    continue;
                }
                $table_name = trim($table_name, '`');
                if (strpos($table_name, config('database.prefix')) === false || strpos($table_name, '(') !== false) {
                    continue;
                }
                if (isset($sql[$table_name])) {
                    $sql[$table_name]++;
                } else {
                    $sql[$table_name] = 1;
                }
            }
        }
        //倒序
        arsort($sql);
        //整理数据
        $sql_array = [];
        $all_count = array_sum($sql);
        foreach ($sql as $table_name => $count) {
            $sql_array[] = [$table_name, $count, number_format($count / $all_count * 100, 2)];
        }
        $request_item_template = __DIR__ . '/log_count_templates/sql_table.html';
        $html_content          = $this->view->fetch($request_item_template, [
            'time'      => time(),
            'sql_array' => $sql_array
        ]);
        $target_file           = DOCUMENT_ROOT_PATH . '/log_count/sql_table.html';
        ClFile::dirCreate($target_file);
        //写入文件
        file_put_contents($target_file, $html_content);
        $output->info('sql:' . $target_file);
    }

    /**
     * 处理慢查询
     * @param Input $input
     * @param Output $output
     * @param $files
     * @throws \think\Exception
     */
    protected function dealSqlSlowQuery(Input $input, Output $output, $files) {
        if ($input->hasOption('slow_microsecond')) {
            $slow_microsecond = intval($input->getOption('slow_microsecond'));
        } else {
            $slow_microsecond = 30;
        }
        $sql               = [];
        $sql_runtime_array = [];
        foreach ($files as $file) {
            $content = file_get_contents($file);
            $content = explode("\n", $content);
            foreach ($content as $line) {
                if (strpos($line, '[ SQL ]') === false) {
                    continue;
                }
                $line = strtolower($line);
                if (strpos($line, 'select') === false) {
                    continue;
                }
                $sql_runtime = ClString::getBetween($line, 'runtime:', 's', false);
                //转换成毫秒
                $sql_runtime = floatval($sql_runtime * 1000);
                if ($sql_runtime < $slow_microsecond) {
                    continue;
                }
                $sql_content = ClString::getBetween($line, 'select', '[', true);
                $sql_content = trim($sql_content, '[');
                if (isset($sql[$sql_content])) {
                    $sql[$sql_content]++;
                } else {
                    $sql[$sql_content] = 1;
                }
                if (isset($sql_runtime_array[$sql_content])) {
                    $sql_runtime_array[$sql_content] += $sql_runtime;
                } else {
                    $sql_runtime_array[$sql_content] = $sql_runtime;
                }
            }
        }
        //倒序
        arsort($sql);
        //整理数据
        $sql_array = [];
        $all_count = array_sum($sql);
        foreach ($sql as $table_name => $count) {
            $sql_array[] = [$table_name, $count, number_format($sql_runtime_array[$table_name] / $count, 2), number_format($count / $all_count * 100, 2)];
        }
        $request_item_template = __DIR__ . '/log_count_templates/sql_slow.html';
        $html_content          = $this->view->fetch($request_item_template, [
            'time'      => time(),
            'sql_array' => $sql_array
        ]);
        $target_file           = DOCUMENT_ROOT_PATH . '/log_count/sql_slow.html';
        ClFile::dirCreate($target_file);
        //写入文件
        file_put_contents($target_file, $html_content);
        $output->highlight('sql_slow:' . $target_file);
    }

}