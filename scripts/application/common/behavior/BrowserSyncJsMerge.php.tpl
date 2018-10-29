<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017-04-10
 * Time: 16:30
 */

namespace app\common\behavior;


use app\console\BrowserSync;
use think\App;

/**
 * 自动拼接浏览器自动刷新js
 * Class BrowserSyncJsMerge
 * @package app\common\behavior
 */
class BrowserSyncJsMerge {

    /**
     * 执行
     * @param $content
     */
    public function run(&$content) {
        //包含不加载标识
        if (strpos($content, 'exclude_sync_js_content')) {
            return;
        }
        //忽略api,migrate两个模块
        if (in_array(strtolower(request()->module()), ['api', 'migrate'])) {
            return;
        }
        //非debug模式
        if (!App::$debug) {
            return;
        }
        //忽略ajax请求
        if (request()->isAjax()) {
            return;
        }
        //忽略cli请求
        if (request()->isCli()) {
            return;
        }
        //拼接socket监听js
        $js_content = BrowserSync::instance()->getJsContent();
        if (strpos($content, '<head>') !== false) {
            //嵌入js
            $content = str_replace('<head>', "<head>\n" . $js_content, $content);
        } else {
            //拼接
            $content .= $js_content;
        }
    }
}