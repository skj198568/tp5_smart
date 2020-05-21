        $items = $this->triggerGetItems();
        foreach($items as $item){
            if (isset($item[self::F_SHORT_URL])) {
                self::getByShortUrlRc($item[self::F_SHORT_URL]);
            }
        }