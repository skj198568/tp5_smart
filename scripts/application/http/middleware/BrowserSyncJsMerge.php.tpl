<?php

namespace app\http\middleware;

use app\console\BrowserSync;
use think\facade\App;

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
        if (App::isDebug() && !request()->isAjax() && !request()->isCli() && !in_array(strtolower(request()->module()), ['api', 'migrate'])) {
            //获取内容
            $content = $response->getData();
            //拼接socket监听js
            $js_content = BrowserSync::instance()->getJsContent();
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
        return $response;
    }

}
