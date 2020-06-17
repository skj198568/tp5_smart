<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/12/7
 * Time: 11:20
 */

namespace think\log\driver;

use ClassLibrary\ClHttp;

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
        //添加域名、ip
        $message = ClHttp::getServerDomain(false) . ' ' . request()->ip() . "\n" . $message;
        $socket  = stream_socket_client($report_address);
        if (!$socket) {
            return false;
        }
        return stream_socket_sendto($socket, $message) == strlen($message);
    }

}