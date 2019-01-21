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
 * 地址信息 Map
 * Class AreaMap
 * @package app\index\map
 */
class AreaMap extends BaseModel {

    /**
     * 实例对象存放数组
     * @var array
     */
    protected static $instances_array = [];

    /**
     * 当前数据表名称（含前缀）
     * @var string
     */
    protected $table = 't_area';

    /**
     * 名称
     * Type: varchar(255)
     * Default: ''
     */
    const F_NAME = 'name';

    /**
     * 父类id
     * Type: int(11)
     * Default: 0
     */
    const F_F_ID = 'f_id';

    /**
     * 类型，1/省、直辖市，2/城市，3/区县
     * Type: int(11)
     * Default: 0
     */
    const F_TYPE = 'type';

    /**
     * 省/直辖市
     */
    const V_TYPE_PROVINCE = 1;

    /**
     * 城市
     */
    const V_TYPE_CITY = 2;

    /**
     * 区县
     */
    const V_TYPE_AREA = 3;

    /**
     * 字段配置
     */
    const C_TYPE = [
        1 => '省/直辖市',
        2 => '城市',
        3 => '区县'
    ];

    /**
     * 字段校验，用于字段内容判断
     * @var array
     */
    public static $fields_verifies = [
        self::F_NAME => ["is_required","chinese",["length_max",255]], 
        self::F_F_ID => ["is_required","number",["length_max",11]], 
        self::F_TYPE => ["is_required","number",["in_array",["1","2","3"]],["length_max",11]], 
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
        self::F_TYPE => [[[["1","省\/直辖市"],["2","城市"],["3","区县"]],"_show"]]
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
        self::F_NAME => '名称',
        self::F_F_ID => '父类id',
        self::F_TYPE => '类型，1/省、直辖市，2/城市，3/区县'
    ];

    /**
     * 默认值
     * @var array
     */
    protected static $fields_default_values = [];

    /**
     * 获取所有的字段
     * @param array $exclude_fields 不包含的字段
     * @return array
     */
    public static function getAllFields($exclude_fields = [self::F_ID]) {
        $fields = [self::F_ID, self::F_NAME, self::F_F_ID, self::F_TYPE];
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
        if (is_numeric(3600) && isset($item[static::F_ID])) {
            static::getByIdRc($item[static::F_ID]);
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
    public static function getById($id, $exclude_fields = [], $duration = 3600) {
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
    public static function getValueById($id, $field, $default = '', $is_convert_to_int = false, $duration = 3600) {
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
    public static function getColumnByIds($ids, $field, $is_convert_to_int = false, $duration = 3600) {
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
    public static function getItemsByIds($ids, $sort_field = '', $sort_type = self::V_ORDER_ASC, $exclude_fields = [], $duration = 3600) {
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
     * 获取所有的省份
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getAllProvinces() {
        return self::instance()->where(array(
            self::F_TYPE => self::V_TYPE_PROVINCE
        ))->cache([], 3600)->field(array(
            self::F_ID, self::F_NAME, self::F_F_ID
        ))->select();
    }

    /**
     * 获取所有的城市
     * @param $province_id
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getCitesByProvinceId($province_id) {
        return self::instance()->where(array(
            self::F_TYPE => self::V_TYPE_CITY,
            self::F_F_ID => $province_id
        ))->cache([$province_id], 3600)->field(array(
            self::F_ID, self::F_NAME, self::F_F_ID
        ))->select();
    }

    /**
     * 按城市获取区县
     * @param $city_id
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getAreasByCityId($city_id) {
        return self::instance()->where(array(
            self::F_TYPE => self::V_TYPE_AREA,
            self::F_F_ID => intval($city_id)
        ))->field(array(
            self::F_ID, self::F_NAME, self::F_F_ID
        ))->select();
    }

    /**
     * 按名字获取信息
     * @param $name
     * @return array|false|null|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getByName($name) {
        return self::instance()->where([
            self::F_NAME => ['like', '%' . $name . '%']
        ])->find();
    }

    /**
     * 按name获取id
     * @param $name
     * @param int $father_id 父类id
     * @param int $type 类型
     * @return int|mixed
     */
    public static function getIdByName($name, $father_id = 0, $type = 0) {
        $where = [
            self::F_NAME => ['like', '%' . $name . '%']
        ];
        if ($father_id != 0) {
            $where[self::F_F_ID] = $father_id;
        }
        if ($type != 0) {
            $where[self::F_TYPE] = $type;
        }
        $id = self::instance()->where($where)->value(self::F_ID);
        if (empty($id)) {
            $id = 0;
        }
        return $id;
    }

    /**
     * 获取根id
     * @param $area_id
     * @return mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getRootProvinceId($area_id) {
        $info = self::getById($area_id);
        if ($info[self::F_TYPE] == self::V_TYPE_PROVINCE) {
            return $info[self::F_ID];
        } else {
            //继续向上寻找
            return self::getRootProvinceId($info[self::F_F_ID]);
        }
    }

}