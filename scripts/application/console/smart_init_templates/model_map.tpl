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
class {$table_name}Map extends BaseModel
{

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
        <php>echo "\n\t\t";</php>{$key} => {$v}<if condition="$v neq end($fields_show_map_fields)">,</if>
    </foreach><php>echo "\n\t";</php>]</empty>;

    /**
     * 字段格式化
     * @var array
     */
    protected static $fields_show_format = <empty name="fields_show_format">[]<else/>[<foreach name="fields_show_format" item="v"><php>echo "\n\t\t";</php>{$key} => {$v}<if condition="$v neq end($fields_show_format)">,</if></foreach><php>echo "\n\t";</php>]</empty>;

    /**
     * 字段存储格式
     * @var array
     */
    protected static $fields_store_format = <empty name="fields_store_format">[]<else/>[<foreach name="fields_store_format" item="v"><php>echo "\n\t\t";</php>{$key} => {$v}<if condition="$v neq end($fields_store_format)">,</if></foreach><php>echo "\n\t";</php>]</empty>;

    /**
     * 获取所有的字段
     * @param array $exclude_fields 不包含的字段
     * @return array
     */
    public static function getAllFields($exclude_fields = [self::F_ID])
    {
        $fields = [{$all_fields_str}];
        return array_diff($fields, $exclude_fields);
    }

    /**
     * 按id或id数组获取
     * @param $id
     * @param array $exclude_fields 不包含的字段
     * @param int $duration 缓存时间
     * @return array|false|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getById($id, $exclude_fields = [], $duration = {$table_comment['is_cache']})
    {
        if($duration == 0){
            return static::instance()->where([
                self::F_ID => is_array($id) ? ['in', $id] : $id
            ])->field(self::getAllFields($exclude_fields))->find();
        }else{
            if(is_array($id)){
                $items = [];
                foreach($id as $each_id){
                    $info = self::getById($each_id, $exclude_fields, $duration);
                    if(!empty($info)){
                        $items[] = $info;
                    }
                }
                return $items;
            }
            $info = static::instance()->cache([$id], $duration)->where([
                self::F_ID => $id
            ])->find();
            if(empty($info)){
                return [];
            }else{
                return ClArray::getByKeys($info, self::getAllFields($exclude_fields));
            }
        }
    }

    /**
     * 清除缓存
     * @param $id
     * @return bool
     */
    public static function getByIdRc($id){
        return ClCache::remove($id);
    }

    /**
     * 获取某个字段值
     * @param integer $id 主键
     * @param string $field 字段
     * @param string $default 默认值
     * @param bool $is_convert_to_int 是否转换为int
     * @return int|mixed|string
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getValueById($id, $field, $default = '', $is_convert_to_int = false)
    {
        if({$table_comment['is_cache']} > 0){
            $info = self::getById($id);
            if(empty($info)){
                return $default;
            }else{
                if($is_convert_to_int){
                    return intval($info[$field]);
                }else{
                    return $info[$field];
                }
            }
        }else{
            return static::instance()->where([
                self::F_ID => $id
            ])->value($field, $default, $is_convert_to_int);
        }
    }

}