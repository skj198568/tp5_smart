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
use ClassLibrary\ClVerify;
use think\App;
use think\Controller;

/**
 * 基础api
 * Class BaseApiController
 * @package app\api\base
 */
class BaseApiController extends Controller
{

    /**
     * 初始化函数
     */
    public function _initialize()
    {
        parent::_initialize();
        if (App::$debug) {
            log_info('$_REQUEST:', request()->request());
        }
    }

    /**
     * 返回信息
     * @param int $code 返回码
     * @param array $data 返回的值
     * @param string $example 例子，用于自动生成api文档
     * @param bool $is_log
     * @return \think\response\Json|\think\response\Jsonp
     */
    protected function ar($code, $data = [], $example = '', $is_log = false)
    {
        $status = sprintf('%s-%s-%s-%s', request()->module(), request()->controller(), request()->action(), $code);
        //转小写
        $status = strtolower($status);
        $data = is_array($data) ? $data : [$data];
        //是否包含
        $api_include_example = get_param('api_include_example', ClFieldVerify::instance()->verifyNumber()->verifyInArray([0, 1])->fetchVerifies(), '返回值是否包含例子', 0);
        if($api_include_example != 0){
            if(!empty($example)){
                $example = trim($example);
                $example = str_replace(["\t", "\n"], ['', ''], $example);
            }
            //解码为数组
            $example = json_decode($example, true);
            if(!isset($data['example'])){
                $data['example'] = $example;
            }else{
                $data['example_'.rand(1, 99)] = $example;
            }
        }
        //本地请求，自动记录
        if(ClVerify::isLocalIp()){
            $is_log = true;
        }
        return json_return(array_merge([
            'status' => $status,
        ], $data), $is_log);
    }

    /**
     * 分页数据构建
     * @param $model_instance
     * @param $where
     * @param string $call_back 回调函数
     * @param array $exclude_fields 不包含的字段
     * @param int $limit 每页显示数
     * @param null|int $duration 缓存时间
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    protected function paging(BaseModel $model_instance, $where, $call_back = '', $exclude_fields = [], $limit = PAGES_NUM, $duration = null)
    {
        $limit = get_param('limit', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '每页显示数量', $limit);
        $total = get_param('total', ClFieldVerify::instance()->verifyNumber()->fetchVerifies(), '总数，默认为0', 0);
        $page = get_param('page', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '当前页码数', 1);
        $order = get_param('order', ClFieldVerify::instance()->verifyInArray(['asc', 'desc'])->fetchVerifies(), '排序， ["asc"， "desc"]任选其一，默认为"asc"', 'asc');
        $sort = get_param('sort', ClFieldVerify::instance()->verifyAlphaNumDash()->fetchVerifies(), '排序值，默认为表的主键', $model_instance->getPk());
        $return = [
            'limit' => $limit,
            'page' => $page,
            'total' => $total
        ];
        $return['items'] = $model_instance
            ->cache([$model_instance->getTable(), $where, $exclude_fields, $order, $page, $limit, 'items'], $duration)
            ->where($where)
            ->field($model_instance::getAllFields($exclude_fields))
            ->order([
                $sort => $order
            ])
            ->page($page)
            ->limit($limit)
            ->select();
        if (!empty($call_back) && gettype($call_back) == 'object') {
            $return['items'] = $call_back($return['items']);
        }
        if (empty($total)) {
            $return['total'] = $model_instance
                ->cache([$model_instance->getTable(), $where, $order, $page, $limit, 'total'], $duration)
                ->where($where)
                ->count();
        }
        return $return;
    }

}