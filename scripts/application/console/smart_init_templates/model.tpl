/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: {$date}
 * Time: {$time}
 */

namespace app\index\model;

use app\index\map\{$table_name}Map;

/**
 * {$table_comment['name']} Model
 */
class {$table_name}Model extends {$table_name}Map {

    /**
     * 实例对象存放数组
     * @var array
     */
    private static $instances_array = [];

    /**
     * 实例对象
     * @param int $id -1/获取实例数量，-2/自动新增一个实例
     * @return int|mixed|null|static
     */
    public static function instance($id = 0) {
        if($id >= 0) {
            if (!isset(self::$instances_array[$id])) {
                self::$instances_array[$id] = new self();
            }
            return self::$instances_array[$id];
        }else if($id == -1) {
            return count(self::$instances_array);
        }else if($id == -2) {
            return self::instance(count(self::$instances_array));
        }else{
            return null;
        }
    }

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        if(isset($item[self::F_ID])) {
            self::getByIdRc($item[self::F_ID]);
        }
    }

}