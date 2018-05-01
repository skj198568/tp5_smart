/**
 * Created by SongKeJing on 2015/1/24.
 * avalon常用函数，比如avalon配置、过滤器等
 */
avalon.config({
    debug: true
});

/**
 * avalon 长度限制过滤器
 * @type {{get: Function}}
 */
avalon.duplexHooks.limit = {
    get: function (str, data) {
        var limit = parseFloat(data.element.getAttribute('data-duplex-limit'));
        if (str.length > limit) {
            return data.element.value = str.slice(0, limit);
        } else {
            return str;
        }
    }
};

/**
 * 日期过滤器
 * @param t
 * @returns {string}
 */
avalon.filters.dateFormat = function (t) {
    if (isNaN(parseInt(t)) || parseInt(t) == 0) {
        return '';
    }
    return dateFormat(t);
};

/**
 * 性别过滤器
 * @param str
 * @returns {string|*}
 */
avalon.filters.sex = function (str) {
    return_str = '';
    switch (parseInt(str)) {
        case 0:
            return_str = '女';
            break;
        case 1:
            return_str = '男';
            break;
        default:
            return_str = '未知';
    }
    return return_str;
};

/**
 * 是否关注过滤器
 * @param str
 * @returns {string|*}
 */
avalon.filters.subscribe = function (str) {
    return_str = '';
    switch (parseInt(str)) {
        case 0:
            return_str = '否';
            break;
        case 1:
            return_str = '是';
            break;
    }
    return return_str;
};

/**
 * 所属地区过滤器
 * @param str
 * @returns {string|*}
 */
avalon.filters.place = function (str) {
    if (str.length == 0) {
        return '无';
    }
    return str;
};

/**
 * 是否是星标消息
 * @param str
 * @returns {string}
 */
avalon.filters.star = function (str) {
    if (parseInt(str) == 1) {
        return '<span class="text-success">是</span>';
    } else {
        return '<span class="text-danger">否</span>';
    }
};

/**
 * 是否有效
 * @param valid
 * @returns {string}
 */
avalon.filters.isValid = function (valid) {
    if (parseInt(valid) == 1) {
        return '<span class="text-success">是</span>';
    } else {
        return '<span class="text-danger">否</span>';
    }
};

/**
 * 比较新旧两个对象的不同，仅仅对比两个对象都存在的键值对
 * @param object_new
 * @param object_old
 * @returns {Object}
 */
avalon.objectGetDifferent = function (object_new, object_old) {
    if (!jCommon.isObject(object_new) || !jCommon.isObject(object_old)) {
        return new Object();
    }
    var return_array = new Object();
    avalon.each(object_new, function (new_k, new_v) {
        if (object_old.hasOwnProperty(new_k) == true && object_old[new_k] != new_v) {
            return_array[new_k] = new_v;
        }
    });
    object_new = object_old = null;
    return return_array;
};

/**
 * 将新对象改变的值赋值给老对象，仅仅对比两个对象都存在的键值对
 * @param object_new
 * @param object_old
 * @returns {*}
 */
avalon.objectMerge = function (object_new, object_old) {
    if (!jCommon.isObject(object_new) || !jCommon.isObject(object_old)) {
        return new Object();
    }
    avalon.each(object_new, function (new_k, new_v) {
        if (object_old.hasOwnProperty(new_k) == true && object_old[new_k] != new_v) {
            object_old[new_k] = new_v;
        }
    });
    object_new = null;
    return object_old;
};

/**
 * 导入文件类型过滤器
 * @param type
 */
avalon.filters.importFileType = function (type) {
    var name = '';
    avalon.each(sda_import_types, function (k, v) {
        if (parseInt(v.id) == parseInt(type)) {
            name = v.name;
        }
    });
    return name;
};

/**
 * 导入类型过滤器
 * @param status
 * @returns {string}
 */
avalon.filters.importStatus = function (status) {
    var name = '';
    avalon.each(sda_import_status, function (k, v) {
        if (parseInt(status) == parseInt(v.id)) {
            name = v.name;
        }
    });
    return name;
};
