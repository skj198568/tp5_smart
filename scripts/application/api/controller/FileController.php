<?php
/**
 * Created by PhpStorm.
 * User: SongKejing
 * QQ: 597481334
 * Date: 2018/2/8
 * Time: 14:06
 */

namespace app\api\controller;

use ClassLibrary\ClFieldVerify;
use ClassLibrary\ClFile;
use ClassLibrary\ClImage;

/**
 * 文件处理
 * Class FileController
 * @package app\api\controller
 */
class FileController extends ApiController {

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
        $png2jpg = get_param('png2jpg', ClFieldVerify::instance()->verifyInArray([0, 1])->fetchVerifies(), '是否转换png为jpg', 1);
        //png转jpg
        if ($png2jpg) {
            $result['file'] = ClImage::png2jpg($result['file']);
        }
        return $this->ar(1, $result, '{"status":"api\/file\/uploadfile\/1","result":true,"msg":"上传成功","file":"\/upload\/2018\/03\/06\/104945_2748152867.xlsx"}');
    }

}