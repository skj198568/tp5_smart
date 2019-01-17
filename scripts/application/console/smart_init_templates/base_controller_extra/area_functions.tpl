
    /**
     * 按名字获取
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getByName() {
        $where = [];
        $name  = get_param('name', ClFieldVerify::instance()->fetchVerifies(), '模糊检索名字', '');
        if (!empty($name)) {
            $where[AreaModel::F_NAME] = ['like', '%' . $name . '%'];
        }
        $type = get_param('type', ClFieldVerify::instance()->fetchVerifies(), '地区类型，int或int型数组', 0);
        if ($type != 0) {
            $where[AreaModel::F_TYPE] = is_array($type) ? ['in', $type] : $type;
        }
        $items = AreaModel::instance()->where($where)->select();
        $items = AreaModel::forShow($items);
        return $this->ar(1, ['items' => $items], '{"status":"api\/area\/getbyname\/1","status_code":1,"items":[{"id":320100,"name":"南京市","f_id":320000,"type":2,"type_show":"城市"}]}');
    }

    /**
     * 获取省份
     * @return array|false|null|\PDOStatement|string|\think\Collection
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getProvinces() {
        return $this->ar(1, ['items' => AreaModel::getAllProvinces()], '{"status":"api\/area\/getprovinces\/1","status_code":1,"items":[{"id":130000,"name":"河北省","f_id":0},{"id":140000,"name":"山西省","f_id":0},{"id":150000,"name":"内蒙古自治区","f_id":0},{"id":210000,"name":"辽宁省","f_id":0},{"id":220000,"name":"吉林省","f_id":0},{"id":230000,"name":"黑龙江省","f_id":0},{"id":320000,"name":"江苏省","f_id":0},{"id":330000,"name":"浙江省","f_id":0},{"id":340000,"name":"安徽省","f_id":0},{"id":350000,"name":"福建省","f_id":0},{"id":360000,"name":"江西省","f_id":0},{"id":370000,"name":"山东省","f_id":0},{"id":410000,"name":"河南省","f_id":0},{"id":420000,"name":"湖北省","f_id":0},{"id":430000,"name":"湖南省","f_id":0},{"id":440000,"name":"广东省","f_id":0},{"id":450000,"name":"广西壮族自治区","f_id":0},{"id":460000,"name":"海南省","f_id":0},{"id":510000,"name":"四川省","f_id":0},{"id":520000,"name":"贵州省","f_id":0},{"id":530000,"name":"云南省","f_id":0},{"id":540000,"name":"西藏自治区","f_id":0},{"id":610000,"name":"陕西省","f_id":0},{"id":620000,"name":"甘肃省","f_id":0},{"id":630000,"name":"青海省","f_id":0},{"id":640000,"name":"宁夏回族自治区","f_id":0},{"id":650000,"name":"新疆维吾尔自治区","f_id":0}]}');
    }

    /**
     * 获取城市
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getCitiesByProvinceId() {
        $province_id = get_param('province_id', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '省份id/直辖市id');
        return $this->ar(1, ['items' => AreaModel::getCitesByProvinceId($province_id)], '{"status":"api\/area\/getcitiesbyprovinceid\/1","status_code":1,"items":[{"id":130100,"name":"石家庄市","f_id":130000},{"id":130200,"name":"唐山市","f_id":130000},{"id":130300,"name":"秦皇岛市","f_id":130000},{"id":130400,"name":"邯郸市","f_id":130000},{"id":130500,"name":"邢台市","f_id":130000},{"id":130600,"name":"保定市","f_id":130000},{"id":130700,"name":"张家口市","f_id":130000},{"id":130800,"name":"承德市","f_id":130000},{"id":130900,"name":"沧州市","f_id":130000},{"id":131000,"name":"廊坊市","f_id":130000},{"id":131100,"name":"衡水市","f_id":130000}]}');
    }

    /**
     * 获取区
     * @return \think\response\Json|\think\response\Jsonp
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\ModelNotFoundException
     * @throws \think\exception\DbException
     */
    public function getAreasByCityId() {
        $city_id = get_param('city_id', ClFieldVerify::instance()->verifyIsRequire()->verifyNumber()->fetchVerifies(), '城市id');
        return $this->ar(1, ['items' => AreaModel::getAreasByCityId($city_id)], '{"status":"api\/area\/getareasbycityid\/1","status_code":1,"items":[{"id":130102,"name":"长安区","f_id":130100},{"id":130103,"name":"桥东区","f_id":130100},{"id":130104,"name":"桥西区","f_id":130100},{"id":130105,"name":"新华区","f_id":130100},{"id":130107,"name":"井陉矿区","f_id":130100},{"id":130108,"name":"裕华区","f_id":130100},{"id":130121,"name":"井陉县","f_id":130100},{"id":130123,"name":"正定县","f_id":130100},{"id":130124,"name":"栾城县","f_id":130100},{"id":130125,"name":"行唐县","f_id":130100},{"id":130126,"name":"灵寿县","f_id":130100},{"id":130127,"name":"高邑县","f_id":130100},{"id":130128,"name":"深泽县","f_id":130100},{"id":130129,"name":"赞皇县","f_id":130100},{"id":130130,"name":"无极县","f_id":130100},{"id":130131,"name":"平山县","f_id":130100},{"id":130132,"name":"元氏县","f_id":130100},{"id":130133,"name":"赵县","f_id":130100},{"id":130181,"name":"辛集市","f_id":130100},{"id":130182,"name":"藁城市","f_id":130100},{"id":130183,"name":"晋州市","f_id":130100},{"id":130184,"name":"新乐市","f_id":130100},{"id":130185,"name":"鹿泉市","f_id":130100}]}');
    }
