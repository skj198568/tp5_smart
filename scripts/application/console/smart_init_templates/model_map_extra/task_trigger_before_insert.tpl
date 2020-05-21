        if (isset($info[self::F_COMMAND]) && !isset($info[self::F_COMMAND_CRC32])) {
            $info[self::F_COMMAND_CRC32] = crc32($info[self::F_COMMAND]);
        }