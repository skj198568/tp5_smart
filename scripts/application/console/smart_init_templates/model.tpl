/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: {$date}
 * Time: {$time}
 */

namespace app\index\model;

use app\index\map\{$table_name}Map;

/**
 * {$table_comment['name']}
 * 如果有需要，请重写父类接口，不可直接修改父类函数，会被自动覆盖掉。
 * Class {$table_name}Model
 * @package app\index\model
 */
class {$table_name}Model extends {$table_name}Map {

    /**
     * 初始化
     */
    public function initialize() {
        parent::initialize();
    }

    /**
     * 在插入之前处理数据
     * @param array $info
     * @return array
     */
    protected function triggerBeforeInsert($info) {
        return parent::triggerBeforeInsert($info);
    }

    /**
     * 在插入之后处理数据
     * 采用$items = $this->triggerGetItems();方式获取所有影响的数据
     */
    protected function triggerAfterInsert() {
        parent::triggerAfterInsert();
    }

    /**
     * 在更新之前处理数据
     * @param array $info
     * @return array
     */
    protected function triggerBeforeUpdate($info) {
        return parent::triggerBeforeUpdate($info);
    }

    /**
     * 在更新之后处理数据
     * 采用$items = $this->triggerGetItems();方式获取所有影响的数据
     */
    protected function triggerAfterUpdate() {
        parent::triggerAfterUpdate();
    }

    /**
     * 在删除数据之前处理数据
     * @param array $items
     */
    protected function triggerBeforeDelete($items) {
        parent::triggerBeforeDelete($items);
    }

    /**
     * 在删除数据之后处理数据
     * @param array $items
     */
    protected function triggerAfterDelete($items) {
        parent::triggerAfterDelete($items);
    }

    /**
     * 缓存清除器
     * 采用$items = $this->triggerGetItems();方式获取所有影响的数据
     * @throws \think\db\exception\BindParamException
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     * @throws \think\exception\PDOException
     */
    protected function triggerRemoveCache() {
        parent::triggerRemoveCache();
    }

}