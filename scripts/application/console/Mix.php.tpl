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
use think\console\Command;
use think\console\Input;
use think\console\input\Option;
use think\console\Output;

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
     * @return int|null|void
     */
    protected function execute(Input $input, Output $output) {
        $dirs = [DOCUMENT_ROOT_PATH . '/../database/migrations'];
        $dirs = array_merge(ClFile::dirGet(DOCUMENT_ROOT_PATH . '/../application'), $dirs);
        foreach ($dirs as $dir) {
            $files = ClFile::dirGetFiles($dir, ['.php']);
            foreach ($files as $file) {
                $output->highlight(str_replace(DOCUMENT_ROOT_PATH . '/../', '', $file));
                ClPhpMix::encode($file);
            }
        }
    }

}