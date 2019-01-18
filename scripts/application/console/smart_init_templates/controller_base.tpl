/**
 * Created by PhpStorm.
 * User: SmartInit
 */

namespace app\api\base;

use app\api\controller\ApiController;
use app\index\model\{$table_name}Model;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClArray;{$use_content}

/**
 * {$table_comment['name']} Base
 * Class {$table_name} Base Api
 * @package app\api\base
 */
class {$table_name}BaseApiController extends ApiController {
<if condition="!empty($create_api) && in_array('get', $create_api)">

    /**
     * 获取返回例子
     * @return string
     */
    protected function getListReturnExample() {
        return '{$ar_get_list_json}';
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
        <present name="table_comment['partition']">${$table_comment['partition'][0]} = get_param('{$table_comment['partition'][0]}', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '{:isset($table_comment['partition'][1]) ? '字段'.$table_comment['partition'][0] : '日期'}');
        <if condition="isset($table_comment['partition'][1])">$where = [
            {$table_name}Model::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]}<php>echo "\n";</php>
        ];
        <else/>$where = [];
        </if>return $this->ar(1, $this->paging({$table_name}Model::instance(${$table_comment['partition'][0]}), $where, function ($return) {
            //拼接额外字段 & 格式化相关字段
            $return['items'] = {$table_name}Model::forShow($return['items']);
            //返回
            return $return;
        }), static::getListReturnExample());
    }
        <else/>$where = [];
        return $this->ar(1, $this->paging({$table_name}Model::instance(), $where, function ($return) {
            //拼接额外字段 & 格式化相关字段
            $return['items'] = {$table_name}Model::forShow($return['items']);
            //返回
            return $return;
        }), static::getListReturnExample());
    }
    </present>

    /**
     * 返回例子
     * @return string
     */
    protected function getReturnExample() {
        return '{$ar_get_json}';
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
        <present name="table_comment['partition']">${$table_comment['partition'][0]} = get_param('{$table_comment['partition'][0]}', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '{:isset($table_comment['partition'][1]) ? '字段'.$table_comment['partition'][0] : '日期'}');
        //获取
        $info = {$table_name}Model::getById(${$table_comment['partition'][0]}, $id);
        <else/>//获取
        $info = {$table_name}Model::getById($id);
        </present>//拼接额外字段 & 格式化相关字段
        $info = {$table_name}Model::forShow($info);
        return $this->ar(1, ['info' => $info], static::getReturnExample());
    }

    /**
     * 返回例子
     * @return string
     */
    protected function getByIdsReturnExample() {
        return '{$ar_get_by_ids_json}';
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
        <present name="table_comment['partition']">${$table_comment['partition'][0]} = get_param('{$table_comment['partition'][0]}', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '{:isset($table_comment['partition'][1]) ? '字段'.$table_comment['partition'][0] : '日期'}');
        //获取
        $items = {$table_name}Model::getItemsByIds(${$table_comment['partition'][0]}, $ids);
        <else/>//获取
        $items = {$table_name}Model::getItemsByIds($ids);
        </present>//拼接额外字段 & 格式化相关字段
        $items = {$table_name}Model::forShow($items);
        return $this->ar(1, ['items' => $items], static::getByIdsReturnExample());
    }
</if>
<if condition="!empty($create_api) && in_array('create', $create_api)">

    /**
     * 返回例子
     * @return string
     */
    protected function createReturnExample() {
        return '{$ar_create_json}';
    }

    /**
     * 创建
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function create() {
        $fields = ClArray::getByKeys(input(), {$table_name}Model::getAllFields());
        <present name="table_comment['partition']">${$table_comment['partition'][0]} = get_param('{$table_comment['partition'][0]}', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '{:isset($table_comment['partition'][1]) ? '字段'.$table_comment['partition'][0] : '日期'}');
        //创建
        {$table_name}Model::instance(${$table_comment['partition'][0]})->insert(${$table_comment['partition'][0]}, $fields);
        //获取
        $info = {$table_name}Model::getById(${$table_comment['partition'][0]}, {$table_name}Model::instance(${$table_comment['partition'][0]})->getLastInsID());
        <else/>//创建
        {$table_name}Model::instance()->insert($fields);
        //获取
        $info = {$table_name}Model::getById({$table_name}Model::instance()->getLastInsID());
        </present>//拼接额外字段 & 格式化相关字段
        $info = {$table_name}Model::forShow($info);
        return $this->ar(1, ['info' => $info], static::createReturnExample());
    }
</if>
<if condition="!empty($create_api) && in_array('update', $create_api)">

    /**
     * 返回例子
     * @return string
     */
    protected function updateReturnExample() {
        return '{$ar_update_json}';
    }

    /**
     * 更新
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function update() {
        $id = get_param({$table_name}Model::F_ID, ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '主键id');
        $fields = ClArray::getByKeys(input(), {$table_name}Model::getAllFields());
        <present name="table_comment['partition']">${$table_comment['partition'][0]} = get_param('{$table_comment['partition'][0]}', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '{:isset($table_comment['partition'][1]) ? '字段'.$table_comment['partition'][0] : '日期'}');
        //更新
        {$table_name}Model::instance(${$table_comment['partition'][0]})->where([
            <if condition="isset($table_comment['partition'][1])">{$table_name}Model::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]},
            </if>{$table_name}Model::F_ID => $id
        ])->setField($fields);
        //获取
        $info = {$table_name}Model::getById(${$table_comment['partition'][0]}, $id);
        <else/>//更新
        {$table_name}Model::instance()->where([
            {$table_name}Model::F_ID => $id
        ])->setField($fields);
        //获取
        $info = {$table_name}Model::getById($id);
        </present>//拼接额外字段 & 格式化相关字段
        $info = {$table_name}Model::forShow($info);
        return $this->ar(1, ['info' => $info], static::updateReturnExample());
    }
</if>
<if condition="!empty($create_api) && in_array('delete', $create_api)">

    /**
     * 返回例子
     * @return string
     */
    protected function deleteReturnExample() {
        return '{$ar_delete_json}';
    }

    /**
     * 删除
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\Exception
     * @throws \think\exception\PDOException
     */
    public function delete() {
        $id = get_param({$table_name}Model::F_ID, ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '主键id或id数组');
        <present name="table_comment['partition']">${$table_comment['partition'][0]} = get_param('{$table_comment['partition'][0]}', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '{:isset($table_comment['partition'][1]) ? '字段'.$table_comment['partition'][0] : '日期'}');
        //删除
        {$table_name}Model::instance(${$table_comment['partition'][0]})->where([
            <if condition="isset($table_comment['partition'][1])">{$table_name}Model::F_{:strtoupper($table_comment['partition'][0])} => ${$table_comment['partition'][0]},
            </if>{$table_name}Model::F_ID => is_array($id) ? ['in', $id] : $id
        ])->delete();
        <else/>//删除
        {$table_name}Model::instance()->where([
            {$table_name}Model::F_ID => is_array($id) ? ['in', $id] : $id
        ])->delete();
        </present>return $this->ar(1, ['id' => $id], static::deleteReturnExample());
    }
</if>
<foreach name="fields_config" item="each_config">

    /**
     * 获取字段{$each_config['field_name']}配置
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function getFieldConfig{$each_config['class_name']}() {
        $items = [];
        foreach ({$table_name}Model::C_{:strtoupper($each_config['field_name'])} as $value => $text) {
            $items[] = [
                'value' => $value,
                'text'  => $text
            ];
        }
        return $this->ar(1, ['items' => $items], '{$each_config["json_return"]}');
    }
</foreach>
{$functions_content}
}