<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\api\base;

use app\api\controller\ApiController;
use app\index\model\UrlShortModel;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClArray;

/**
 * 短网址 Base
 * Class UrlShort Base Api
 * @package app\api\base
 */
class UrlShortBaseApiController extends ApiController {

    /**
     * 获取返回例子
     * @return string
     */
    protected function getListReturnExample() {
        return '{"status":"api\/url_short\/getlist\/1","status_code":1,"limit":10,"offset":0,"total":10,"items":[{"id":"主键id","short_url":"短连接","true_url":"真实url","end_time":"超时时间，如果为0，则永不超时","end_time_show":"超时时间，如果为0，则永不超时","create_time":"创建时间","create_time_show":"创建时间"}]}';
    }

    /**
     * 列表
     * @throws \think\Exception
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getList() {
        $where = [];
        return $this->ar(1, $this->paging(UrlShortModel::instance(), $where, function ($return) {
            //拼接额外字段 & 格式化相关字段
            $return['items'] = UrlShortModel::forShow($return['items']);
            //返回
            return $return;
        }), static::getListReturnExample());
    }
    
    /**
     * 返回例子
     * @return string
     */
    protected function getReturnExample() {
        return '{"status":"api\/url_short\/get\/1","status_code":1,"info":{"id":"主键id","short_url":"短连接","true_url":"真实url","end_time":"超时时间，如果为0，则永不超时","end_time_show":"超时时间，如果为0，则永不超时","create_time":"创建时间","create_time_show":"创建时间"}}';
    }

    /**
     * 单个信息
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function get() {
        $id = get_param('id', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '主键id');
        //获取
        $info = UrlShortModel::getById($id);
        //拼接额外字段 & 格式化相关字段
        $info = UrlShortModel::forShow($info);
        return $this->ar(1, ['info' => $info], static::getReturnExample());
    }

    /**
     * 返回例子
     * @return string
     */
    protected function getByIdsReturnExample() {
        return '{"status":"api\/url_short\/getbyids\/1","status_code":1,"items":[{"id":"主键id","short_url":"短连接","true_url":"真实url","end_time":"超时时间，如果为0，则永不超时","end_time_show":"超时时间，如果为0，则永不超时","create_time":"创建时间","create_time_show":"创建时间"}]}';
    }

    /**
     * 多个信息
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getByIds() {
        $ids = get_param('ids', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->verifyArray()->fetchVerifies(), '主键id数组');
        //获取
        $items = UrlShortModel::getItemsByIds($ids);
        //拼接额外字段 & 格式化相关字段
        $items = UrlShortModel::forShow($items);
        return $this->ar(1, ['items' => $items], static::getByIdsReturnExample());
    }

    /**
     * 返回例子
     * @return string
     */
    protected function createReturnExample() {
        return '{"status":"api\/url_short\/create\/1","status_code":1,"info":{"id":"主键id","short_url":"短连接","true_url":"真实url","end_time":"超时时间，如果为0，则永不超时","end_time_show":"超时时间，如果为0，则永不超时","create_time":"创建时间","create_time_show":"创建时间"}}';
    }

    /**
     * 创建
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function create() {
        $fields = ClArray::getByKeys(input(), UrlShortModel::getAllFields());
        //创建
        UrlShortModel::instance()->insert($fields);
        //获取
        $info = UrlShortModel::getById(UrlShortModel::instance()->getLastInsID());
        //拼接额外字段 & 格式化相关字段
        $info = UrlShortModel::forShow($info);
        return $this->ar(1, ['info' => $info], static::createReturnExample());
    }

}