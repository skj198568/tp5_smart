<?php
/**
 * Created by PhpStorm.
 * User: SmartInit
 * Date: 2018/05/05
 * Time: 19:58:34
 */

namespace app\index\model;

use app\index\map\AreaMap;

/**
 * 地址信息 Model
 */
class AreaModel extends AreaMap {

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
        if ($id >= 0) {
            if (!isset(self::$instances_array[$id])) {
                self::$instances_array[$id] = new self();
            }
            return self::$instances_array[$id];
        } else if ($id == -1) {
            return count(self::$instances_array);
        } else if ($id == -2) {
            return self::instance(count(self::$instances_array));
        } else {
            return null;
        }
    }

    /**
     * 缓存清除触发器
     * @param $item
     */
    protected function cacheRemoveTrigger($item) {
        //先执行父类
        parent::cacheRemoveTrigger($item);
    }

    /**
     * 获取所有的省份
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getAllProvinces() {
        return self::instance()->where(array(
            self::F_TYPE => self::V_TYPE_PROVINCE
        ))->cache([], 3600)->field(array(
            self::F_ID, self::F_NAME, self::F_F_ID
        ))->select();
    }

    /**
     * 获取所有的城市
     * @param $province_id
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getCitesByProvinceId($province_id) {
        return self::instance()->where(array(
            self::F_TYPE => self::V_TYPE_CITY,
            self::F_F_ID => $province_id
        ))->cache([$province_id], 3600)->field(array(
            self::F_ID, self::F_NAME, self::F_F_ID
        ))->select();
    }

    /**
     * 按城市获取区县
     * @param $city_id
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getAreasByCityId($city_id) {
        return self::instance()->where(array(
            self::F_TYPE => self::V_TYPE_AREA,
            self::F_F_ID => intval($city_id)
        ))->field(array(
            self::F_ID, self::F_NAME, self::F_F_ID
        ))->select();
    }

    /**
     * 按名字获取信息
     * @param $name
     * @return array|false|null|\PDOStatement|string|\think\Model
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getByName($name) {
        return self::instance()->where([
            self::F_NAME => ['like', '%' . $name . '%']
        ])->find();
    }

    /**
     * 按name获取id
     * @param $name
     * @param int $father_id 父类id
     * @param int $type 类型
     * @return int|mixed
     */
    public static function getIdByName($name, $father_id = 0, $type = 0) {
        $where = [
            self::F_NAME => ['like', '%' . $name . '%']
        ];
        if ($father_id != 0) {
            $where[self::F_F_ID] = $father_id;
        }
        if ($type != 0) {
            $where[self::F_TYPE] = $type;
        }
        $id = self::instance()->where($where)->value(self::F_ID);
        if (empty($id)) {
            $id = 0;
        }
        return $id;
    }

    /**
     * 获取根id
     * @param $area_id
     * @return mixed
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function getRootProvinceId($area_id) {
        $info = self::getById($area_id);
        if ($info[self::F_TYPE] == self::V_TYPE_PROVINCE) {
            return $info[self::F_ID];
        } else {
            //继续向上寻找
            return self::getRootProvinceId($info[self::F_F_ID]);
        }
    }

}