<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\index\map;

use app\index\model\BaseModel;
use ClassLibrary\ClArray;
use ClassLibrary\ClCache;
use ClassLibrary\ClHttp;
use ClassLibrary\ClString;

/**
 * 短网址 Map
 * Class UrlShortMap
 * @package app\index\map
 */
class UrlShortMap extends BaseModel {

    /**
     * 实例对象存放数组
     * @var array
     */
    protected static $instances_array = [];

    /**
     * 当前数据表名称（含前缀）
     * @var string
     */
    protected $table = '';

    /**
     * 短连接
     * Type: varchar(255)
     * Default: ''
     */
    const F_SHORT_URL = 'short_url';

    /**
     * 真实url
     * Type: varchar(255)
     * Default: ''
     */
    const F_TRUE_URL = 'true_url';

    /**
     * 超时时间，如果为0，则永不超时
     * Type: int(11)
     * Default: 0
     */
    const F_END_TIME = 'end_time';

    /**
     * 创建时间
     * Type: int(11)
     * Default: 0
     */
    const F_CREATE_TIME = 'create_time';

    /**
     * 字段校验，用于字段内容判断
     * @var array
     */
    public static $fields_verifies = [
        self::F_SHORT_URL   => [["length_max", 255]],
        self::F_TRUE_URL    => [["length_max", 255]],
        self::F_END_TIME    => ["number", ["length_max", 11]],
        self::F_CREATE_TIME => ["number", ["length_max", 11]],
    ];

    /**
     * 只读的字段，仅仅是创建的时候添加，其他地方均不可修改
     * @var array
     */
    protected static $fields_read_only = [];

    /**
     * 不可见字段，去掉view层或接口中的字段
     * @var array
     */
    protected static $fields_invisible = [];

    /**
     * 字段映射
     * @var array
     */
    protected static $fields_show_map_fields = [];

    /**
     * 字段格式化
     * @var array
     */
    protected static $fields_show_format = [
        self::F_END_TIME    => [["date('Y-m-d H:i:s', %s)", "_show"]],
        self::F_CREATE_TIME => [["date('Y-m-d H:i:s', %s)", "_show"]]
    ];

    /**
     * 字段存储格式
     * @var array
     */
    public static $fields_store_format = [];

    /**
     * 所有字段的注释
     */
    public static $fields_names = [
        self::F_SHORT_URL   => '短连接',
        self::F_TRUE_URL    => '真实url',
        self::F_END_TIME    => '超时时间，如果为0，则永不超时',
        self::F_CREATE_TIME => '创建时间'
    ];

    /**
     * 默认值
     * @var array
     */
    protected static $fields_default_values = [];

    /**
     * 初始化
     */
    public function initialize() {
        parent::initialize();
        $this->table = config('database.prefix') . 'url_short';
    }

    /**
     * 获取所有的字段
     * @param array $exclude_fields 不包含的字段
     * @return array
     */
    public static function getAllFields($exclude_fields = [self::F_ID]) {
        $fields = [self::F_ID, self::F_SHORT_URL, self::F_TRUE_URL, self::F_END_TIME, self::F_CREATE_TIME];
        return array_diff($fields, $exclude_fields);
    }

    /**
     * 实例对象
     * @param int $id -1/获取实例数量，-2/自动新增一个实例
     * @return int|mixed|null|static
     */
    public static function instance($id = 0) {
        if ($id >= 0) {
            if (!isset(static::$instances_array[$id])) {
                static::$instances_array[$id] = new static();
            }
            return static::$instances_array[$id];
        } else if ($id == -1) {
            return count(static::$instances_array);
        } else if ($id == -2) {
            return static::instance(count(static::$instances_array));
        } else {
            return null;
        }
    }

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        if (is_numeric(600) && isset($item[static::F_ID])) {
            static::getByIdRc($item[static::F_ID]);
        }
        if (isset($item[self::F_SHORT_URL])) {
            self::getByShortUrlRc($item[self::F_SHORT_URL]);
        }
    }

    /**
     * 按id获取
     * @param int $id
     * @param array $exclude_fields 不包含的字段
     * @param int|null $duration 缓存时间
     * @return array|false|null|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getById($id, $exclude_fields = [], $duration = 600) {
        if (is_numeric($duration)) {
            $info = static::instance()->cache([$id], $duration)->where([
                static::F_ID => $id
            ])->find();
            if (empty($info)) {
                return [];
            } else {
                return ClArray::getByKeys($info, static::getAllFields($exclude_fields));
            }
        } else {
            return static::instance()->where([
                static::F_ID => $id
            ])->field(static::getAllFields($exclude_fields))->find();
        }
    }

    /**
     * 清除缓存
     * @param $id
     * @return bool
     */
    protected static function getByIdRc($id) {
        return ClCache::remove($id);
    }

    /**
     * 获取某个字段值
     * @param int $id 主键
     * @param string $field 字段
     * @param string $default 默认值
     * @param bool $is_convert_to_int 是否转换为int
     * @param int|null $duration 缓存时间
     * @return int|mixed|string
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getValueById($id, $field, $default = '', $is_convert_to_int = false, $duration = 600) {
        if (is_numeric($duration)) {
            $info = static::getById($id, [], $duration);
            if (empty($info)) {
                return $default;
            } else {
                if ($is_convert_to_int) {
                    return intval($info[$field]);
                } else {
                    return $info[$field];
                }
            }
        } else {
            return static::instance()->where([
                static::F_ID => $id
            ])->value($field, $default, $is_convert_to_int);
        }
    }

    /**
     * 按id数组获取某一列的值
     * @param array $ids
     * @param string $field
     * @param bool $is_convert_to_int
     * @param int|null $duration
     * @return array|false|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getColumnByIds($ids, $field, $is_convert_to_int = false, $duration = 600) {
        if (!is_array($ids) || empty($ids)) {
            return [];
        }
        if (is_numeric($duration)) {
            $items = static::getItemsByIds($ids, [], $duration);
            if (!empty($items)) {
                $items = array_column($items, $field);
            }
        } else {
            $items = static::instance()->where([
                static::F_ID => ['in', $ids]
            ])->column($field);
        }
        if (!empty($items) && $is_convert_to_int) {
            array_walk($items, function (&$value) {
                $value = intval($value);
            });
        }
        return $items;
    }

    /**
     * 按ids获取
     * @param $ids
     * @param string $sort_field
     * @param string $sort_type
     * @param array $exclude_fields
     * @param int $duration
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getItemsByIds($ids, $sort_field = '', $sort_type = self::V_ORDER_ASC, $exclude_fields = [], $duration = 600) {
        if (!is_array($ids) || empty($ids)) {
            return [];
        }
        if (is_numeric($duration)) {
            $items = [];
            foreach ($ids as $each_id) {
                $info = static::getById($each_id, $exclude_fields, $duration);
                if (!empty($info)) {
                    $items[] = $info;
                }
            }
            if (!empty($sort_field)) {
                //排序
                usort($items, function ($a, $b) use ($sort_field, $sort_type) {
                    if ($a[$sort_field] > $b[$sort_field]) {
                        if ($sort_type == self::V_ORDER_ASC) {
                            return 1;
                        } else {
                            return -1;
                        }
                    } else {
                        if ($sort_type == self::V_ORDER_ASC) {
                            return -1;
                        } else {
                            return 1;
                        }
                    }
                });
            }
            return $items;
        } else {
            if (empty($sort_field)) {
                return static::instance()->where([
                    static::F_ID => ['in', $ids]
                ])->field(static::getAllFields($exclude_fields))->select();
            } else {
                return static::instance()->where([
                    static::F_ID => ['in', $ids]
                ])->field(static::getAllFields($exclude_fields))->order([$sort_field => $sort_type])->select();
            }
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