<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/11/06
 * Time: 17:08:46
 */

namespace app\index\model;

use app\index\map\UrlShortMap;
use ClassLibrary\ClCache;
use ClassLibrary\ClHttp;
use ClassLibrary\ClString;

/**
 * 短网址 Model
 */
class UrlShortModel extends UrlShortMap {

    /**
     * 初始化
     */
    public function initialize() {
        parent::initialize();
    }

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        //先执行父类
        parent::cacheRemoveTrigger($item);
        if (isset($item[self::F_SHORT_URL])) {
            self::getByShortUrlRc($item[self::F_SHORT_URL]);
        }
    }

    /**
     * 按短连接获取
     * @param $short_url
     * @param int $duration
     * @return array|false|null|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getByShortUrl($short_url, $duration = 3600) {
        return self::instance()->cache([$short_url], $duration)->where([
            self::F_SHORT_URL => $short_url
        ])->find();
    }

    /**
     * 清缓存
     * @param $short_url
     * @return bool
     */
    protected static function getByShortUrlRc($short_url) {
        return ClCache::remove($short_url);
    }

    /**
     * 获取短域名
     * @param string $url 源域名
     * @param bool $with_domain 是否包含域名
     * @param int $duration 短地址有效时间，比如3600秒，0为永不失效
     * @return string
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getShortUrl($url, $with_domain = false, $duration = 0) {
        $current_domain = ClHttp::getServerDomain();
        $url            = trim($url);
        if (strpos($url, $current_domain) === 0) {
            $url = ClString::replaceOnce($current_domain, '', $url);
        }
        $base32    = [
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
            'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
            'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
            'y', 'z', '0', '1', '2', '3', '4', '5'
        ];
        $hex       = md5($url);
        $short_url = '';
        //把加密字符按照8位一组16进制与0x3FFFFFFF(30位1)进行位与运算
        $sub_hex = substr($hex, 0, 8);
        $int     = 0x3FFFFFFF & intval('0x' . $sub_hex, 0);
        for ($j = 0; $j < 6; $j++) {
            //把得到的值与0x0000001F进行位与运算，取得字符数组chars索引
            $val       = 0x0000001F & $int;
            $short_url .= $base32[$val];
            $int       = $int >> 5;
        }
        $info = self::getByShortUrl($short_url);
        if (empty($info)) {
            //新增
            self::instance()->insert([
                self::F_SHORT_URL => $short_url,
                self::F_TRUE_URL  => $url,
                self::F_END_TIME  => $duration == 0 ? $duration : time() + $duration
            ]);
        } else {
            //url不一致，忽略原先生成的url，直接覆盖
            if ($info[self::F_TRUE_URL] != $url) {
                self::instance()->where([
                    self::F_ID => $info[self::F_ID]
                ])->setField([
                    self::F_TRUE_URL => $url,
                    self::F_END_TIME => $duration == 0 ? $duration : time() + $duration
                ]);
            }
        }
        if ($with_domain) {
            $short_url = $current_domain . '/su/' . $short_url;
        }
        return $short_url;
    }

}