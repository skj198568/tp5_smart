    /**
     * 在操作数据库之前预处理数据
     * @param array $data
     * @param string $operate_type 操作类型self::V_OPERATE_TYPE_INSERT/self::V_OPERATE_TYPE_UPDATE
     * @return array
     */
    protected function preprocessDataBeforeExecute($data, $operate_type) {
        $data = parent::preprocessDataBeforeExecute($data, $operate_type);
        if (isset($data[self::F_COMMAND])) {
            $data[self::F_COMMAND_CRC32] = crc32($data[self::F_COMMAND]);
        }
        return $data;
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
                self::F_START_TIME => 0
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
     * @return bool|int|string
     */
    public static function createTask($command, $within_seconds_ignore_this_cmd = 0) {
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
            return self::instance()->insert([
                self::F_COMMAND => $command
            ]);
        } else {
            return false;
        }
    }