<?php

namespace app\http\middleware;

use app\console\BrowserSync;
use think\facade\App;
use think\Response;

/**
 * 浏览器同步刷新js
 * Class BrowserSyncJsMerge
 * @package app\http\middleware
 */
class BrowserSyncJsMerge {

    /**
     * 执行
     * @param $request
     * @param \Closure $next
     * @return mixed
     */
    public function handle($request, \Closure $next) {
        $response = $next($request);
        //处理response
        $this->dealResponse($response);
        return $response;
    }

    /**
     * 处理response
     * @param Response $response
     */
    private function dealResponse(Response $response) {
        //忽略ajax请求
        if (request()->isAjax()) {
            return;
        }
        //非debug模式
        if (!App::isDebug()) {
            return;
        }
        //忽略cli请求
        if (request()->isCli()) {
            return;
        }
        //忽略api,migrate两个模块
        if (in_array(strtolower(request()->module()), ['api', 'migrate'])) {
            return;
        }
        //获取内容
        $content = $response->getData();
        //包含不加载标识
        if (strpos($content, 'exclude_sync_js_content')) {
            return;
        }
        //拼接socket监听js
        $js_content = BrowserSync::instance()->getJsContent();
        //为空，则忽略
        if (empty($js_content)) {
            return;
        }
        //已经拼接，则忽略
        if (strpos($content, $js_content) !== false) {
            return;
        }
        if (strpos($content, '<head>') !== false) {
            //嵌入js
            $content = str_replace('<head>', "<head>\n" . $js_content, $content);
        } else {
            //拼接
            $content .= $js_content;
        }
        //设置内容
        $response->data($content);
    }

}
