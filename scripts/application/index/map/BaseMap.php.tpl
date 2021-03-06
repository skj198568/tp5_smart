<?php
/**
 * Created by PhpStorm.
 * User: SongKeJing
 * Date: 2020/4/6 12:46
 */

namespace app\index\map;

use ClassLibrary\ClArray;
use ClassLibrary\ClCache;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClHttp;
use ClassLibrary\ClString;
use ClassLibrary\ClVerify;
use think\db\Connection;
use think\db\Query;
use think\Model;

/**
 * 基础Map，可在BaseModel中重写BaseMap中的方法
 * Class BaseMap
 * @package app\index\map
 */
class BaseMap extends Query {

    /**
     * 是否分表
     * @var bool
     */
    public $is_divide_table = false;

    /**
     * @var int 有效数字标识 1
     */
    const V_VALID = 1;

    /**
     * @var int 无效数字标识 0
     */
    const V_INVALID = 0;

    /**
     * @var string pk int(11)
     */
    const F_ID = 'id';

    /**
     * 逆序
     * @var string
     */
    const V_ORDER_DESC = 'DESC';

    /**
     * 正序
     * @var string
     */
    const V_ORDER_ASC = 'ASC';

    /**
     * 字段校验，用于字段内容判断
     * @var array
     */
    public static $fields_verifies = [];

    /**
     * 只读的字段，仅仅是创建的时候添加，其他地方均不可修改
     * @var array
     */
    public static $fields_read_only = [];

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
    protected static $fields_show_format = [];

    /**
     * 字段存储格式
     * @var array
     */
    public static $fields_store_format = [];

    /**
     * 默认值
     * @var array
     */
    protected static $fields_default_values = [];

    /**
     * 拼接域名
     * @var array
     */
    protected static $fields_append_domain = [];

    /**
     * 所有字段的注释
     */
    public static $fields_names = [];

    /**
     * 分表规则
     * @var array
     */
    public static $partition = [];

    /**
     * 操作-插入
     */
    const V_OPERATE_TYPE_INSERT = 'insert';

    /**
     * 操作-更新
     */
    const V_OPERATE_TYPE_UPDATE = 'update';

    /**
     * 是否可执行before trigger，备份数据不执行beforeInsert和beforeUpdate
     * @var bool
     */
    protected $is_can_exec_before_trigger = true;

    /**
     * 上次插入id
     * @var int
     */
    private $last_insert_id = 0;

    /**
     * 回调sql
     * @var string
     */
    private $trigger_sql = '';

    /**
     * 回调ids
     * @var array
     */
    private $trigger_id_or_ids = [];

    /**
     * 回调数据items
     * @var array
     */
    private $trigger_items = [];

    /**
     * 回调结果items
     * @var array
     */
    private $trigger_result_items = [];

    /**
     * 回调更新信息
     * @var array
     */
    private $trigger_update_info = [];

    /**
     * after insert 限制次数，0为不限制次数
     * @var int
     */
    private $trigger_after_insert_called_limit_times = 0;

    /**
     * after insert 当前调用次数
     * @var int
     */
    private $trigger_after_insert_called_current_times = 0;

    /**
     * after update 限制次数，0为不限制次数
     * @var int
     */
    private $trigger_after_update_called_limit_times = 0;

    /**
     * after update 当前调用次数
     * @var int
     */
    private $trigger_after_update_called_current_times = 0;

    /**
     * after delete 限制次数，0为不限制次数
     * @var int
     */
    private $trigger_after_delete_called_limit_times = 0;

    /**
     * after delete 当前调用次数
     * @var int
     */
    private $trigger_after_delete_called_current_times = 0;

    /**
     * remove cache 限制次数，0为不限制次数
     * @var int
     */
    private $trigger_remove_cache_called_limit_times = 0;

    /**
     * remove cache 当前调用次数
     * @var int
     */
    private $trigger_remove_cache_called_current_times = 0;

    /**
     * 构造函数
     * @access public
     * @param Connection $connection 数据库对象实例
     * @param Model $model 模型对象
     */
    public function __construct(Connection $connection = null, Model $model = null) {
        parent::__construct($connection, $model);
        //调用初始化函数
        $this->initialize();
    }

    /**
     * 初始化
     */
    public function initialize() {

    }

    /**
     * 回调设置数据
     * @param string $sql
     * @param array $ids
     * @param array $items
     */
    private function triggerSet($sql = '', $ids = [], $items = []) {
        $this->trigger_sql       = $sql;
        $this->trigger_id_or_ids = $ids;
        $this->trigger_items     = $items;
    }

    /**
     * 获取所有的字段
     * @param array $exclude_fields 不包含的字段
     * @return array
     */
    public static function getAllFields($exclude_fields = [self::F_ID]) {
        return [];
    }

    /**
     * 在插入之前，预处理插入的字段数据，如果想阻断插入，请return [];
     * @param array $info
     * @return array
     */
    protected function triggerBeforeInsert($info) {
        return $this->triggerBeforeDealDataForAppend($info);
    }

    /**
     * 处理拼接字段
     * @param $info
     * @return mixed
     */
    private function triggerBeforeDealDataForAppend($info) {
        foreach ($info as $k_info => $v_info) {
            if (in_array($k_info, static::$fields_append_domain)) {
                if (is_array($v_info)) {
                    foreach ($v_info as $k_v_info => $v_v_info) {
                        $v_info[$k_v_info] = str_replace(ClHttp::getServerDomain(), '', $v_v_info);
                    }
                    $info[$k_info] = $v_info;
                } else {
                    $info[$k_info] = str_replace(ClHttp::getServerDomain(), '', $v_info);
                }
            }
        }
        return $info;
    }

    /**
     * 在插入之后，处理其他关联业务
     * 如需获取影响的数据:$items = $this->triggerGetItems();
     */
    protected function triggerAfterInsert() {

    }

    /**
     * 设置triggerAfterInsert被调用次数
     * @param int $limit_times 0/不限制
     */
    public function triggerAfterInsertSetCalledLimitTimes($limit_times = 1) {
        $this->trigger_after_insert_called_limit_times = $limit_times;
    }

    /**
     * 在更新之前，预处理更新的字段数据，如果想阻断更新，请return [];
     * @param array $info
     * @return array
     */
    protected function triggerBeforeUpdate($info) {
        return $this->triggerBeforeDealDataForAppend($info);
    }

    /**
     * 在更新之后，处理其他关联业务
     * 如需获取影响的数据:$items = $this->triggerGetItems();
     * @param array $info 更改的字段数据
     */
    protected function triggerAfterUpdate($info) {

    }

    /**
     * 设置triggerAfterUpdate被调用次数
     * @param int $limit_times 0/不限制
     */
    public function triggerAfterUpdateSetLimitCalledTimes($limit_times = 1) {
        $this->trigger_after_update_called_limit_times = $limit_times;
    }

    /**
     * 在删除之后，处理其他关联业务
     * @param array $items
     */
    protected function triggerAfterDelete($items) {

    }

    /**
     * 设置triggerAfterDelete被调用次数
     * @param int $limit_times 0/不限制
     */
    public function triggerAfterDeleteSetLimitCalledTimes($limit_times = 1) {
        $this->trigger_after_delete_called_limit_times = $limit_times;
    }

    /**
     * 缓存清除器
     * 采用$items = $this->triggerGetItems();方式获取所有影响的数据
     */
    protected function triggerRemoveCache() {

    }

    /**
     * 设置triggerRemoveCache被调用次数
     * @param int $limit_times 0/不限制
     */
    public function triggerRemoveCacheSetCalledLimitTimes($limit_times = 1) {
        $this->trigger_remove_cache_called_limit_times = $limit_times;
    }

    /**
     * 缓存清除器调用
     */
    private function triggerRemoveCacheCall() {
        if ($this->trigger_remove_cache_called_limit_times == 0 || $this->trigger_remove_cache_called_current_times < $this->trigger_remove_cache_called_limit_times) {
            static::triggerRemoveCache();
            $this->trigger_remove_cache_called_current_times++;
        }
    }

    /**
     * 触发事件获取数据
     * @param string $sql
     * @param array $ids
     * @param array $items
     * @return array|false|mixed|\PDOStatement|string|\think\Collection|null
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     * @throws \think\exception\PDOException
     */
    protected function triggerGetItems() {
        $trigger_key = md5($this->trigger_sql . json_encode($this->trigger_id_or_ids) . json_encode($this->trigger_items));
        if (isset($this->trigger_result_items[$trigger_key])) {
            return $this->trigger_result_items[$trigger_key];
        }
        $default = [];
        if (count($this->trigger_items) > 0) {
            return $this->trigger_items;
        } elseif ($this->trigger_sql != '') {
            $items = $this->query($this->trigger_sql);
            //存储
            $this->trigger_result_items[$trigger_key] = $items;
            return $items;
        } elseif (is_array($this->trigger_id_or_ids)) {
            if (empty($this->trigger_id_or_ids)) {
                return $default;
            }
            $items = $this->where([
                'id' => ['in', $this->trigger_id_or_ids]
            ])->select();
            //存储
            $this->trigger_result_items[$trigger_key] = $items;
            return $items;
        } elseif (is_numeric($this->trigger_id_or_ids)) {
            $info  = $this->where([
                'id' => $this->trigger_id_or_ids
            ])->find();
            $items = [$info];
            //存储
            $this->trigger_result_items[$trigger_key] = $items;
            return $items;
        } else {
            return $default;
        }
    }

    /**
     * 默认处理数据
     * @param $data
     * @param $operate_type
     * @return array
     */
    private function getDataBeforeExecute($data, $operate_type) {
        //如果是备份数据，则忽略数据的处理及校验
        if (!$this->is_can_exec_before_trigger) {
            return $data;
        }
        //调用预处理
        if ($operate_type == 'insert') {
            $data = static::triggerBeforeInsert($data);
        } else if ($operate_type == 'update') {
            $data = static::triggerBeforeUpdate($data);
            //赋值
            $this->trigger_update_info = $data;
        }
        //非array数据，不进行处理
        if (!is_array($data) || empty($data)) {
            return $data;
        }
        if ($operate_type == self::V_OPERATE_TYPE_INSERT) {
            //添加默认值
            $data = array_merge(static::$fields_default_values, $data);
            //自动完成字段
            if (in_array('create_time', static::getAllFields())) {
                if (!isset($data['create_time']) || empty($data['create_time'])) {
                    $data['create_time'] = time();
                }
            }
        } else if ($operate_type == self::V_OPERATE_TYPE_UPDATE) {
            //自动完成字段
            if (in_array('update_time', static::getAllFields())) {
                if (!isset($data['update_time']) || empty($data['update_time'])) {
                    $data['update_time'] = time();
                }
            }
            //去除只读字段
            if (!empty(static::$fields_read_only)) {
                //默认更新接口，需要判断字段是否只读
                if (request()->action() === 'update' || request()->action() === 'create') {
                    foreach (static::$fields_read_only as $each_field) {
                        if (isset($data[$each_field])) {
                            unset($data[$each_field]);
                        }
                    }
                }
            }
        }
        //校验参数
        ClFieldVerify::verifyFields($data, static::$fields_verifies, $operate_type, $this->is_divide_table ? null : static::instance());
        //存储格式处理
        if (!empty(static::$fields_store_format)) {
            foreach (static::$fields_store_format as $k_field => $each_field_store_format) {
                if (isset($data[$k_field])) {
                    if (is_array($each_field_store_format)) {
                        switch ($each_field_store_format[0]) {
                            case 'password':
                                $data[$k_field] = md5($data[$k_field] . $each_field_store_format[1]);
                                break;
                        }
                    } else {
                        switch ($each_field_store_format) {
                            case 'json':
                                if (empty($data[$k_field])) {
                                    $data[$k_field] = [];
                                } else if (!is_array($data[$k_field])) {
                                    if (ClVerify::isJson($data[$k_field])) {
                                        $data[$k_field] = json_decode($data[$k_field], true);
                                    } else {
                                        $data[$k_field] = [$data[$k_field]];
                                    }
                                }
                                $data[$k_field] = json_encode($data[$k_field], JSON_UNESCAPED_UNICODE);
                                break;
                            case 'base64':
                                if (empty($data[$k_field])) {
                                    $data[$k_field] = '';
                                } else {
                                    $data[$k_field] = base64_encode($data[$k_field]);
                                }
                                break;
                        }
                    }
                }
            }
        }
        return $data;
    }

    /**
     * 重写execute方法，用于清除缓存
     * @param string $sql
     * @param array $bind
     * @return int
     * @throws \Exception
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function execute($sql, $bind = []) {
        //清空数据
        $this->trigger_items = [];
        $is_update           = strpos($sql, 'UPDATE') === 0;
        $is_delete           = strpos($sql, 'DELETE') === 0;
        if ($is_update || $is_delete) {
            //先查询，后执行
            $last_sql    = $this->connection->getRealSql($sql, $bind);
            $table_name  = substr($last_sql, strpos($last_sql, '`') + 1);
            $table_name  = substr($table_name, 0, strpos($table_name, '`'));
            $trigger_sql = sprintf('SELECT * FROM `%s` %s', $table_name, substr($last_sql, strpos($last_sql, 'WHERE')));
            $result      = parent::execute($sql, $bind);
            if ($is_delete) {
                $items = $this->query($trigger_sql);
                //设置数据
                $this->triggerSet('', [], $items);
                $this->triggerRemoveCacheCall();
                if ($this->trigger_after_delete_called_limit_times == 0 || $this->trigger_after_delete_called_current_times < $this->trigger_after_delete_called_limit_times) {
                    static::triggerAfterDelete($items);
                    $this->trigger_after_delete_called_current_times++;
                }
            } elseif ($is_update) {
                //设置数据
                $this->triggerSet($trigger_sql);
                $this->triggerRemoveCacheCall();
                if ($this->trigger_after_update_called_limit_times == 0 || $this->trigger_after_update_called_current_times < $this->trigger_after_update_called_limit_times) {
                    static::triggerAfterUpdate($this->trigger_update_info);
                    $this->trigger_after_update_called_current_times++;
                }
                //清除更新数据
                $this->trigger_update_info = [];
            }
            //清除缓存后执行
            ClCache::removeAfter();
        } else {
            //查询
            $result = parent::execute($sql, $bind);
        }
        return $result;
    }

    /**
     * 重写
     * @param array $data
     * @param bool $replace
     * @param bool $getLastInsID
     * @param null $sequence
     * @return int|string
     */
    public function insert(array $data = [], $replace = false, $getLastInsID = true, $sequence = null) {
        //预处理数据
        $data                 = $this->getDataBeforeExecute($data, 'insert');
        $last_id              = parent::insert($data, $replace, true, $sequence);
        $this->last_insert_id = $last_id;
        //设置数据
        $this->triggerSet('', $last_id);
        //处理数据
        if ($this->trigger_after_insert_called_limit_times == 0 || $this->trigger_after_insert_called_current_times < $this->trigger_after_insert_called_limit_times) {
            static::triggerAfterInsert();
            $this->trigger_after_insert_called_limit_times++;
        }
        //清缓存
        $this->triggerRemoveCacheCall();
        //清除缓存后执行
        ClCache::removeAfter();
        return $last_id;
    }

    /**
     * 获取最近插入的ID
     * @access public
     * @param string $sequence 自增序列名
     * @return string
     */
    public function getLastInsID($sequence = null) {
        $id = $this->connection->getLastInsID($sequence);
        if (empty($id)) {
            $id = $this->last_insert_id;
        }
        return $id;
    }

    /**
     * 批量插入记录
     * @access public
     * @param mixed $dataSet 数据集
     * @param boolean $replace 是否replace
     * @param integer $limit 每次写入数据限制
     * @return integer|string
     */
    public function insertAll(array $dataSet, $replace = false, $limit = null) {
        //校验参数
        foreach ($dataSet as $k_data => $data) {
            //预处理数据
            $data = $this->getDataBeforeExecute($data, 'insert');
            //替换数据
            $dataSet[$k_data] = $data;
        }
        $result         = parent::insertAll($dataSet, $replace, $limit);
        $insert_ids     = [];
        $last_insert_id = $this->getLastInsID();
        if ($last_insert_id) {
            for ($i = $last_insert_id - count($dataSet); $i < $last_insert_id; $i++) {
                $insert_ids[] = $i;
            }
        }
        $this->triggerSet('', $insert_ids);
        //处理数据
        if ($this->trigger_after_insert_called_limit_times == 0 || $this->trigger_after_insert_called_current_times < $this->trigger_after_insert_called_limit_times) {
            static::triggerAfterInsert();
            $this->trigger_after_insert_called_current_times++;
        }
        //清缓存
        $this->triggerRemoveCacheCall();
        //清除缓存后执行
        ClCache::removeAfter();
        return $result;
    }

    /**
     * 重写update方法
     * @param array $data
     * @return int|string
     * @throws \think\Exception
     * @throws \think\exception\PDOException
     */
    public function update(array $data = []) {
        //预处理数据
        $data = $this->getDataBeforeExecute($data, 'update');
        return parent::update($data);
    }

    /**
     * 拼接额外展现字段
     * @param array $items
     * @return array|mixed
     */
    private static function showMapFields($items) {
        if (empty($items)) {
            return $items;
        }
        if (empty(static::$fields_show_map_fields)) {
            return $items;
        }
        $is_linear_array = false;
        //一维数组，处理成多维数组
        if (ClArray::isLinearArray($items)) {
            $items           = [$items];
            $is_linear_array = true;
        }
        //查询结果值
        $search_values = [];
        //额外字段拼接
        foreach (static::$fields_show_map_fields as $field => $map_fields) {
            foreach ($items as $k => $each) {
                if (isset($each[$field])) {
                    foreach ($map_fields as $each_map_field) {
                        $table_and_field = $each_map_field[0];
                        $alias           = $each_map_field[1];
                        $fetch_field     = ClString::getBetween($table_and_field, '.', '', false);
                        $table_name      = ClString::getBetween($table_and_field, '', '.', false);
                        if (strpos($table_name, '_') !== false) {
                            $table_name = explode('_', $table_name);
                            foreach ($table_name as $k_table_name => $each_table_and_field) {
                                $table_name[$k_table_name] = ucfirst($each_table_and_field);
                            }
                            $model = implode('', $table_name);
                        } else {
                            $model = ucfirst($table_name);
                        }
                        //拼接Model
                        $model .= 'Model';
                        if (is_array($each[$field])) {
                            $each[$alias] = [];
                            foreach ($each[$field] as $each_field) {
                                //考虑性能，对查询结果进行缓存
                                $key = sprintf('app\index\model\%s::getValueById(%s, %s)', $model, $each_field, $fetch_field);
                                if (!isset($search_values[$key])) {
                                    $search_values[$key] = call_user_func_array([sprintf('app\index\model\%s', $model), 'getValueById'], [$each_field, $fetch_field]);
                                }
                                //获取信息
                                $each[$alias][] = $search_values[$key];
                            }
                        } else {
                            //考虑性能，对查询结果进行缓存
                            $key = sprintf('app\index\model\%s::getValueById(%s, %s)', $model, $each[$field], $fetch_field);
                            if (!isset($search_values[$key])) {
                                $search_values[$key] = call_user_func_array([sprintf('app\index\model\%s', $model), 'getValueById'], [$each[$field], $fetch_field]);
                            }
                            //获取信息
                            $each[$alias] = $search_values[$key];
                        }
                    }
                }
                $items[$k] = $each;
            }
        }
        if ($is_linear_array) {
            return $items[0];
        } else {
            return $items;
        }
    }

    /**
     * 不可见字段去除
     * @param array $items
     * @return array|mixed
     */
    private static function showInvisible($items) {
        if (empty($items)) {
            return $items;
        }
        if (empty(static::$fields_invisible)) {
            return $items;
        }
        $is_linear_array = false;
        //一维数组，处理成多维数组
        if (ClArray::isLinearArray($items)) {
            $items           = [$items];
            $is_linear_array = true;
        }
        foreach ($items as $k => $v) {
            foreach (static::$fields_invisible as $each_key) {
                if (array_key_exists($each_key, $v)) {
                    unset($items[$k][$each_key]);
                }
            }
        }
        if ($is_linear_array) {
            return $items[0];
        } else {
            return $items;
        }
    }

    /**
     * 自动拼接域名
     * @param $value
     * @return string
     */
    public static function autoAppendDomain($value) {
        if (empty($value)) {
            return $value;
        }
        $domain = ClHttp::getServerDomain();
        if (!ClVerify::hasHtmlTag($value)) {
            if (strpos($value, 'http') === 0) {
                return $value;
            }
            //单条记录，拼接域名
            $value = $domain . $value;
        } else {
            //富文本内容，批量替换
            $value = str_replace(['src="/', 'href="/'], ['src="' . $domain . '/', 'href="' . $domain . '/'], $value);
        }
        return $value;
    }

    /**
     * 字段格式化
     * @param array $items
     * @return array|mixed
     */
    private static function showFormat($items) {
        if (empty($items)) {
            return $items;
        }
        if (empty(static::$fields_show_format)) {
            return $items;
        }
        $is_linear_array = false;
        //一维数组，处理成多维数组
        if (ClArray::isLinearArray($items)) {
            $items           = [$items];
            $is_linear_array = true;
        }
        foreach ($items as $k => $item) {
            foreach (static::$fields_show_format as $k_format_key => $each_format) {
                if (!isset($item[$k_format_key])) {
                    continue;
                }
                foreach ($each_format as $each_format_item) {
                    if (is_string($each_format_item[0]) && strpos($each_format_item[0], '%s') !== false) {
                        //函数型格式化
                        if (!is_numeric($item[$k_format_key]) && empty($item[$k_format_key])) {
                            //如果为空，则取消格式化
                            $item[$k_format_key . $each_format_item[1]] = '';
                        } else {
                            if (empty($item[$k_format_key])) {
                                $item[$k_format_key . $each_format_item[1]] = '';
                            } else {
                                $format_string = sprintf('%s;', sprintf($each_format_item[0], $item[$k_format_key]));
                                $function      = ClString::getBetween($format_string, '', '(', false);
                                $params        = ClString::getBetween($format_string, '(', ')', false);
                                if (strpos($params, ',') !== false) {
                                    $params = explode(',', $params);
                                } else {
                                    $params = [$params];
                                }
                                $item[$k_format_key . $each_format_item[1]] = trim(call_user_func_array($function, $params), "''");
                            }
                        }
                    } else {
                        //数组式格式化
                        if (!is_numeric($item[$k_format_key]) && empty($item[$k_format_key])) {
                            //如果为空，则取消格式化
                            $item[$k_format_key . $each_format_item[1]] = '';
                        } else {
                            foreach ((array)$each_format_item[0] as $each_format_item_each) {
                                if ($each_format_item_each[0] == $item[$k_format_key]) {
                                    $item[$k_format_key . $each_format_item[1]] = $each_format_item_each[1];
                                    //退出循环
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            //拼接域名
            foreach (static::$fields_append_domain as $append_field) {
                foreach ($item as $field_key => $field_value) {
                    if ($field_key == $append_field) {
                        if (is_array($field_value)) {
                            //数组存储字段
                            foreach ($field_value as $field_value_key => $field_value_value) {
                                $field_value[$field_value_key] = static::autoAppendDomain($field_value_value);
                            }
                            //覆盖
                            $item[$field_key] = $field_value;
                        } else {
                            $item[$field_key] = static::autoAppendDomain($field_value);
                        }
                    }
                }
            }
            $items[$k] = $item;
        }
        if ($is_linear_array) {
            return $items[0];
        } else {
            return $items;
        }
    }

    /**
     * 重写cache方法，用于控制缓存的key
     * @param bool|mixed|array $key
     * @param null $expire
     * @param null $tag
     * @return $this
     */
    public function cache($key = true, $expire = null, $tag = null) {
        if (is_null($expire)) {
            if (is_numeric($key)) {
                $key    = call_user_func_array(['\ClassLibrary\ClCache', 'getKey'], []);
                $expire = $key;
            } else {
                $key = false;
            }
        } else {
            $key = call_user_func_array(['\ClassLibrary\ClCache', 'getKey'], !is_array($key) ? [$key] : $key);
        }
        parent::cache($key, $expire, $tag);
        return $this;
    }

    /**
     * 拼接额外字段 & 格式化字段
     * @param $items
     * @param BaseMap|null $model_instance
     * @param null $duration
     * @return array|array[]|mixed
     */
    public static function forShow($items, BaseMap $model_instance = null, $duration = null) {
        if (is_numeric($duration)) {
            $key         = ClCache::getKey([$model_instance->getTable(), 'for_show', $items]);
            $cache_items = cache($key);
            if ($cache_items === false) {
                $cache_items = self::showFormat(self::showInvisible(self::showMapFields($items)));
                //缓存
                cache($key, $cache_items, $duration);
            }
            $items = $cache_items;
        } else {
            $items = self::showFormat(self::showInvisible(self::showMapFields($items)));
        }
        return $items;
    }

    /**
     * 查询之后处理数据
     * @param array $info
     * @return array
     */
    protected function triggerAfterQuery($info) {
        //不进行处理
        if (!is_array($info) || empty($info)) {
            return $info;
        }
        //存储格式处理
        if (!empty(static::$fields_store_format)) {
            foreach (static::$fields_store_format as $k_field => $each_field_store_format) {
                if (isset($info[$k_field])) {
                    if (is_string($each_field_store_format)) {
                        switch ($each_field_store_format) {
                            case 'json':
                                if (empty($info[$k_field])) {
                                    $info[$k_field] = [];
                                } else {
                                    $info[$k_field] = json_decode($info[$k_field], true);
                                    if (is_null($info[$k_field])) {
                                        $info[$k_field] = [];
                                    }
                                }
                                break;
                            case 'base64':
                                if (empty($info[$k_field])) {
                                    $info[$k_field] = '';
                                } else {
                                    $info[$k_field] = base64_decode($info[$k_field]);
                                    if ($info[$k_field] == false) {
                                        $info[$k_field] = '';
                                    }
                                }
                                break;
                        }
                    }
                }
            }
        }
        return $info;
    }

    /**
     * 重写select
     * @param null $data
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function select($data = null) {
        $data = parent::select($data);
        if (empty($data)) {
            return [];
        }
        if (is_array($data)) {
            foreach ($data as $k => $each) {
                //预处理数据
                $data[$k] = $this->triggerAfterQuery($each);
            }
        }
        return $data;
    }

    /**
     * 重写find
     * @param null $data
     * @return array|false|null|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function find($data = null) {
        $data = parent::find($data);
        if (empty($data)) {
            return [];
        }
        //预处理数据
        return $this->triggerAfterQuery($data);
    }

    /**
     * 重写value
     * @param string $field
     * @param null $default
     * @param bool $force
     * @return mixed
     */
    public function value($field, $default = null, $force = false) {
        $value = parent::value($field, $default, $force);
        //转换成数组进行处理
        $value = $this->triggerAfterQuery([$field => $value]);
        //取数据
        return $value[$field];
    }

    /**
     * 重写column
     * @param string $field
     * @param string $key
     * @return array
     */
    public function column($field, $key = '') {
        $data = parent::column($field, $key);
        foreach ($data as $key => $value) {
            //转换成数组进行处理
            $value = $this->triggerAfterQuery([$field => $value]);
            //替换
            $data[$key] = $value[$field];
        }
        return $data;
    }

    /**
     * 校验密码的正确性
     * @param string $db_store_password 数据库存储的真实密码
     * @param string $user_input_password 用户输入的待校验的密码
     * @param string $field_name 字段名称，如果为空，则从所有字段存储中判断，不为空，则直接获取到存储格式
     * @return bool
     */
    public static function verifyPassword($db_store_password, $user_input_password, $field_name = '') {
        if (!empty($field_name)) {
            if (!isset(static::$fields_store_format[$field_name])) {
                //不存在存储格式
                return false;
            }
            $store_format = static::$fields_store_format[$field_name];
            if (is_array($store_format) && $store_format[0] == 'password') {
                //返回比较结果
                return $db_store_password == md5($user_input_password . $store_format[1]);
            }
        } else {
            foreach (static::$fields_store_format as $each_field => $each_field_store_format) {
                if (is_array($each_field_store_format) && $each_field_store_format[0] == 'password') {
                    //返回比较结果
                    return $db_store_password == md5($user_input_password . $each_field_store_format[1]);
                }
            }
        }
        return false;
    }

    /**
     * 表是否存在
     * @param string $table_name_with_prefix
     * @return bool
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function tableIsExist($table_name_with_prefix = '') {
        if (empty($table_name_with_prefix)) {
            $table_name_with_prefix = $this->table;
        }
        $key = 'TABLE_IS_EXIST_' . $table_name_with_prefix;
        if (!cache($key)) {
            //判断是否有此表
            $tables = $this->query("SHOW TABLES LIKE '$table_name_with_prefix'");
            if (empty($tables)) {
                //创建表
                return false;
            }
            //记录
            cache($key, 1);
        }
        return true;
    }

    /**
     * 复制表
     * @param string $source_table_name_with_prefix
     * @param string $new_table_name_with_prefix
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function tableCopy($source_table_name_with_prefix, $new_table_name_with_prefix) {
        if ($this->tableIsExist($source_table_name_with_prefix) && !$this->tableIsExist($new_table_name_with_prefix)) {
            //创建表
            $this->execute("CREATE TABLE `$new_table_name_with_prefix` LIKE `$source_table_name_with_prefix`");
        }
    }

    /**
     * 释放数据表信息
     */
    public static function tableInfoFree() {
        self::$info = [];
    }

    /**
     * 清空表
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function tableTruncate() {
        if ($this->tableIsExist($this->table)) {
            //清空表
            $this->execute("TRUNCATE TABLE `$this->table`");
        }
    }

    /**
     * 批量更新
     * @param array $new_data 新数据数组，例：[['id' => 1, 'price' => 90],['id' => 2, 'price' => 10]]
     * @param array $old_data 原数据数组，例：[['id' => 1, 'price' => 100],['id' => 2, 'price' => 90]]
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function updateBatch($new_data, $old_data) {
        if (!is_array($new_data) || !is_array($old_data)) {
            return;
        }
        if (empty($new_data) || empty($old_data)) {
            return;
        }
        $where_ids = array_column($new_data, 'id');
        $updates   = $this->updateBatchParseData($new_data, $old_data);
        $where_ids = implode(',', $where_ids);
        $sql       = sprintf("UPDATE `%s` SET %sWHERE `id` IN (%s)", $this->getTable(), $updates, $where_ids);
        //执行sql
        $this->execute($sql);
    }

    /**
     * 批量更新 将二维数组转换成CASE WHEN THEN的批量更新条件
     * @param $new_items
     * @param $old_items
     * @return string
     */
    private function updateBatchParseData($new_items, $old_items) {
        $sql  = '';
        $keys = array_keys(current($new_items));
        foreach ($keys as $field) {
            if ($field == 'id') {
                //忽略主键
                continue;
            }
            $sql .= sprintf("`%s` = \nCASE `%s` \n", $field, $field);
            foreach ($new_items as $new_item) {
                foreach ($new_item as $column => $value) {
                    if ($column == 'id') {
                        //忽略主键
                        continue;
                    }
                    foreach ($old_items as $old_item) {
                        foreach ($old_item as $old_column => $old_value) {
                            if ($column == $old_column && $new_item['id'] == $old_item['id']) {
                                $sql .= sprintf("WHEN '%s' THEN '%s' \n", $old_value, $value);
                                break 2;
                            }
                        }
                    }
                }
            }
            $sql .= "END \n,";
        }
        return rtrim($sql, ',');
    }

    /**
     * 设置迁移数据状态，不可执行before和after动作
     */
    public function setMoveDataBegin() {
        $this->is_can_exec_before_trigger = false;
        self::triggerAfterInsertSetCalledLimitTimes(-1);
        self::triggerAfterUpdateSetLimitCalledTimes(-1);
        self::triggerAfterDeleteSetLimitCalledTimes(-1);
        self::triggerRemoveCacheSetCalledLimitTimes(-1);
    }

    /**
     * 设置迁移数据状态，恢复可执行before和after动作
     */
    public function setMoveDataEnd() {
        $this->is_can_exec_before_trigger = true;
        self::triggerAfterInsertSetCalledLimitTimes(0);
        self::triggerAfterUpdateSetLimitCalledTimes(0);
        self::triggerAfterDeleteSetLimitCalledTimes(0);
        self::triggerRemoveCacheSetCalledLimitTimes(0);
    }

}