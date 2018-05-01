->{$field_deal_type}('{$field_info['field_name']}', '{$field_info['field_type']}', [{$field_info['after_field']}{$field_info['field_limit']}{$field_info['field_default_value']}'comment' =>
ClMigrateField::instance()
<present name="field_info['is_sortable']">
    <if condition="$field_info['is_sortable']">
        ->isSortable()
    </if>
</present>
<present name="field_info['is_searchable']">
    <if condition="$field_info['is_searchable']">
        ->isSearchable()
    </if>
</present>
<present name="field_info['visible']">
    <if condition="!$field_info['visible']">
        ->invisible()
    </if>
</present>
<present name="field_info['is_read_only']">
    <if condition="$field_info['is_read_only']">
        ->isReadOnly()
    </if>
</present>
<present name="field_info['const_values']">
    <notempty name="field_info['const_values']">
        ->constValues({:is_array($field_info['const_values']) ? trim(json_encode($field_info['const_values'], JSON_UNESCAPED_UNICODE), '"') : $field_info['const_values']})
    </notempty>
</present>
<present name="field_info['show_map_fields']">
    <notempty name="field_info['show_map_fields']">
        ->showMapFields({:is_array($field_info['show_map_fields']) ? trim(json_encode($field_info['show_map_fields'], JSON_UNESCAPED_UNICODE), '"') : $field_info['show_map_fields']})
    </notempty>
</present>
<present name="field_info['show_format']">
    <notempty name="field_info['show_format']">
        <foreach name="field_info['show_format']" item="v" key="k">
            ->showFormat("{$v[0]}")
        </foreach>
    </notempty>
</present>
<present name="field_info['is_read_only']">
    <if condition="$field_info['is_read_only']">
        ->isReadOnly()
    </if>
</present>
<present name="field_info['store_format']">
    <if condition="$field_info['store_format'] eq 'json'">
        ->storageFormatJson()
    </if>
    <if condition="is_array($store_format)">
        <if condition="$field_info['store_format'][0] eq 'password'">
            ->storageFormatPassword('{$store_format[1]}')
        </if>
    </if>
</present>
<present name="field_info['verifies']">
    <foreach name="$field_info['verifies']" item="v" key="k">
        <if condition="is_array($v)">
            <if condition="$v[0] eq 'password'">
                ->verifyIsPassword('{$v[1]}', '{$v[2]}')
            </if>
            <if condition="$v[0] eq 'in_array'">
                ->verifyInArray({:is_array($v[1]) ? trim(json_encode($v[1], JSON_UNESCAPED_UNICODE), '"') : $v[1]})
            </if>
            <if condition="$v[0] eq 'in_scope'">
                ->verifyIntInScope('{$v[1]}', '{$v[2]}')
            </if>
            <if condition="$v[0] eq 'max'">
                ->verifyIntMax('{$v[1]}')
            </if>
            <if condition="$v[0] eq 'min'">
                ->verifyIntMin('{$v[1]}')
            </if>
            <if condition="$v[0] eq 'length'">
                ->verifyStringLength('{$v[1]}')
            </if>
            <if condition="$v[0] eq 'length_max'">
                ->verifyStringLengthMax('{$v[1]}')
            </if>
            <if condition="$v[0] eq 'length_min'">
                ->verifyStringLengthMin('{$v[1]}')
            </if>
            <else/>
            <if condition="$v eq 'is_required'">
                ->verifyIsRequire()
            </if>
            <if condition="$v eq 'email'">
                ->verifyEmail()
            </if>
            <if condition="$v eq 'mobile'">
                ->verifyMobile()
            </if>
            <if condition="$v eq 'ip'">
                ->verifyIp()
            </if>
            <if condition="$v eq 'postcode'">
                ->verifyPostcode()
            </if>
            <if condition="$v eq 'id_card'">
                ->verifyIdCard()
            </if>
            <if condition="$v eq 'chinese'">
                ->verifyChinese()
            </if>
            <if condition="$v eq 'chinese_alpha'">
                ->verifyChineseAlpha()
            </if>
            <if condition="$v eq 'chinese_alpha_num'">
                ->verifyChineseAlphaNum()
            </if>
            <if condition="$v eq 'chinese_alpha_num_dash'">
                ->verifyChineseAlphaNumDash()
            </if>
            <if condition="$v eq 'alpha'">
                ->verifyAlpha()
            </if>
            <if condition="$v eq 'alpha_num'">
                ->verifyAlphaNum()
            </if>
            <if condition="$v eq 'alpha_num_dash'">
                ->verifyAlphaNumDash()
            </if>
            <if condition="$v eq 'url'">
                ->verifyUrl()
            </if>
            <if condition="$v eq 'number'">
                ->verifyNumber()
            </if>
            <if condition="$v eq 'array'">
                ->verifyArray()
            </if>
            <if condition="$v eq 'tel'">
                ->verifyTel()
            </if>
            <if condition="$v eq 'is_date'">
                ->verifyIsDate()
            </if>
            <if condition="$v eq 'unique'">
                ->verifyUnique()
            </if>
            <if condition="$v eq 'is_domain'">
                ->verifyIsDomain()
            </if>
        </if>
    </foreach>
</present>
->fetch('{$field_info['field_desc']}')
])