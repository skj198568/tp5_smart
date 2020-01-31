    /**
     * 在插入之前处理数据
     * @param array $info
     * @return array
     */
    protected function triggerBeforeInsert($info) {
        $info = parent::triggerBeforeInsert($info);
        if (isset($info[self::F_COMMAND]) && !isset($info[self::F_COMMAND_CRC32])) {
            $info[self::F_COMMAND_CRC32] = crc32($info[self::F_COMMAND]);
        }
        return $info;
    }

    /**
     * 处理任务
     * @param int $id 执行的id
     * @return bool
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public static function deal($id = 0) {
        //处理数据
        if ($id == 0) {
            $item = self::instance()->where([
                self::F_START_TIME  => 0,
                self::F_CREATE_TIME => ['elt', time()]
            ])->order([self::F_ID => self::V_ORDER_ASC])->find();
            if (empty($item)) {
                return true;
            }
        } else {
            $item = self::getById($id);
        }
        //设置正在执行
        self::instance()->where([
            self::F_ID => $item[self::F_ID]
        ])->setField([
            self::F_START_TIME => time()
        ]);
        //执行
        log_info('task-start-' . $item[self::F_ID]);
        try {
            eval($item[self::F_COMMAND]);
            //设置执行的结束时间
            self::instance()->where([
                self::F_ID => $item[self::F_ID]
            ])->setField([
                self::F_END_TIME => time()
            ]);
        } catch (Exception $e) {
            $error_msg = json_encode([
                'message' => $e->getMessage(),
                'file'    => $e->getFile(),
                'line'    => $e->getLine(),
                'code'    => $e->getCode()
            ], JSON_UNESCAPED_UNICODE);
            self::instance()->where([
                self::F_ID => $item[self::F_ID]
            ])->setField([
                self::F_REMARK => $error_msg
            ]);
            log_info('task-error', $error_msg);
            if ($id > 0) {
                echo_info('task-error', $error_msg);
            }
        }
        //结束
        log_info('task-end-' . $item[self::F_ID]);
        return true;
    }

    /**
     * 创建任务
     * @param string $command 类似任务命令:app\index\model\AdminLoginLogModel::sendEmail();
     * @param int $within_seconds_ignore_this_cmd 在多长时间内忽略该任务，比如某些不需要太精确的统计任务，可以设置为60秒，即60秒内只执行一次任务
     * @param int $deal_time 定时任务执行的时间戳
     * @return bool|int|string
     */
    public static function createTask($command, $within_seconds_ignore_this_cmd = 0, $deal_time = 0) {
        $is_insert = true;
        //转为crc32，用于处理索引
        $command_crc32 = crc32($command);
        if ($within_seconds_ignore_this_cmd > 0) {
            $last_create_time = self::instance()->where([
                self::F_COMMAND_CRC32 => $command_crc32
            ])->order([self::F_ID => self::V_ORDER_DESC])->value(self::F_CREATE_TIME);
            if (!is_numeric($last_create_time) || time() - $last_create_time > $within_seconds_ignore_this_cmd) {
                $is_insert = true;
            } else {
                $is_insert = false;
            }
        }
        if ($is_insert) {
            //新增
            $fields = [self::F_COMMAND => $command];
            if ($deal_time > 0) {
                //定时任务
                $fields[self::F_CREATE_TIME] = $deal_time;
            }
            return self::instance()->insert($fields);
        } else {
            return false;
        }
    }