<?php

namespace app\http\middleware;

use ClassLibrary\ClMergeResource;
use think\Response;

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
        //处理返回值
        $this->dealResponse($response);
        return $response;
    }

    /**
     * 处理返回值
     * @param Response $response
     */
    private function dealResponse(Response $response) {
        //ajax模式
        if (request()->isAjax()) {
            return;
        }
        //cli模式
        if (request()->isCli()) {
            return;
        }
        //忽略api和migrate模块
        if (in_array(strtolower(request()->module()), ['api', 'migrate'])) {
            return;
        }
        $content = $response->getData();
        $content = ClMergeResource::merge($content);
        $response->data($content);
    }

}
