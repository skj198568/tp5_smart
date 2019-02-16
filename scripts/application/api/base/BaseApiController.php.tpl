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
use ClassLibrary\ClFieldVerify;
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
    ];

    /**
     * 初始化函数
     */
    public function _initialize() {
        parent::_initialize();
        if (App::$debug) {
            log_info('$_REQUEST:', request()->request());
        }
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
        $sort   = get_param('sort', ClFieldVerify::instance()->verifyAlphaNumDash()->fetchVerifies(), '排序值，默认为表的主键id', $model_instance->getPk());
        //默认返回值
        $return = [
            'limit'  => $limit,
            'offset' => $offset,
            'total'  => $total
        ];
        //列表
        $return['items'] = $model_instance
            ->cache([$model_instance->getTable(), $where, $exclude_fields, $order, $offset, $limit, 'items'], $duration)
            ->where($where)
            ->field($model_instance::getAllFields($exclude_fields))
            ->order([
                $sort => $order
            ])
            ->limit($offset, $limit)
            ->select();
        //总数
        if (empty($total)) {
            //上次sql
            $last_sql = $model_instance->getLastSql();
            //拼接total sql
            $total_sql = 'SELECT COUNT(*) FROM ' . ClString::getBetween($last_sql, 'FROM', 'ORDER', false);
            //获取总数
            $total_count = $model_instance->cache([$model_instance->getTable(), $where, $exclude_fields, $order, $offset, $limit, 'items'], $duration)->query($total_sql);
            if (empty($total_count)) {
                $total_count = 0;
            } else {
                $total_count = $total_count[0]['COUNT(*)'];
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

}