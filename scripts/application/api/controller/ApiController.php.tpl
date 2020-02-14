<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2017/8/30
 * Time: 18:22
 */

namespace app\api\controller;


use app\api\base\BaseApiController;
use ClassLibrary\ClArray;
use ClassLibrary\ClCrypt;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClVerify;
use think\App;

/**
 * 基础Api接口
 * Class ApiController
 * @package app\api\controller
 */
class ApiController extends BaseApiController {

    /**
     * 用户uid
     * @var int
     */
    protected $id = 0;

    /**
     * 不校验的请求
     * @var array
     */
    protected $uncheck_request = [
    ];

    /**
     * 初始化
     */
    public function _initialize() {
        parent::_initialize();
        $token = '';
        //合并
        $this->uncheck_request = array_merge($this->default_uncheck_request, $this->uncheck_request);
        if (!ClArray::inArrayIgnoreCase(request()->controller() . '/' . request()->action(), $this->uncheck_request)) {
            $token = get_param('token', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '校验token');
        }
        if (!empty($token)) {
            $this->id = ClCrypt::decrypt($token, CRYPT_KEY);
            if (empty($this->id)) {
                if (ClVerify::isLocalIp(request()->ip()) && is_numeric($token)) {
                    //本机请求
                    $this->id = $token;
                } else {
                    $response = json_return([
                        'status'  => -2,
                        'message' => '无效token'
                    ]);
                    $response->send();
                    exit;
                }
            }
        }
    }

    /**
     * 空请求
     * @return string
     */
    public function _empty() {
        if (strtolower(request()->controller() . DS . request()->action()) == 'index' . DS . 'index' && App::$debug) {
            $t = get_param('t', [], '时间戳', 0);
            if ($t == 0 || $t < time() - 3) {
                $this->redirect('/api?t=' . time());
            }
            $api_file             = DOCUMENT_ROOT_PATH . '/../doc/api/index.html';
            $api_file_create_time = 0;
            if (is_file($api_file)) {
                $api_file_create_time = filectime($api_file);
            }
            //获取所有controller文件
            $controller_files       = ClFile::dirGetFiles(__DIR__, [], ['ApiController.php']);
            $max_modify_create_time = 0;
            foreach ($controller_files as $controller_file) {
                $file_create_time = filectime($controller_file);
                if ($file_create_time > $max_modify_create_time) {
                    $max_modify_create_time = $file_create_time;
                }
            }
            if ($max_modify_create_time > $api_file_create_time) {
                if (!function_exists('exec')) {
                    return 'function "exec" is not exist';
                }
                //重新生成api文档
                $cmd = sprintf('cd %s && php think api_doc', DOCUMENT_ROOT_PATH . '/../');
                exec($cmd);
            }
            //直接输出
            return $this->fetch($api_file);
        } else {
            return '<h1 style="text-align: center;font-size: 5em;">404</h1>';
        }
    }

}