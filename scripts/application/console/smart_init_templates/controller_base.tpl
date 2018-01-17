/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\api\base;

use app\api\controller\ApiController;
use app\index\model\{$table_name}Model;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClArray;

/**
 * {$table_comment['name']} Base
 * Class {$table_name} Base Api
 * @package app\api\base
 */
class {$table_name}BaseApiController extends ApiController
{
<if condition="in_array('getList', $create_api)">

    /**
     * 列表
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getList()
    {
        $where = [];
        return $this->ar(1, $this->paging({$table_name}Model::instance(), $where, function ($items) {
            //拼接额外字段 & 格式化相关字段
            return {$table_name}Model::forShow($items);
        }), '{$ar_get_list_json}');
    }
</if>
<if condition="in_array('get', $create_api)">

    /**
     * 单个信息
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function get()
    {
        $id = get_param({$table_name}Model::F_ID, ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '主键id或id数组');
        $info = {$table_name}Model::getById($id);
        //拼接额外字段 & 格式化相关字段
        $info = {$table_name}Model::forShow($info);
        return $this->ar(1, ['info' => $info], '{$ar_get_json}');
    }
</if>
<if condition="in_array('create', $create_api)">

    /**
     * 创建
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function create()
    {
        $fields = ClArray::getByKeys(input(), {$table_name}Model::getAllFields());
        //创建
        {$table_name}Model::instance()->insert($fields);
        return $this->ar(1, ['id' => {$table_name}Model::instance()->getLastInsID()], '{"status":"api-{:strtolower($table_name)}-create-1","id":"主键id"}');
    }
</if>
<if condition="in_array('update', $create_api)">

    /**
     * 更新
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function update()
    {
        $id = get_param({$table_name}Model::F_ID, ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '主键id或id数组');
        $fields = ClArray::getByKeys(input(), {$table_name}Model::getAllFields());
        //更新
        {$table_name}Model::instance()->where([
            {$table_name}Model::F_ID => $id
        ])->setField($fields);
        return $this->ar(1, ['id' => $id], '{"status":"api-{:strtolower($table_name)}-update-1","id":"主键id"}');
    }
</if>
<if condition="in_array('delete', $create_api)">

    /**
     * 删除
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\Exception
     * @throws \think\exception\PDOException
     */
    public function delete()
    {
        $id = get_param({$table_name}Model::F_ID, ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '主键id或id数组');
        //删除
        {$table_name}Model::instance()->where([
            {$table_name}Model::F_ID => is_array($id) ? ['in', $id] : $id
        ])->delete();
        return $this->ar(1, ['id' => $id], '{"status":"api-{:strtolower($table_name)}-delete-1","id":"主键id"}');
    }
</if>

}