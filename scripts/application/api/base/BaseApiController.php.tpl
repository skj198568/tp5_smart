<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/12/15
 * Time: 11:04
 */

namespace app\api\base;

use app\index\model\BaseModel;
use ClassLibrary\ClCache;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClString;
use ClassLibrary\ClVerify;
use think\App;
use think\Controller;

/**
 * 基础api
 * Class BaseApiController
 * @package app\api\base
 */
class BaseApiController extends Controller {

    /**
     * 不校验的请求
     * @var array
     */
    protected $default_uncheck_request = [
        'Index/index',
        'UrlShort/jump',
        'File/uploadFile',
        'File/img',
        'File/delete',
    ];

    /**
     * 被锁的key，防止用户多次请求
     * @var array
     */
    protected $locked_key = [];

    /**
     * 初始化函数
     */
    public function _initialize() {
        parent::_initialize();
        if (App::$debug) {
            log_info('input:', input());
            ini_set('display_errors', 'On');
            ini_set("error_reporting", E_ALL);
        }
        try {
            $id = input('id', 0);
        } catch (\InvalidArgumentException $exception) {
            //可能为数组参数，忽略处理
            $id = 0;
        }
        if ($id > 0) {
            //存在id
            $lock_key          = $this->getLockKey($id);
            $last_request_time = cache($lock_key);
            //同一时间请求
            if ($last_request_time !== false) {
                $response = $this->ar(-4, '请勿重复请求');
                $response->send();
                exit;
            }
            //缓存
            cache($lock_key, time(), 3);
            //存储
            $this->locked_key[] = $lock_key;
        }
    }

    /**
     * 获取lock key
     * @param $id
     * @return string
     */
    protected function getLockKey($id) {
        return implode('_', [request()->module(), request()->controller(), request()->action(), $id, session_id()]);
    }

    /**
     * 返回信息
     * @param int $code 返回码
     * @param array $data 返回的值，如果传入为字符串，则默认该字符串为返回message信息内容
     * @param string $example 例子，用于自动生成api文档
     * @param bool $is_log
     * @return \think\response\Json|\think\response\Jsonp
     */
    protected function ar($code, $data = [], $example = '', $is_log = false) {
        $status = sprintf('%s/%s/%s/%s', request()->module(), request()->controller(), request()->action(), $code);
        //格式化
        $status = ClString::toArray($status);
        foreach ($status as $k_status => $v_status) {
            if (ClVerify::isAlphaCapital($v_status)) {
                $status[$k_status] = '_' . strtolower($v_status);
            }
        }
        //转换为字符串
        $status = implode('', $status);
        $status = str_replace('/_', '/', $status);
        $data   = is_array($data) ? $data : ['message' => $data];
        //清掉locked_key
        foreach ($this->locked_key as $each_locked_key) {
            cache($each_locked_key, null);
        }
        return json_return(array_merge([
            'status'      => $status,
            'status_code' => $code
        ], $data), $is_log);
    }

    /**
     * 分页数据构建
     * @param $model_instance
     * @param array|object $where
     * @param string $call_back 回调函数
     * @param array $exclude_fields 不包含的字段
     * @param int $limit 每页显示数
     * @param null|int $duration 缓存时间
     * @return array
     * @throws \think\Exception
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    protected function paging(BaseModel $model_instance, $where, $call_back = '', $exclude_fields = [], $limit = PAGES_NUM, $duration = null) {
        $limit  = get_param('limit', ClFieldVerify::instance()->verifyNumber()->fetchVerifies(), '每页显示数量，默认15条', $limit);
        $total  = get_param('total', ClFieldVerify::instance()->verifyNumber()->fetchVerifies(), '总数，默认为0', 0);
        $offset = get_param('offset', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '偏移数量，默认0', 0);
        $order  = get_param('order', ClFieldVerify::instance()->verifyInArray(['asc', 'desc'])->fetchVerifies(), '排序， ["asc"， "desc"]任选其一，默认为asc', 'asc');
        $sort   = get_param('sort', ClFieldVerify::instance()->fetchVerifies(), '排序值，默认为表的主键id，如果多个字段排序请用英文逗号分隔', $model_instance->getPk());
        //默认返回值
        $return      = [
            'limit'  => $limit,
            'offset' => $offset,
            'total'  => $total
        ];
        $order_array = [];
        if (strpos($sort, ',') !== false) {
            $sorts = explode(',', $sort);
        } else {
            $sorts = [$sort];
        }
        foreach ($sorts as $sort) {
            $order_array[$sort] = $order;
        }
        //列表
        $return['items'] = $model_instance
            ->cache([$model_instance->getTable(), $where, $exclude_fields, $order, $offset, $limit, $duration, 'items'], $duration)
            ->where($where)
            ->field($model_instance::getAllFields($exclude_fields))
            ->order($order_array)
            ->limit($offset, $limit)
            ->select();
        //总数
        if (empty($total)) {
            $total_key   = '';
            $total_count = null;
            if ($duration > 0) {
                //尝试从缓存中获取
                $total_key   = ClCache::createKeyByParams([$where, $exclude_fields, $order, $offset, $limit, $duration, 'total']);
                $total_count = cache($total_key);
                if ($total_count === false) {
                    $total_count = null;
                }
            }
            if ($total_count == null) {
                //上次sql
                $last_sql = $model_instance->getLastSql();
                if (strpos($last_sql, 'SELECT ') === false) {
                    //sql不正确，则拼接一次sql
                    $last_sql = $model_instance
                        ->where($where)
                        ->field($model_instance::getAllFields($exclude_fields))
                        ->order($order_array)
                        ->limit($offset, $limit)
                        ->fetchSql(true)
                        ->select();
                }
                //拼接total sql
                $total_sql = 'SELECT COUNT(1) AS all_count FROM ' . ClString::getBetween($last_sql, 'FROM ', ' ORDER', false);
                //获取总数
                $total_count = $model_instance->query($total_sql);
                if (empty($total_count)) {
                    $total_count = 0;
                } else {
                    $total_count = $total_count[0]['all_count'];
                }
                if ($duration > 0) {
                    //存储，多加10秒进行时间差保障
                    cache($total_key, $total_count, $duration);
                }
            }
            $return['total'] = $total_count;
        }
        //回调函数处理
        if (!empty($call_back) && gettype($call_back) == 'object') {
            $return = $call_back($return);
        }
        return $return;
    }

    /**
     * 空内容的返回
     * @return array
     */
    protected function pagingGetEmptyReturn() {
        return [
            'limit'  => PAGES_NUM,
            'offset' => 0,
            'total'  => 0,
            'items'  => []
        ];
    }

    /**
     * 空请求
     * @return string
     */
    public function _empty() {
        if (!App::$debug) {
            //非debug
            return '<h1 style="text-align: center;font-size: 5em;">404</h1>';
        }
        if (strtolower(request()->controller() . DS . request()->action()) != 'index' . DS . 'index') {
            //非首页
            return '<h1 style="text-align: center;font-size: 5em;">404</h1>';
        }
        $t = get_param('t', [], '时间戳', 0);
        if ($t == 0 || $t < time() - 3) {
            $this->redirect('/api?t=' . time());
        }
        $api_file             = DOCUMENT_ROOT_PATH . '/../doc/api/index.html';
        $api_file_create_time = 0;
        if (is_file($api_file)) {
            $api_file_create_time = filectime($api_file);
        }
        //获取所有controller文件
        $controller_files       = ClFile::dirGetFiles(__DIR__ . '/../controller', [], ['ApiController.php']);
        $max_modify_create_time = 0;
        foreach ($controller_files as $controller_file) {
            $file_create_time = filectime($controller_file);
            if ($file_create_time > $max_modify_create_time) {
                $max_modify_create_time = $file_create_time;
            }
        }
        if ($max_modify_create_time > $api_file_create_time) {
            if (!function_exists('exec')) {
                return 'function "exec" is not exist';
            }
            //重新生成api文档
            $cmd = sprintf('cd %s && php think api_doc', DOCUMENT_ROOT_PATH . '/../');
            exec($cmd);
        }
        //直接输出
        return $this->fetch($api_file);
    }

}