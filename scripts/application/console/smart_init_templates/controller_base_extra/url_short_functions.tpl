    /**
     * 跳转地址
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function jump() {
        $short_url = get_param('short_url', ClFieldVerify::instance()->verifyIsRequire()->fetchVerifies(), '短连接地址');
        //获取
        $info = UrlShortModel::getByShortUrl($short_url);
        //默认跳转地址
        $jump_url = ClHttp::getServerDomain() . '/';
        if (!empty($info)) {
            //判断超时时间
            if (empty($info[UrlShortModel::F_END_TIME]) || $info[UrlShortModel::F_END_TIME] > time()) {
                $jump_url = $info[UrlShortModel::F_TRUE_URL];
                if (strpos($info[UrlShortModel::F_TRUE_URL], '/') === 0) {
                    $jump_url = ClHttp::getServerDomain() . $info[UrlShortModel::F_TRUE_URL];
                }
            }
        }
        //跳转地址
        $this->redirect($jump_url);
    }