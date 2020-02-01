"use strict";

/**
 * 公共js
 */
var jCommon = {

    /**
     * bootstrap提示信息，第二个参数可选top|bottom|left|right|auto
     * @param id 例:'id_123'
     */
    bTooltip: function (id) {
        var placement = arguments.length === 2 ? arguments[1] : 'top';
        var options = {
            animation: true,
            container: 'body',
            trigger: 'hover', //触发tooltip的事件
            placement: placement
        };
        $('#' + id).tooltip(options);
    },

    /**
     * bootstrap消息提示
     * @param msg
     */
    bShowMsg: function (msg) {
        Messenger.options = {
            extraClasses: 'messenger-fixed messenger-on-bottom',
            theme: 'future'
        };
        var type = arguments.length === 2 ? arguments[1] : true;
        if (type) {
            Messenger().post({
                message: msg,
                showCloseButton: true
            });
        } else {
            Messenger().post({
                message: msg,
                type: 'error',
                showCloseButton: true
            });
        }
    },

    /**
     * 是否为数值型
     * @param str
     * @returns {boolean}
     */
    isNumber: function (str) {
        return str.toString().match(/^[0-9]+\.{0,1}[0-9]{0,2}$/) === null ? false : true;
    },

    /**
     * 判断是否是字符串
     * @param str
     * @returns {boolean}
     */
    isString: function (str) {
        return Object.prototype.toString.call(str) === "[object String]";
    },

    /**
     * 是否为email
     * @param email
     * @returns {boolean}
     */
    isEmail: function (email) {
        var regex = /^([a-zA-Z0-9_.+-])+\@(([a-zA-Z0-9-])+\.)+([a-zA-Z0-9]{2,4})+$/;
        var res = regex.test(email);
        res = ((email !== '') && res);
        return res;
    },

    /**
     * 是否为手机号码
     * @param mobile
     * @returns {boolean}
     */
    isMobile: function isMobile(mobile) {
        var regex = /^1(3|4|5|6|7|8|9)\d{9}$/;
        if (regex.test(mobile)) {
            return true;
        } else {
            return false;
        }
    },

    /**
     * 是否为有效ip
     * @param ip
     * @returns {boolean}
     */
    isIP: function isIP(ip) {
        var s = /^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])$/;
        return ip.match(s) === null ? false : true;
    },

    /**
     * 是否为mac地址
     * @param mac
     * @returns {boolean}
     */
    isMAC: function (mac) {
        var temp = /[A-Fa-f0-9]{2}:[A-Fa-f0-9]{2}:[A-Fa-f0-9]{2}:[A-Fa-f0-9]{2}:[A-Fa-f0-9]{2}:[A-Fa-f0-9]{2}/;
        return mac.match(temp) === null ? false : true;
    },

    /**
     * 是否为邮政编码
     * @param postcode
     */
    isPostcode: function (postcode) {
        return postcode.match(/^[1-9][0-9]{5}$/) === null ? false : true;
    },

    /**
     * 获取字符串设计长度（支持中英文）
     * @param str
     * @returns {number}
     */
    strLength: function (str) {
        var realLength = 0, len = str.length, charCode = -1;
        for (var i = 0; i < len; i++) {
            charCode = str.charCodeAt(i);
            if (charCode >= 0 && charCode <= 128) {
                realLength += 1;
            } else {
                realLength += 2;
            }
        }
        return realLength;
    },

    /**
     * 删除左右两端的空格
     * @param str
     * @returns {string}
     */
    strTrim: function (str) {
        return str.replace(/(^\s*)|(\s*$)/g, "");
    },

    /**
     * 删除左边的空格
     * @param str string
     * @returns {string}
     */
    strLeftTrim: function (str) {
        return str.replace(/(^\s*)/g, "");
    },

    /**
     * 删除右边的空格
     * @param str
     * @returns {string}
     */
    strRightTrim: function (str) {
        return str.replace(/(\s*$)/g, "");
    },

    /**
     * 反转字符串
     * @param str
     * @returns {string}
     */
    strReverse: function (str) {
        return str.toString().split("").reverse().join("");
    },

    /**
     * 图片居中剪裁显示
     * 使用方法：
     * <div id="id_div">
     *    <img id="id_img" src="images/b.jpg" alt="" onload="imageCenterCut('id_div', 'id_img', 200, 400)"/>
     * </div>
     * @param id_div 包含图片父类div id
     * @param id_img 图片id
     * @param show_height 父类div图片显示高度
     * @param show_width 父类div图片显示宽度
     */
    imageCenterCut: function (id_div, id_img, show_height, show_width) {
        //设置外部div style
        document.getElementById(id_div).style.position = 'absolute';
        document.getElementById(id_div).style.overflow = 'hidden';
        document.getElementById(id_div).style.width = show_width + 'px';
        document.getElementById(id_div).style.height = show_height + 'px';
        var img_height = document.getElementById(id_img).height;
        var img_width = document.getElementById(id_img).width;
        //设置图片显示的宽度和高度，并且设置div scroll值
        if (img_height / img_width > show_height / show_width) {
            document.getElementById(id_img).width = show_width;
            document.getElementById(id_img).height = img_height / img_width * show_width;
            document.getElementById(id_div).scrollTop = (img_height / img_width * show_width - show_height) / 2;
        } else {
            document.getElementById(id_img).width = img_width / img_height * show_height;
            document.getElementById(id_img).height = show_height;
            document.getElementById(id_div).scrollLeft = (img_width / img_height * show_height - show_width) / 2;
        }
    },

    /**
     * 去除html标签
     * @param str
     * @returns {string}
     */
    strStripHtmlTags: function (str) {
        return str.toString().replace(/<[^>]+>/g, "");
    },

    /**
     * 格式化时间
     * @param t
     * @returns {string}
     */
    dateFormat: function (t) {
        var d = new Date(t);
        return d.getFullYear() + '-' + jCommon.dateAddZero(d.getMonth() + 1) + '-' + jCommon.dateAddZero(d.getDate()) + ' ' + jCommon.dateAddZero(d.getHours()) + ':' + jCommon.dateAddZero(d.getMinutes()) + ':' + jCommon.dateAddZero(d.getSeconds());
    },

    /**
     * 获取当前时间 Y-m-d H:i:s
     * @returns {string}
     */
    getDate: function () {
        var d = new Date();
        return d.getFullYear() + '-' + jCommon.dateAddZero(d.getMonth() + 1) + '-' + jCommon.dateAddZero(d.getDate()) + ' ' + jCommon.dateAddZero(d.getHours()) + ':' + jCommon.dateAddZero(d.getMinutes()) + ':' + jCommon.dateAddZero(d.getSeconds());
    },

    /**
     * 添加时间
     * @param d
     * @returns {string}
     */
    dateAddZero: function (d) {
        return parseInt(d) < 10 ? '0' + d : d;
    },

    /**
     * 获取年月日
     * @returns {string}
     */
    getDateYmd: function (date) {
        var d = new Date();
        if (jCommon.empty(date)) {
            d = new Date();
        } else {
            d = new Date(date * 1000);
        }
        return d.getFullYear() + '-' + jCommon.dateAddZero(d.getMonth() + 1) + '-' + jCommon.dateAddZero(d.getDate());
    },

    /**
     * 获取时间戳
     * @param date
     * @returns {number}
     */
    getDateTimestamp: function (date) {
        var d = new Date(date);
        return d.getTime() / 1000;
    },

    /**
     * bootstrap分页字符串
     * @param all_count 所有数据总条数
     * @param page_count 每页显示条数
     * @param current_page 当前页
     * @param page_function 调用分页函数，例如：'getPage'
     * @returns {string}
     */
    bPagingString: function (all_count, page_count, current_page, page_function) {
        all_count = parseInt(all_count);
        //为空则直接返回
        if (all_count === 0) {
            return '<nav><ul class="pagination"></ul></nav>';
        }
        page_count = parseInt(page_count);
        current_page = parseInt(current_page);
        var pages_str = '';
        var page_begin = 0;
        var page_end = 0;
        var all_page = Math.ceil(all_count / page_count);
        var show_count = 11;
        var show_middle = 5;
        page_begin = (current_page - show_middle) > 0 ? (current_page - show_middle) : 1;
        page_end = (current_page + show_middle) < all_page ? (current_page + show_middle) : all_page;
        if (all_page > show_count && page_end < show_count) {
            page_end = show_count;
        }
        for (var i = page_begin; i <= page_end; i++) {
            if (i === current_page) {
                pages_str += '<li class="active"><a href="javascript: void(0);">' + i + '</a></li>';
            } else {
                pages_str += '<li><a href="javascript: void(0);" onclick="return ' + page_function + '(' + i + ');">' + i + '</a></li>';
            }
        }
        //添加上一页
        if (current_page === 1) {
            pages_str = '<li class="disabled"><a href="javascript: void(0);">上一页</a></li>' + pages_str;
        } else {
            pages_str = '<li><a href="javascript: void(0);" onclick="return ' + page_function + '(' + (current_page - 1) + ');">上一页</a></li>' + pages_str;
        }
        //添加下一页
        if (current_page === all_page) {
            pages_str += '<li class="disabled"><a href="javascript: void(0);">下一页</a></li>';
        } else {
            pages_str += '<li><a href="javascript: void(0);" onclick="return ' + page_function + '(' + (current_page + 1) + ');">下一页</a></li>';
        }
        pages_str += '<li class="disabled"><a href="javascript: void(0);" style="border-right-width: 0;"><span class="text-primary">' + all_count + '</span>条&nbsp;&nbsp;<span class="text-primary">' + Math.ceil(all_count / page_count) + '</span>页</a></li>';
        pages_str += '<li>' +
            '<input class="form-control" style="width: 50px;display: inline;float: left;padding:8px;border-radius:0;" id="id_js_common_jump_page_text" type="text" placeholder="Page">' +
            '<button type="button" class="btn btn-primary" style="float: left;border-top-left-radius: 0;border-bottom-left-radius: 0;" onclick="return jCommon.bJumpPage();">跳转</button>' +
            '</li>';
        pages_str += '<span style="display: none;" id="id_js_common_jump_page_function">' + page_function + '</span>';
        pages_str += '<span style="display: none;" id="id_js_common_all_count">' + all_count + '</span>';
        pages_str += '<span style="display: none;" id="id_js_common_page_count">' + page_count + '</span>';
        pages_str += '<span style="display: none;" id="id_js_common_current_page">' + current_page + '</span>';
        return '<nav><ul class="pagination">' + pages_str + '</ul></nav>';
    },

    /**
     * 分页跳转页面
     * @returns {boolean}
     */
    bJumpPage: function () {
        var all_count = $('#id_js_common_all_count').html();
        var page_count = $('#id_js_common_page_count').html();
        var current_page = $('#id_js_common_current_page').html();
        var jump_page = $('#id_js_common_jump_page_text').val();
        if (jump_page.length === 0) {
            return false;
        }
        //不是数字
        if (!jCommon.isNumber(jump_page)) {
            $('#id_js_common_jump_page_text').css('color', 'red');
            return false;
        }
        //小于1
        if (jump_page < 1) {
            $('#id_js_common_jump_page_text').css('color', 'red');
            return false;
        }
        $('#id_js_common_jump_page_text').css('color', 'black');
        //最大页
        if (jump_page > Math.ceil(all_count / page_count)) {
            jump_page = Math.ceil(all_count / page_count);
            $('#id_js_common_jump_page_text').val(jump_page);
        }
        //页面相等
        if (current_page === jump_page) {
            return false;
        }
        var page_function = $('#id_js_common_jump_page_function').html();
        //执行页面跳转
        var eval_function = eval;
        eval_function(page_function + '(' + jump_page + ')');
        return false;
    },

    /**
     * 以中文4位万分位格式化金钱数字
     * @param money
     * @returns {*}
     */
    strToMoney: function (money) {
        money = money.toString();
        //反转字符串
        money = jCommon.strReverse(money);
        var return_str = '';
        //判断是否含有'.'
        var i;
        if (money.indexOf('.') >= 0) {
            //以'.'分割字符串
            var money_array = money.split('.');
            for (i = 0; i < money_array[1].length; i++) {
                return_str += money_array[1].charAt(i);
                if ((i + 1) % 4 === 0 && (i + 1) < money_array[1].length) {
                    return_str += ',';
                }
            }
            return_str = money_array[0] + '.' + return_str;
        } else {
            for (i = 0; i < money.length; i++) {
                return_str += money.charAt(i);
                if ((i + 1) % 4 === 0 && (i + 1) < money.length) {
                    return_str += ',';
                }
            }
        }
        //再次反转字符串
        return jCommon.strReverse(return_str);
    },

    /**
     * 判断是否是数组
     * @param o
     * @returns {boolean}
     */
    isArray: function (o) {
        return Object.prototype.toString.call(o) === '[object Array]';
    },

    /**
     * 是否是对象
     * @param o
     * @returns {boolean}
     */
    isObject: function (o) {
        return typeof o === 'object';
    },

    /**
     * 对象的数据长度
     * @param obj
     * @returns {number}
     */
    objectSize: function (obj) {
        var size = 0, key;
        for (key in obj) {
            if (obj.hasOwnProperty(key)) {
                size++;
            }
        }
        return size;
    },

    /**
     * 验证密码：以字母开头，长度在min~max之间，只能包含字符、数字和下划线
     * @param str
     * @param min
     * @param max
     * @returns {boolean}
     */
    isPassword: function (str, min, max) {
        max = parseInt(max);
        //max--;
        min = parseInt(min);
        //min--;
        var reg = new RegExp('^[0-9A-Za-z]{' + min + ',' + max + '}$');
        return str.match(reg) === null ? false : true;
    },

    /**
     * 简单密码，最小长度的字母数字组合
     * @param str
     * @param min
     * @returns {boolean}
     */
    isPasswordAZaz09: function (str, min) {
        var reg = new RegExp('(\\w){' + min + ',}$', 'g');
        return str.match(reg) === null ? false : true;
    },

    /**
     * 是否是固话
     * @param str
     * @returns {boolean}
     */
    isFixedPhone: function (str) {
        return str.match(/\d{3}(-?)\d{8}|\d{4}(-?)\d{7}$/) === null ? false : true;
    },

    /**
     * 身份证校验
     * @param code
     * @returns {{result: boolean, msg: string}}
     */
    isIdCard: function (code) {
        // 根据〖中华人民共和国国家标准 GB 11643-1999〗中有关公民身份号码的规定，公民身份号码是特征组合码，由十七位数字本体码和一位数字校验码组成。排列顺序从左至右依次为：六位数字地址码，八位数字出生日期码，三位数字顺序码和一位数字校验码。
        // 地址码表示编码对象常住户口所在县(市、旗、区)的行政区划代码。
        // 出生日期码表示编码对象出生的年、月、日，其中年份用四位数字表示，年、月、日之间不用分隔符。
        // 顺序码表示同一地址码所标识的区域范围内，对同年、月、日出生的人员编定的顺序号。顺序码的奇数分给男性，偶数分给女性。
        // 校验码是根据前面十七位数字码，按照ISO 7064:1983.MOD 11-2校验码计算出来的检验码。
        //
        // 出生日期计算方法。
        // 15位的身份证编码首先把出生年扩展为4位，简单的就是增加一个19或18,这样就包含了所有1800-1999年出生的人;
        // 2000年后出生的肯定都是18位的了没有这个烦恼，至于1800年前出生的,那啥那时应该还没身份证号这个东东，⊙﹏⊙b汗...
        // 下面是正则表达式:
        // 出生日期1800-2099  (18|19|20)?\d{2}(0[1-9]|1[12])(0[1-9]|[12]\d|3[01])
        // 身份证正则表达式 /^\d{6}(18|19|20)?\d{2}(0[1-9]|1[12])(0[1-9]|[12]\d|3[01])\d{3}(\d|X)$/i
        // 15位校验规则 6位地址编码+6位出生日期+3位顺序号
        // 18位校验规则 6位地址编码+8位出生日期+3位顺序号+1位校验位
        //
        // 校验位规则     公式:∑(ai×Wi)(mod 11)……………………………………(1)
        // 公式(1)中：
        // i----表示号码字符从由至左包括校验码在内的位置序号；
        // ai----表示第i位置上的号码字符值；
        // Wi----示第i位置上的加权因子，其数值依据公式Wi=2^(n-1）(mod 11)计算得出。
        // i 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1
        // Wi 7 9 10 5 8 4 2 1 6 3 7 9 10 5 8 4 2 1
        // 身份证号合法性验证
        // 支持15位和18位身份证号
        // 支持地址编码、出生日期、校验位验证
        var city = {
            11: "北京",
            12: "天津",
            13: "河北",
            14: "山西",
            15: "内蒙古",
            21: "辽宁",
            22: "吉林",
            23: "黑龙江",
            31: "上海",
            32: "江苏",
            33: "浙江",
            34: "安徽",
            35: "福建",
            36: "江西",
            37: "山东",
            41: "河南",
            42: "湖北",
            43: "湖南",
            44: "广东",
            45: "广西",
            46: "海南",
            50: "重庆",
            51: "四川",
            52: "贵州",
            53: "云南",
            54: "西藏",
            61: "陕西",
            62: "甘肃",
            63: "青海",
            64: "宁夏",
            65: "新疆",
            71: "台湾",
            81: "香港",
            82: "澳门",
            91: "国外"
        };
        var tip = "";
        var pass = true;
        if (!code || !/^\d{6}(18|19|20)?\d{2}(0[1-9]|1[12])(0[1-9]|[12]\d|3[01])\d{3}(\d|X)$/i.test(code)) {
            tip = "身份证号格式错误";
            pass = false;
        } else if (!city[code.substr(0, 2)]) {
            tip = "地址编码错误";
            pass = false;
        } else {
            //18位身份证需要验证最后一位校验位
            if (code.length === 18) {
                code = code.split('');
                //∑(ai×Wi)(mod 11)
                //加权因子
                var factor = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
                //校验位
                var parity = [1, 0, 'X', 9, 8, 7, 6, 5, 4, 3, 2];
                var sum = 0;
                var ai = 0;
                var wi = 0;
                for (var i = 0; i < 17; i++) {
                    ai = code[i];
                    wi = factor[i];
                    sum += ai * wi;
                }
                var last = parity[sum % 11];
                if (parity[sum % 11] !== code[17]) {
                    tip = "校验位错误";
                    pass = false;
                }
            }
        }
        return {
            result: pass,
            msg: tip
        };
    },

    /**
     * 字母
     * @param str
     * @returns {boolean}
     */
    isAZaz: function (str) {
        return str.match(/^[A-Za-z]+$/) === null ? false : true;
    },

    /**
     * 大写字母
     * @param str
     * @returns {boolean}
     */
    isAZ: function (str) {
        return str.match(/^[A-Z]+$/) === null ? false : true;
    },

    /**
     * 小写字母
     * @param str
     * @returns {boolean}
     */
    isaz: function (str) {
        return str.match(/^[a-z]+$/) === null ? false : true;
    },

    /**
     * 是否是中文
     * @param str
     * @returns {boolean}
     */
    isChinese: function (str) {
        return str.match(/^[\u4e00-\u9fa5]+$/) === null ? false : true;
    },

    /**
     * 是否是url
     * @param str
     * @returns {boolean}
     */
    isUrl: function (str) {
        return str.match(/[a-zA-z]+:\/\/[^\s]*/) === null ? false : true;
    },

    /**
     * 是否是qq
     * @param str
     * @returns {boolean}
     */
    isQQ: function (str) {
        return str.match(/[1-9][0-9]{4,}/) === null ? false : true;
    },

    /**
     * 获取数字
     * @param str
     * @returns {*|string}
     */
    getInt: function (str) {
        str = str.match(/\d+(\.\d+)?/g);
        return (str === null) ? '' : str.join('');
    },

    /**
     * 获取中文
     * @param str
     * @returns {*|string}
     */
    getChinese: function (str) {
        str = str.match(/[\u4e00-\u9fa5]/g);
        return (str === null) ? '' : str.join('');
    },

    /**
     * 获取英文字符
     * @param str
     * @returns {*|string}
     */
    getAZaz: function (str) {
        str = str.match(/[a-zA-z]/g);
        return (str === null) ? '' : str.join('');
    },

    /**
     * 获取姓名，支持中文、英文、·符号
     * @param str
     * @returns {*}
     */
    getUserName: function (str) {
        str = str.match(/[\u4e00-\u9fa5a-zA-z·]/g);
        return (str === null) ? '' : str.join('');
    },

    /**
     * 获取屏幕分辨率
     * @returns {Number}
     */
    getScreenSize: function () {
        return {
            clientWidth: document.body.clientWidth,
            clientHeight: document.body.clientHeight,
            scrollWidth: document.body.scrollWidth,
            scrollHeight: document.body.scrollHeight,
            screenTop: window.screenTop,
            screenLeft: window.screenLeft,
            height: window.screen.height,
            width: window.screen.width,
            availHeight: window.screen.availHeight,
            availWidth: window.screen.availWidth
        };
    },

    /**
     * 判断是否为空
     * @param str
     * @returns {boolean}
     */
    empty: function (str) {
        if (typeof (str) === "undefined" || str === 0 || str === '' || str === '0' || str === null || str === false || str === undefined || (jCommon.isString(str) && jCommon.strTrim(str).length === 0) || (jCommon.isArray(str) && str.length === 0)) {
            return true;
        } else if (jCommon.isObject(str)) {
            var is_empty = true;
            var prop;
            for (prop in str) {
                is_empty = false;
                break;
            }
            return is_empty;
        } else {
            return false;
        }
    },

    /**
     * 字符串转换为json数据
     * @param str
     * @returns {Object}
     */
    strToJson: function (str) {
        //去除换行符、回车符
        var eval_function = eval;
        return eval_function('(' + str + ')');
    },

    /**
     * 获取剩余时间，格式：'x年x月x日x时x分x秒'
     * @param time_length 剩余时间
     * @returns {*}
     */
    dateLeftFormat: function (time_length) {
        if (jCommon.empty(time_length)) {
            return 0;
        }
        time_length = parseInt(time_length);
        var format_array = ['Y', 'm', 'd', 'H', 'i', 's'];
        var i;
        var result = {};
        for (i in format_array) {
            switch (format_array[i]) {
                case 'Y':
                    result.Y = time_length - 365 * 24 * 3600 > 0 ? Math.floor(time_length / (365 * 24 * 3600)) : 0;
                    break;
                case 'm':
                    result.m = time_length % (365 * 24 * 3600) - 30 * 24 * 3600 > 0 ? (Math.floor(time_length % (365 * 24 * 3600) / (30 * 24 * 3600))) : 0;
                    break;
                case 'd':
                    result.d = time_length % (365 * 24 * 3600) % (30 * 24 * 3600) - 24 * 3600 > 0 ? (Math.floor(time_length % (365 * 24 * 3600) % (30 * 24 * 3600) / (24 * 3600))) : 0;
                    break;
                case 'H':
                    result.H = time_length % (365 * 24 * 3600) % (30 * 24 * 3600) % (24 * 3600) - 3600 > 0 ? (Math.floor(time_length % (365 * 24 * 3600) % (30 * 24 * 3600) % (24 * 3600) / 3600)) : 0;
                    break;
                case 'i':
                    result.i = time_length % (365 * 24 * 3600) % (30 * 24 * 3600) % (24 * 3600) % 3600 - 60 > 0 ? (Math.floor(time_length % (365 * 24 * 3600) % (30 * 24 * 3600) % (24 * 3600) % 3600 / 60)) : 0;
                    break;
                case 's':
                    result.s = time_length % (365 * 24 * 3600) % (30 * 24 * 3600) % (24 * 3600) % 3600 % 60;
                    break;
            }
        }
        var format = '';
        format_array = {
            Y: '年',
            m: '月',
            d: '日',
            H: '时',
            i: '分',
            s: '秒'
        };
        //是否忽略
        var is_cut = true;
        //替换
        for (i in result) {
            if (is_cut && result[i] <= 0) {
                continue;
            }
            if (result[i] !== 0) {
                is_cut = false;
            }
            //格式化
            if (i !== 'Y') {
                result[i] = jCommon.dateAddZero(result[i]);
            }
            format += result[i] + format_array[i];
        }
        return format;
    },

    /**
     * 获取cookie的值
     * @param name
     * @returns {*}
     */
    cookieGet: function (name) {
        var cookieArray = document.cookie.split("; "); //得到分割的cookie名值对
        for (var i = 0; i < cookieArray.length; i++) {
            var arr = cookieArray[i].split("=");       //将名和值分开
            //如果是指定的cookie，则返回它的值
            if (arr[0] === name) {
                return decodeURI(arr[1]);
            }
        }
        return "";
    },

    /**
     * 删除cookie
     * @param name
     */
    cookieDel: function (name) {
        var d = new Date();
        d.setTime(d.getTime() - 1);
        document.cookie = name + '=; expires=' + d.toGMTString() + ';path=/';
    },

    /**
     * 设置cookie的值
     * @param name
     * @param value
     * @param seconds 为0时不设定过期时间，浏览器关闭时cookie自动消失
     */
    cookieAdd: function (name, value, seconds) {
        var str = name + '=' + encodeURI(value);
        if (seconds > 0) {
            var date = new Date();
            seconds = seconds * 1000;
            date.setTime(date.getTime() + seconds);
            str += '; expires=' + date.toGMTString();
        }
        document.cookie = str + ';path=/';
    },

    /**
     * 获取域名
     * @returns {string}
     */
    hostGet: function () {
        return window.location.host;
    },

    /**
     * 获取当前url
     * @returns {string}
     */
    hrefGet: function () {
        return window.location.href;
    },

    /**
     * 获取上一次请求的url
     * @returns {string}
     */
    hrefGetLast: function () {
        return document.referrer;
    },

    /**
     * 在数组中获取指定值的元素索引
     * @returns {int}
     */
    getIndexByValue: function (value, arr) {
        var index = -1;
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] === value) {
                index = i;
                break;
            }
        }
        return index;
    },

    /**
     * 数组去重
     * @returns {array}
     */
    arrUnique: function (arr) {
        arr.sort();
        var re = [arr[0]];
        for (var i = 1; i < arr.length; i++) {
            if (arr[i] !== re[re.length - 1]) {
                re.push(arr[i]);
            }
        }
        return re;
    },

    /**
     * 去除空格
     * @param str
     * @returns {*}
     */
    removeSpace: function (str) {
        return str.replace(/\s+/g, "");
    },

    /**
     * 获取url参数，第二个参数为默认值，第三个参数为默认url
     * @param name
     * @returns {*}
     */
    hrefGetParams: function (name) {
        var default_value = arguments.length === 2 ? arguments[1] : null;
        var url = arguments.length === 3 ? arguments[2] : window.location.href;
        //去除锚点
        if (url.indexOf('#') > -1) {
            url = url.substr(0, url.indexOf('#'));
        }
        //替换?、=、&为“/”
        url = url.replace(/(\?)|(=)|(&)/g, '/');
        var domain = jCommon.hostGet();
        url = url.substr(url.indexOf(domain) + domain.length);
        //不存在参数
        if (url.indexOf('/') === -1) {
            return default_value;
        }
        //去除后缀
        if (url.indexOf('.') !== -1 && url.lastIndexOf('/') < url.lastIndexOf('.')) {
            url = url.substring(0, url.lastIndexOf('.'));
        }
        //去除左侧"/"
        url = url.replace(/(^\/)/, "");
        //分割为数组
        var params = url.split('/');
        //翻转数组
        params.reverse();
        var return_params = {};
        for (var i = 0; i <= params.length; i += 2) {
            if (params.hasOwnProperty(i) && params.hasOwnProperty(i + 1)) {
                return_params[params[i + 1]] = params[i];
            }
        }
        if (return_params.hasOwnProperty(name)) {
            return decodeURI(return_params[name]);
        } else {
            return default_value;
        }
    },

    /**
     * 获取href中的锚点
     * @returns {*}
     */
    hrefGetAnchor: function () {
        var url = window.location.href;
        if (url.lastIndexOf('#') === -1) {
            return '';
        } else {
            url = url.substring(url.lastIndexOf('#') + 1);
            if (url.indexOf('-') !== -1) {
                url = url.substring(0, url.indexOf('-'));
            }
            return url;
        }
    },

    /**
     * 获取锚点中的参数
     * @param name
     * @returns {*}
     */
    hrefGetAnchorParams: function (name) {
        var url = window.location.href;
        var default_value = arguments.length === 2 ? arguments[1] : null;
        if (url.indexOf('#') === -1) {
            return default_value;
        }
        url = url.substring(url.indexOf('#') + 1);
        //分割为数组
        var params = url.split('/');
        //翻转数组
        params.reverse();
        var return_params = {};
        for (var i = 0; i <= params.length; i += 2) {
            if (params.hasOwnProperty(i) && params.hasOwnProperty(i + 1)) {
                return_params[params[i + 1]] = params[i];
            }
        }
        if (return_params.hasOwnProperty(name)) {
            return decodeURI(return_params[name]);
        } else {
            return default_value;
        }
    },

    /**
     * 将变量转换为驼峰格式
     * @param str
     * @returns {string}
     */
    convertStrToHump: function (str) {
        if (str.indexOf('_') === -1) {
            return str;
        }
        var p = str.split('_');
        str = '';
        for (var i = 0; i < p.length; i++) {
            if (i === 0) {
                str += p[i];
            } else {
                str += (p[i]).substring(0, 1).toUpperCase() + (p[i]).substring(1);
            }
        }
        return str;
    },

    /**
     * 字符串是否是json
     * @param str
     * @returns {boolean}
     */
    isJson: function (str) {
        if (/^[\],:{}\s]*$/.test(str.replace(/\\["\\\/bfnrtu]/g, '@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
            return true;
        } else {
            return false;
        }
    },

    /**
     * 获取IE版本
     * @returns {*}
     */
    browserGetIeVersion: function () {
        var userAgent = navigator.userAgent; //取得浏览器的userAgent字符串
        var isIE = userAgent.indexOf("compatible") > -1 && userAgent.indexOf("MSIE") > -1; //判断是否IE<11浏览器
        var isEdge = userAgent.indexOf("Edge") > -1 && !isIE; //判断是否IE的Edge浏览器
        var isIE11 = userAgent.indexOf('Trident') > -1 && userAgent.indexOf("rv:11.0") > -1;
        if (isIE) {
            var reIE = new RegExp("MSIE (\\d+\\.\\d+);");
            reIE.test(userAgent);
            var fIEVersion = parseFloat(RegExp["$1"]);
            if (fIEVersion > 6) {
                return fIEVersion;
            } else {
                //IE版本<=7
                return 6;
            }
        } else if (isEdge) {
            return 'edge';//edge
        } else if (isIE11) {
            return 11; //IE11
        } else {
            return -1;//不是ie浏览器
        }
    }

};
