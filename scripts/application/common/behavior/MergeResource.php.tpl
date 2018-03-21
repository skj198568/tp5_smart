<?php
/**
 * Created by PhpStorm.
 * User: skj19
 * Date: 2016/11/29
 * Time: 10:07
 */

namespace app\common\behavior;

use ClassLibrary\ClMergeResource;

/**
 * 合并资源
 * Class MergeResource
 * @package app\common\behavior
 */
class MergeResource {

    /**
     * 执行
     * @param $content
     */
    public function run(&$content) {
        $content = ClMergeResource::merge($content);
    }

}