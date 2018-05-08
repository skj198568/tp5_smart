<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\api\base;

use app\api\controller\ApiController;
use app\index\model\AreaModel;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClArray;

/**
 * 地址信息 Base
 * Class Area Base Api
 * @package app\api\base
 */
class AreaBaseApiController extends ApiController {

    /**
     * 列表
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getList() {
        $where = [];
        return $this->ar(1, $this->paging(AreaModel::instance(), $where, function ($return) {
            //拼接额外字段 & 格式化相关字段
            $return['items'] = AreaModel::forShow($return['items']);
            //返回
            return $return;
        }), '{"status":"api\/area\/getlist\/1","limit":10,"offset":0,"total":10,"items":[{"id":"主键id","name":"名称","f_id":"父类id","type":"类型，1\/省、直辖市，2\/城市，3\/区县: 1\/省\/直辖市; 2\/城市; 3\/区县;"}]}');
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
        $info = AreaModel::getById($id);
        //拼接额外字段 & 格式化相关字段
        $info = AreaModel::forShow($info);
        return $this->ar(1, ['info' => $info], '{"status":"api\/area\/get\/1","info":{"id":"主键id","name":"名称","f_id":"父类id","type":"类型，1\/省、直辖市，2\/城市，3\/区县: 1\/省\/直辖市; 2\/城市; 3\/区县;"}}');
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
        $items = AreaModel::getItemsByIds($ids);
        //拼接额外字段 & 格式化相关字段
        $items = AreaModel::forShow($items);
        return $this->ar(1, ['items' => $items], '{"status":"api\/area\/getbyids\/1","items":[{"id":"主键id","name":"名称","f_id":"父类id","type":"类型，1\/省、直辖市，2\/城市，3\/区县: 1\/省\/直辖市; 2\/城市; 3\/区县;"}]}');
    }

}