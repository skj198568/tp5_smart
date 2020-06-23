<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/12/7
 * Time: 11:20
 */

namespace think\log\driver;

/**
 * udp日志
 * Class Udp
 * @package think\log\driver
 */
class Udp extends File {

    /**
     * 日志写入
     * @access protected
     * @param array $message 日志信息
     * @param string $destination 日志文件
     * @param bool $apart 是否独立文件写入
     * @param bool $append 是否追加请求信息
     * @return bool
     */
    protected function write($message, $destination, $apart = false, $append = false) {
        $report_address = config('REMOTE_UDP_LOG_ADDRESS');
        if (empty($report_address)) {
            exit('please config `REMOTE_UDP_LOG_ADDRESS`');
        }
        // 日志信息封装
        $info['timestamp'] = date($this->config['time_format']);
        foreach ($message as $type => $msg) {
            $info[$type] = is_array($msg) ? implode("\r\n", $msg) : $msg;
        }
        if (PHP_SAPI == 'cli') {
            $message = $this->parseCliLog($info);
        } else {
            // 添加调试日志
            $this->getDebugLog($info, $append, $apart);
            $message = $this->parseLog($info);
        }
        $socket = stream_socket_client($report_address);
        if (!$socket) {
            return false;
        }
        //ip
        $message = request()->ip() . "\n" . $message;
        //udp包最大65507
        $max_length = 65000;
        if (strlen($message) > $max_length) {
            //分多次上传
            while (strlen($message) > $max_length) {
                $temp_message = substr($message, 0, $max_length);
                stream_socket_sendto($socket, '.=' . $temp_message);
                $message = substr($message, $max_length - 1);
            }
            //剩余部分
            if (!empty($message)) {
                $message = '.=' . $message;
            }
        }
        //再次发送
        if (strlen($message) > 0) {
            stream_socket_sendto($socket, $message);
        }
        return true;
    }

}