/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\index\map;

use app\index\model\BaseModel;
use ClassLibrary\ClArray;
use ClassLibrary\ClCache;

/**
 * {$table_comment['name']} Map
 * Class {$table_name}Map
 * @package app\index\map
 */
class {$table_name}Map extends BaseModel {

    /**
     * 当前数据表名称（含前缀）
     * @var string
     */
    protected $table = '{$table_name_with_prefix}';
    {$const_fields}

    /**
     * 字段校验，用于字段内容判断
     * @var array
     */
    public static $fields_verifies = [{$fields_verifies}];

    /**
     * 只读的字段，仅仅是创建的时候添加，其他地方均不可修改
     * @var array
     */
    protected static $fields_read_only = [{$fields_read_only}];

    /**
     * 不可见字段，去掉view层或接口中的字段
     * @var array
     */
    protected static $fields_invisible = [{$fields_invisible}];

    /**
     * 字段映射
     * @var array
     */
    protected static $fields_show_map_fields = <empty name="fields_show_map_fields">[]<else/>[<foreach name="fields_show_map_fields" item="v">
        <php>echo "\n        ";</php>{$key} => {$v}<if condition="$key neq end($fields_show_map_fields_keys)">,</if>
    </foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 字段格式化
     * @var array
     */
    protected static $fields_show_format = <empty name="fields_show_format">[]<else/>[<foreach name="fields_show_format" item="v"><php>echo "\n        ";</php>{$key} => {$v}<if condition="$key neq end($fields_show_format_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 字段存储格式
     * @var array
     */
    protected static $fields_store_format = <empty name="fields_store_format">[]<else/>[<foreach name="fields_store_format" item="v"><php>echo "\n        ";</php>{$key} => {$v}<if condition="$key neq end($fields_store_format_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 所有字段的注释
     */
    public static $fields_names = <empty name="fields_names">[]<else/>[<foreach name="fields_names" item="v"><php>echo "\n        ";</php>{$key} => '{$v}'<if condition="$key neq end($fields_names_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 获取所有的字段
     * @param array $exclude_fields 不包含的字段
     * @return array
     */
    public static function getAllFields($exclude_fields = [self::F_ID]) {
        $fields = [{$all_fields_str}];
        return array_diff($fields, $exclude_fields);
    }

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        if (is_numeric({$table_comment['is_cache']}) && isset($item[static::F_ID])) {
            static::getByIdRc($item[static::F_ID]);
        }
    }

    /**
     * 按id或id数组获取
     * @param int $id
     * @param array $exclude_fields 不包含的字段
     * @param int|null $duration 缓存时间
     * @return array|false|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getById($id, $exclude_fields = [], $duration = {$table_comment['is_cache']}) {
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
     * @param integer $id 主键
     * @param string $field 字段
     * @param string $default 默认值
     * @param bool $is_convert_to_int 是否转换为int
     * @param int|null $duration 缓存时间
     * @return int|mixed|string
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getValueById($id, $field, $default = '', $is_convert_to_int = false, $duration = {$table_comment['is_cache']}) {
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
    public static function getColumnByIds($ids, $field, $is_convert_to_int = false, $duration = {$table_comment['is_cache']}) {
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
    public static function getItemsByIds($ids, $exclude_fields = [], $duration = {$table_comment['is_cache']}) {
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