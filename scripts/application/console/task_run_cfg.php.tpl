<?php
/**
 * Created by : PhpStorm
 * @author: SongKeJing qq:597481334 mobile:159-5107-8050
 */
//执行命令=类似crontab的执行时间定义，支持到秒一级任务定义 */秒 */分 */时 */日 */月 */周
//Tools/Template/homework=*/5 * * * * *
return [
    [
        'command'   => 'tools/task/deal',
        'cron_date' => '*/1 * * * * *'
    ],
];