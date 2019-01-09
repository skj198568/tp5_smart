<?php
/**
 * Created by PhpStorm.
 * User: skj19
 * Date: 2019-1-8
 * Time: 18:17
 */

namespace app\migrate\controller;

use ClassLibrary\ClString;
use think\db\Query;

/**
 * 基础函数
 * Class CommonController
 * @package app\migrate\controller
 */
class CommonController extends MigrateBaseController {

    /**
     * 获取mysql版本
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\BindParamException
     * @throws \think\exception\PDOException
     */
    public function getMysqlVersion() {
        $result  = $this->query('select version() as version;');
        $version = $result[0]['version'];
        //取数字
        $version = ClString::getBetween($version, '', '-', false);
        return $this->ar(1, ['version' => $version]);
    }

}