<?php

namespace app\http\middleware;

use ClassLibrary\ClMergeResource;
use think\facade\App;

/**
 * 合并资源
 * Class MergeResource
 * @package app\http\middleware
 */
class MergeResource {

    /**
     * 执行
     * @param $request
     * @param \Closure $next
     * @return mixed
     */
    public function handle($request, \Closure $next) {
        $response = $next($request);
        if (App::isDebug() && !request()->isAjax() && !request()->isCli() && !in_array(strtolower(request()->module()), ['api', 'migrate'])) {
            $content = $response->getData();
            $content = ClMergeResource::merge($content);
            $response->data($content);
        }
        return $response;
    }

}
