<?php
/**
 * Created by PhpStorm.
 * User: skj19
 * Date: 2018-8-29
 * Time: 11:00
 */

namespace app\console;


use ClassLibrary\ClFile;
use ClassLibrary\ClPhpMix;
use ClassLibrary\ClSystem;
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;
use think\Exception;

/**
 * 代码混淆
 * Class Mix
 * @package app\console
 */
class Mix extends Command {

    /**
     * 配置
     */
    protected function configure() {
        $this->setName('mix')
            ->setDescription('混淆核心业务代码');
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool|int|null
     */
    protected function execute(Input $input, Output $output) {
        if (ClSystem::isWin()) {
            $output->error('请在Linux环境下执行');
            return false;
        }
        try {
            return $this->doExecute($input, $output);
        } catch (Exception $exception) {
            echo_info([
                'message' => $exception->getMessage(),
                'file'    => $exception->getFile(),
                'line'    => $exception->getLine(),
                'code'    => $exception->getCode(),
                'data'    => $exception->getData()
            ]);
        }
        return true;
    }

    /**
     * 执行
     * @param Input $input
     * @param Output $output
     * @return bool
     */
    private function doExecute(Input $input, Output $output) {
        $dirs = [DOCUMENT_ROOT_PATH . '/../database/migrations'];
        $dirs = array_merge(ClFile::dirGet(DOCUMENT_ROOT_PATH . '/../application'), $dirs);
        foreach ($dirs as $dir) {
            $files = ClFile::dirGetFiles($dir, ['.php']);
            foreach ($files as $file) {
                $output->highlight(str_replace(DOCUMENT_ROOT_PATH . '/../', '', $file));
                ClPhpMix::encode($file);
            }
        }
        //修改目录权限为www
        if (ClSystem::isLinux()) {
            $cmd = sprintf('cd %s && chown -R www:www *', DOCUMENT_ROOT_PATH . '/../');
            exec($cmd);
        }
        return true;
    }

}