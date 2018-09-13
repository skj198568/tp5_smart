<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\index\map;

use app\index\model\BaseModel;
use ClassLibrary\ClArray;
use ClassLibrary\ClCache;

/**
 * 后台任务 Map
 * Class TaskMap
 * @package app\index\map
 */
class TaskMap extends BaseModel {

    /**
     * 实例对象存放数组
     * @var array
     */
    protected static $instances_array = [];

    /**
     * 当前数据表名称（含前缀）
     * @var string
     */
    protected $table = 't_task';
    
    /**
     * 带有命名空间的任务调用地址
     * Type: varchar(255)
     * Default: ''
     */
    const F_COMMAND = 'command';

    /**
     * 创建时间
     * Type: int(11)
     * Default: 0
     */
    const F_CREATE_TIME = 'create_time';

    /**
     * 开始时间
     * Type: int(11)
     * Default: 0
     */
    const F_START_TIME = 'start_time';

    /**
     * 结束时间
     * Type: int(11)
     * Default: 0
     */
    const F_END_TIME = 'end_time';

    /**
     * 备注
     * Type: text
     * Default: 
     */
    const F_REMARK = 'remark';

    /**
     * 字段校验，用于字段内容判断
     * @var array
     */
    public static $fields_verifies = [
        self::F_COMMAND => ["is_required",["length_max",255]], 
        self::F_CREATE_TIME => ["number",["length_max",11]], 
        self::F_START_TIME => ["number",["length_max",11]], 
        self::F_END_TIME => ["number",["length_max",11]], 
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
        self::F_CREATE_TIME => [["date('Y-m-d H:i:s', %s)","_show"]],
        self::F_START_TIME => [["date('Y-m-d H:i:s', %s)","_show"]],
        self::F_END_TIME => [["date('Y-m-d H:i:s', %s)","_show"]]
    ];

    /**
     * 字段存储格式
     * @var array
     */
    protected static $fields_store_format = [];

    /**
     * 所有字段的注释
     */
    public static $fields_names = [
        self::F_COMMAND => '带有命名空间的任务调用地址',
        self::F_CREATE_TIME => '创建时间',
        self::F_START_TIME => '开始时间',
        self::F_END_TIME => '结束时间',
        self::F_REMARK => '备注'
    ];

    /**
     * 默认值
     * @var array
     */
    protected static $fields_default_values = [
        self::F_REMARK => ''
    ];

    /**
     * 获取所有的字段
     * @param array $exclude_fields 不包含的字段
     * @return array
     */
    public static function getAllFields($exclude_fields = [self::F_ID]) {
        $fields = [self::F_ID, self::F_COMMAND, self::F_CREATE_TIME, self::F_START_TIME, self::F_END_TIME, self::F_REMARK];
        return array_diff($fields, $exclude_fields);
    }

    /**
     * 实例对象
     * @param int $id -1/获取实例数量，-2/自动新增一个实例
     * @return int|mixed|null|static
     */
    public static function instance($id = 0) {
        if($id >= 0) {
            if (!isset(static::$instances_array[$id])) {
                static::$instances_array[$id] = new static();
            }
            return static::$instances_array[$id];
        }else if($id == -1) {
            return count(static::$instances_array);
        }else if($id == -2) {
            return static::instance(count(static::$instances_array));
        }else{
            return null;
        }
    }

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        if (is_numeric(null) && isset($item[static::F_ID])) {
            static::getByIdRc($item[static::F_ID]);
        }
    }

    /**
     * 按id或id数组获取
     * @param int $id
     * @param array $exclude_fields 不包含的字段
     * @param int|null $duration 缓存时间
     * @return array|false|null|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getById($id, $exclude_fields = [], $duration = null) {
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
    public static function getValueById($id, $field, $default = '', $is_convert_to_int = false, $duration = null) {
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
    public static function getColumnByIds($ids, $field, $is_convert_to_int = false, $duration = null) {
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
     * @param array $ids
     * @param array $exclude_fields
     * @param int|null $duration
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getItemsByIds($ids, $exclude_fields = [], $duration = null) {
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
            return $items;
        } else {
            return static::instance()->where([
                static::F_ID => ['in', $ids]
            ])->field(static::getAllFields($exclude_fields))->select();
        }
    }

}