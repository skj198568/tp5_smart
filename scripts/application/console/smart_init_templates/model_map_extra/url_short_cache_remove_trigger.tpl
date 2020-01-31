        $items = $this->triggerGetItems($sql, $ids, $items);
        foreach($items as $item){
            if (isset($item[self::F_SHORT_URL])) {
                self::getByShortUrlRc($item[self::F_SHORT_URL]);
            }
        }