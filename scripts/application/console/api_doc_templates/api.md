## {$id}. {$api_desc}

##### url
```
{$url}
```
<notempty name="params">

##### params
名称|校验条件|描述
---|---|---
<foreach name="params" item="vo">
{$vo['name']}|{$vo['filters']}|<?php echo ($vo['remark']."\n"); ?>
</foreach>
</notempty>

##### return
<empty name="ar_returns">
```
```
</empty>
<foreach name="ar_returns" item="vo">
```
<?php echo ($vo."\n"); ?>
```
</foreach>