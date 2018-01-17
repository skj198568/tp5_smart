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
class Udp
{

    /**
     * 日志写入接口
     * @access public
     * @param string $log 日志信息
     * @return bool
     */
    public function save($log) {
        $report_address = config('REMOTE_UDP_LOG_ADDRESS');
        if(empty($report_address)){
            exit('please config `REMOTE_UDP_LOG_ADDRESS`');
        }
        //添加域名、ip
        $log = ClHttp::getServerDomain().' '.request()->ip() . "\n" . $log;
        $socket = stream_socket_client($report_address);
        if (!$socket) {
            return false;
        }
        return stream_socket_sendto($socket, $log) == strlen($log);
    }

}