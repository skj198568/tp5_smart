<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/05/05
 * Time: 19:58:34
 */

namespace app\api\controller;

use app\api\base\AreaBaseApiController;
use app\index\model\AreaModel;
use ClassLibrary\ClFieldVerify;

/**
 * 地址信息
 * 如果有需要，请重写父类接口，不可直接修改父类函数，会被自动覆盖掉。
 * Class AreaController
 * @package app\api\controller
 */
class AreaController extends AreaBaseApiController {

    /**
     * 按名字获取
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getByName() {
        $where = [];
        $name  = get_param('name', ClFieldVerify::instance()->fetchVerifies(), '模糊检索名字', '');
        if (!empty($name)) {
            $where[AreaModel::F_NAME] = ['like', '%' . $name . '%'];
        }
        $type = get_param('type', ClFieldVerify::instance()->fetchVerifies(), '地区类型', 0);
        if ($type != 0) {
            $where[AreaModel::F_TYPE] = $type;
        }
        $items = AreaModel::instance()->where($where)->select();
        $items = AreaModel::forShow($items);
        return $this->ar(1, ['items' => $items], '{"status":"api\/area\/getbyname\/1","items":[{"id":320100,"name":"南京市","f_id":320000,"type":2,"type_show":"城市"}]}');
    }
}