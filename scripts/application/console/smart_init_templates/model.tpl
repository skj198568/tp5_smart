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
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        //先执行父类
        parent::cacheRemoveTrigger($item);
    }

}