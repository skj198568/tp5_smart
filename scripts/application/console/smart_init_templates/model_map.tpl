/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\index\map;

use app\index\model\BaseModel;
use ClassLibrary\ClArray;
use ClassLibrary\ClCache;{$use_content}

/**
 * {$table_comment['name']} Map
 * Class {$table_name_with_format}Map
 * @package app\index\map
 */
class {$table_name_with_format}Map extends BaseModel {
    
    /**
     * 上次插入id
     * @var int
     */
    protected static $last_insert_id = 0;

    /**
     * 回调sql
     * @var string
     */
    protected static $trigger_sql = '';

    /**
     * 回调ids
     * @var array
     */
    protected static $trigger_id_or_ids = [];

    /**
     * 回调数据items
     * @var array
     */
    protected static $trigger_items = [];

    /**
     * 回调结果items
     * @var array
     */
    protected static $trigger_result_items = [];

    /**
     * 实例对象存放数组
     * @var array
     */
    protected static $instances_array = [];
{$const_fields}

    /**
     * 字段校验，用于字段内容判断
     * @var array
     */
    public static $fields_verifies = [{$fields_verifies}];

    /**
     * 只读的字段，不可在接口的create方法中创建也不可在update方法中修改，可在其他后台方法内处理
     * @var array
     */
    public static $fields_read_only = [{$fields_read_only}];

    /**
     * 不可见字段，去掉view层或接口中的字段
     * @var array
     */
    protected static $fields_invisible = [{$fields_invisible}];

    /**
     * 字段映射
     * @var array
     */
    protected static $fields_show_map_fields = <empty name="fields_show_map_fields">[]<else/>[<foreach name="fields_show_map_fields" item="v"><php>echo "\n        ";</php>{$key} => {$v}<if condition="$key neq end($fields_show_map_fields_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 字段格式化
     * @var array
     */
    protected static $fields_show_format = <empty name="fields_show_format">[]<else/>[<foreach name="fields_show_format" item="v"><php>echo "\n        ";</php>{$key} => {$v}<if condition="$key neq end($fields_show_format_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 字段存储格式
     * @var array
     */
    public static $fields_store_format = <empty name="fields_store_format">[]<else/>[<foreach name="fields_store_format" item="v"><php>echo "\n        ";</php>{$key} => {$v}<if condition="$key neq end($fields_store_format_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 所有字段的注释
     */
    public static $fields_names = <empty name="fields_names">[]<else/>[<foreach name="fields_names" item="v"><php>echo "\n        ";</php>{$key} => '{$v}'<if condition="$key neq end($fields_names_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;

    /**
     * 默认值
     * @var array
     */
    protected static $fields_default_values = <empty name="fields_default_values">[]<else/>[<foreach name="fields_default_values" item="v"><php>echo "\n        ";</php>{$key} => '{$v}'<if condition="$key neq end($fields_default_values_keys)">,</if></foreach><php>echo "\n    ";</php>]</empty>;
<present name="table_comment['partition']">

    /**
     * 分表规则
     * @var array
     */
    public static $partition = {:is_array($table_comment['partition']) ? json_encode($table_comment['partition']) : []};
</present>

    /**
     * 初始化
     */
    public function initialize() {
        parent::initialize();
        //设置表名
        $this->table = config('database.prefix') . '{$table_name}';
    }

    /**
     * 获取所有的字段
     * @param array $exclude_fields 不包含的字段
     * @return array
     */
    public static function getAllFields($exclude_fields = [self::F_ID]) {
        $fields = [{$all_fields_str}];
        return array_diff($fields, $exclude_fields);
    }
<present name="table_comment['partition']">

    /**
     * 实例对象
     * @param int ${$table_comment['partition'][0]}<php>echo "\n";</php>
     * @param int $id -1/获取实例数量，-2/自动新增一个实例
     * @return int|mixed|null|static
     */
    public static function instance(${$table_comment['partition'][0]}<if condition="!isset($table_comment['partition'][1])"> = 0</if>, $id = 0) {
        if ($id >= 0) {
            $id = json_encode([${$table_comment['partition'][0]}, $id], JSON_UNESCAPED_UNICODE);
            if (!isset(static::$instances_array[$id])) {
                static::$instances_array[$id] = new static();
                //设置分表
                static::$instances_array[$id]->autoDivideTable(${$table_comment['partition'][0]});
            }
            return static::$instances_array[$id];
        } else if ($id == -1) {
            return count(static::$instances_array);
        } else if ($id == -2) {
            return static::instance(${$table_comment['partition'][0]}, count(static::$instances_array));
        } else {
            return null;
        }
    }
    <else/>

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
</present>
<present name="table_comment['partition']">

    /**
     * 缓存清除器
     * 采用$items = $this->triggerGetItems();方式获取所有影响的数据
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     * @throws \think\exception\PDOException
     */
    protected function triggerRemoveCache(){
        parent::triggerRemoveCache();
        if(is_numeric({$table_comment['is_cache']})){
            $items = $this->triggerGetItems();
            foreach($items as $item){
                if(isset($item['{$table_comment['partition'][0]}']) && isset($item[static::F_ID])){
                    static::getByIdRc($item['{$table_comment['partition'][0]}'], $item[static::F_ID]);
                }
            }
        }{$cache_remove_trigger_content}
    }
    <else/>

    /**
     * 缓存清除器
     * 采用$items = $this->triggerGetItems();方式获取所有影响的数据
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     * @throws \think\exception\PDOException
     */
    protected function triggerRemoveCache() {
        parent::triggerRemoveCache();
        if(is_numeric({$table_comment['is_cache']})){
            $items = $this->triggerGetItems();
            foreach($items as $item){
                if(isset($item[static::F_ID])){
                    static::getByIdRc($item[static::F_ID]);
                }
            }
        }{$cache_remove_trigger_content}
    }
</present>
<present name="table_comment['partition']">

    /**
     * 按id获取
     * @param int ${$table_comment['partition'][0]}<php>echo "\n";</php>
     * @param int $id
     * @param array $exclude_fields 不包含的字段
     * @param int|null $duration 缓存时间
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getById(${$table_comment['partition'][0]}, $id, $exclude_fields = [], $duration = {$table_comment['is_cache']}) {
        if (empty($id)) {
            return [];
        }
        if (is_numeric($duration)) {
            $info = static::instance(${$table_comment['partition'][0]})->cache([${$table_comment['partition'][0]}, $id], $duration)->where([
                <if condition="isset($table_comment['partition'][1])">static::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]},
                </if>static::F_ID => $id
            ])->find();
            if (empty($info)) {
                return [];
            } else {
                return ClArray::getByKeys($info, static::getAllFields($exclude_fields));
            }
        } else {
            return static::instance(${$table_comment['partition'][0]})->where([
                static::F_ID => $id
            ])->field(static::getAllFields($exclude_fields))->find();
        }
    }
    <else/>

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
    public static function getById($id, $exclude_fields = [], $duration = {$table_comment['is_cache']}) {
        if (empty($id)) {
            return [];
        }
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
</present>
<present name="table_comment['partition']">

    /**
     * 清除缓存
     * @param int ${$table_comment['partition'][0]}<php>echo "\n";</php>
     * @param $id
     * @return bool
     */
    protected static function getByIdRc(${$table_comment['partition'][0]}, $id) {
        return ClCache::remove(${$table_comment['partition'][0]}, $id);
    }
    <else/>

    /**
     * 清除缓存
     * @param $id
     * @return bool
     */
    protected static function getByIdRc($id) {
        return ClCache::remove($id);
    }
</present>
<present name="table_comment['partition']">

    /**
     * 获取某个字段值
     * @param int ${$table_comment['partition'][0]}<php>echo "\n";</php>
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
    public static function getValueById(${$table_comment['partition'][0]}, $id, $field, $default = '', $is_convert_to_int = false, $duration = {$table_comment['is_cache']}) {
        if (empty($id)) {
            return null;
        }
        if (is_numeric($duration)) {
            $info = static::getById(${$table_comment['partition'][0]}, $id, [], $duration);
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
            return static::instance(${$table_comment['partition'][0]})->where([
                <if condition="isset($table_comment['partition'][1])">static::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]},
                </if>static::F_ID => $id
            ])->value($field, $default, $is_convert_to_int);
        }
    }
    <else/>

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
    public static function getValueById($id, $field, $default = '', $is_convert_to_int = false, $duration = {$table_comment['is_cache']}) {
        if (empty($id)) {
            return null;
        }
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
</present>
<present name="table_comment['partition']">

    /**
     * 按id数组获取某一列的值
     * @param int ${$table_comment['partition'][0]}<php>echo "\n";</php>
     * @param array $ids
     * @param string $field
     * @param bool $is_convert_to_int
     * @param int|null $duration
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getColumnByIds(${$table_comment['partition'][0]}, $ids, $field, $is_convert_to_int = false, $duration = {$table_comment['is_cache']}) {
        if (!is_array($ids) || empty($ids)) {
            return [];
        }
        if (is_numeric($duration)) {
            $items = static::getItemsByIds(${$table_comment['partition'][0]}, $ids, [], $duration);
            if (!empty($items)) {
                $items = array_column($items, $field);
            }
        } else {
            $items = static::instance(${$table_comment['partition'][0]})->where([
                <if condition="isset($table_comment['partition'][1])">static::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]},
                </if>static::F_ID => ['in', $ids]
            ])->column($field);
        }
        if (!empty($items) && $is_convert_to_int) {
            array_walk($items, function (&$value) {
                $value = intval($value);
            });
        }
        return $items;
    }
    <else/>

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
</present>
<present name="table_comment['partition']">

    /**
     * 按ids获取
     * @param int ${$table_comment['partition'][0]}<php>echo "\n";</php>
     * @param array $ids
     * @param string $sort_field
     * @param string $sort_type
     * @param array $exclude_fields
     * @param int|null $duration
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getItemsByIds(${$table_comment['partition'][0]}, $ids, $sort_field = '', $sort_type = self::V_ORDER_ASC, $exclude_fields = [], $duration = {$table_comment['is_cache']}) {
        if (!is_array($ids) || empty($ids)) {
            return [];
        }
        if (is_numeric($duration)) {
            $items = [];
            foreach ($ids as $each_id) {
                $info = static::getById(${$table_comment['partition'][0]}, $each_id, $exclude_fields, $duration);
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
                return static::instance(${$table_comment['partition'][0]})->where([
                    <if condition="isset($table_comment['partition'][1])">static::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]},
                    </if>static::F_ID => ['in', $ids]
                ])->field(static::getAllFields($exclude_fields))->select();
            } else {
                return static::instance(${$table_comment['partition'][0]})->where([
                    <if condition="isset($table_comment['partition'][1])">static::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]},
                    </if>static::F_ID => ['in', $ids]
                ])->field(static::getAllFields($exclude_fields))->order([$sort_field => $sort_type])->select();
            }
        }
    }
    <else/>

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
    public static function getItemsByIds($ids, $sort_field = '', $sort_type = self::V_ORDER_ASC, $exclude_fields = [], $duration = {$table_comment['is_cache']}) {
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
</present>
<present name="table_comment['partition']">

    /**
     * 设置分表
     * @param int ${$table_comment['partition'][0]}<php>echo "\n";</php>
     * @throws \Exception
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function autoDivideTable(${$table_comment['partition'][0]} = 0) {
        $this->is_divide_table = true;
        <if condition="isset($table_comment['partition'][1])">if (!is_numeric(${$table_comment['partition'][0]}) || ${$table_comment['partition'][0]} == 0) {
            exit('{$table_name_with_prefix} instance required valid ${$table_comment['partition'][0]}');
        }
        $suffix = floor(${$table_comment['partition'][0]} / {$table_comment['partition'][1]});
        if ($suffix < 0) {
            $suffix = 0;
        }
        <else/>if (${$table_comment['partition'][0]} == 0) {
            $suffix = date('{$table_comment['partition'][0]}');
        } else {
            $suffix = ${$table_comment['partition'][0]};
        }
        </if>//拼接
        if (!empty($suffix)) {
            $suffix = '_' . $suffix;
        }
        //分表表名
        if (substr($this->table, -strlen($suffix), strlen($suffix)) != $suffix) {
            $source_table_name = $this->table;
            //设置当前表名
            $this->table .= $suffix;
        } else {
            $source_table_name = substr($this->table, 0, strlen($this->table) - strlen($suffix));
        }
        //表是否存在
        if (!$this->tableIsExist($this->table)) {
            $this->tableCopy($source_table_name, $this->table);
        }
    }
</present>{$functions_content}

}