<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\index\map;

use app\index\model\BaseModel;
use ClassLibrary\ClArray;
use ClassLibrary\ClCache;
use think\Exception;

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
    protected $table = '';

    /**
     * 带有命名空间的任务调用地址
     * Type: varchar(1000)
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
        self::F_COMMAND => ["is_required",["length_max",1000]], 
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
    public static $fields_store_format = [];

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
     * 初始化
     */
    public function initialize() {
        parent::initialize();
        //设置表名
        $this->table = config('database.prefix') . 'task';
    }

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
        if (is_numeric(null) && isset($item[static::F_ID])) {
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
    public static function getItemsByIds($ids, $sort_field = '', $sort_type = self::V_ORDER_ASC, $exclude_fields = [], $duration = null) {
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
     * 处理任务
     * @param int $id 执行的id
     * @return bool
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function deal($id = 0) {
        //处理数据
        if ($id == 0) {
            $item = self::instance()->where([
                self::F_START_TIME => 0
            ])->order([self::F_ID => self::V_ORDER_ASC])->find();
            if (empty($item)) {
                return true;
            }
        } else {
            $item = self::getById($id);
        }
        //设置正在执行
        self::instance()->where([
            self::F_ID => $item[self::F_ID]
        ])->setField([
            self::F_START_TIME => time()
        ]);
        //执行
        log_info('task-start-' . $item[self::F_ID]);
        try {
            eval($item[self::F_COMMAND]);
            //设置执行的结束时间
            self::instance()->where([
                self::F_ID => $item[self::F_ID]
            ])->setField([
                self::F_END_TIME => time()
            ]);
        } catch (Exception $e) {
            $error_msg = json_encode([
                'message' => $e->getMessage(),
                'file'    => $e->getFile(),
                'line'    => $e->getLine(),
                'code'    => $e->getCode()
            ], JSON_UNESCAPED_UNICODE);
            self::instance()->where([
                self::F_ID => $item[self::F_ID]
            ])->setField([
                self::F_REMARK => $error_msg
            ]);
            log_info('task-error', $error_msg);
            if ($id > 0) {
                echo_info('task-error', $error_msg);
            }
        }
        //结束
        log_info('task-end-' . $item[self::F_ID]);
        return true;
    }

    /**
     * 创建任务
     * @param string $command 类似任务命令:app\index\model\AdminLoginLogModel::sendEmail();
     * @param int $within_seconds_ignore_this_cmd 在多长时间内忽略该任务，比如某些不需要太精确的统计任务，可以设置为60秒，即60秒内只执行一次任务
     * @return bool|int|string
     */
    public static function createTask($command, $within_seconds_ignore_this_cmd = 0) {
        $is_insert = true;
        if ($within_seconds_ignore_this_cmd > 0) {
            $last_create_time = self::instance()->where([
                self::F_COMMAND => $command
            ])->order([self::F_ID => self::V_ORDER_DESC])->value(self::F_CREATE_TIME);
            if (!is_numeric($last_create_time) || time() - $last_create_time > $within_seconds_ignore_this_cmd) {
                $is_insert = true;
            } else {
                $is_insert = false;
            }
        }
        if ($is_insert) {
            //新增
            return self::instance()->insert([
                self::F_COMMAND => $command
            ]);
        } else {
            return false;
        }
    }

}