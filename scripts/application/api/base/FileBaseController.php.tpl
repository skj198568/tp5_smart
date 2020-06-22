<?php
/**
 * Created by PhpStorm.
 * User: skj19
 * Date: 2018-10-24
 * Time: 17:00
 */

namespace app\api\base;


use app\api\controller\ApiController;
use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClHttp;
use ClassLibrary\ClImage;

/**
 * 文件处理
 * Class FileBaseController
 * @package app\api\base
 */
class FileBaseController extends ApiController {

    /**
     * 跨域处理
     */
    public function _initialize() {
        parent::_initialize();
        header('Access-Control-Allow-Origin:*');
    }

    /**
     * 上传文件
     */
    public function uploadFile() {
        $file_save_dir = get_param('file_save_dir', ClFieldVerify::instance()->fetchVerifies(), '文件保存文件夹，相对或绝对路径', '');
        $result        = ClFile::uploadDealClient($file_save_dir);
        $image_width   = get_param('image_width', ClFieldVerify::instance()->verifyNumber()->fetchVerifies(), '图片宽度，可不传', 0);
        $image_height  = get_param('image_height', ClFieldVerify::instance()->verifyNumber()->fetchVerifies(), '图片高度，可不传', 0);
        if ($result['result'] && $image_height + $image_width > 0) {
            //自动截取图片
            ClImage::centerCut($result['file'], $image_width, $image_height);
        }
        $png2jpg = get_param('png2jpg', ClFieldVerify::instance()->verifyInArray([0, 1])->fetchVerifies(), '是否转换png为jpg，默认1', 0);
        //png转jpg
        if ($png2jpg) {
            $result['file'] = ClImage::png2jpg($result['file']);
        }
        $is_append_domain = get_param('is_append_domain', ClFieldVerify::instance()->verifyInArray([0, 1])->fetchVerifies(), '返回文件地址是否拼接域名，0/否，1/是，默认0', 0);
        if ($is_append_domain) {
            $result['file'] = ClHttp::getServerDomain() . $result['file'];
        }
        $return_type = get_param('return_type', ClFieldVerify::instance()->verifyInArray(['json', 'file_url'])->fetchVerifies(), '返回类型，默认json', 'json');
        if ($return_type == 'file_url') {
            //直接返回文件内容
            return $result['file'];
        } else {
            return $this->ar(1, $result, '{"status":"api\/file\/uploadfile\/1","status_code":1,"result":true,"msg":"上传成功","file":"\/upload\/2018\/03\/06\/104945_2748152867.xlsx"}');
        }
    }

    /**
     * 图片处理
     * @return \think\response\Json|\think\response\Jsonp
     */
    public function img() {
        $img_url = get_param('img_url', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '图片地址');
        //替换域名
        $img_url      = str_replace(ClHttp::getServerDomain(), '', $img_url);
        $image_width  = get_param('image_width', ClFieldVerify::instance()->verifyNumber()->fetchVerifies(), '图片宽度，可不传', 0);
        $image_height = get_param('image_height', ClFieldVerify::instance()->verifyNumber()->fetchVerifies(), '图片高度，可不传', 0);
        if ($image_height + $image_width > 0) {
            //自动截取图片
            ClImage::centerCut(DOCUMENT_ROOT_PATH . $img_url, $image_width, $image_height);
        }
        $png2jpg = get_param('png2jpg', ClFieldVerify::instance()->verifyInArray([0, 1])->fetchVerifies(), '是否转换png为jpg，默认1', 0);
        //png转jpg
        if ($png2jpg) {
            $img_url = ClImage::png2jpg(DOCUMENT_ROOT_PATH . $img_url);
            //替换为相对路径
            $img_url = str_replace(DOCUMENT_ROOT_PATH, '', $img_url);
        }
        return $this->ar(1, ['url' => $img_url], '{"status":"api\/file\/img\/1","status_code":1,"url":"\/static\/lib\/file_upload\/server\/php\/files\/265286_20180508231249.jpg"}');
    }

}