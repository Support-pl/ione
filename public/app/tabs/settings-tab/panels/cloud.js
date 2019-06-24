/* —------------------------------------------------------------------------ */
/* Copyright 2018-2019, IONe Clouf Project                                    */
/*                                                                            */
/* Licensed under the Apache License, Version 2.0 (the "License"); you may    */
/* not use this file except in compliance with the License. You may obtain    */
/* a copy of the License at                                                   */
/*                                                                            */
/* http://www.apache.org/licenses/LICENSE-2.0                                 */
/*                                                                            */
/* Unless required by applicable law or agreed to in writing, software        */
/* distributed under the License is distributed on an "AS IS" BASIS,          */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   */
/* See the License for the specific language governing permissions and        */
/* limitations under the License.                                             */
/* —------------------------------------------------------------------------ */

define(function(require) {
    /*
      DEPENDENCIES
     */

    var Notifier = require('utils/notifier');
    var Locale = require('utils/locale');
    var OpenNebula = require('opennebula');

    /*
      TEMPLATES
     */

    var TemplateEasyInfo = require('hbs!./cloud/html');
    var TemplateTable = require("utils/panel/template-table");
    /*
      CONSTANTS
     */

    var TAB_ID = require('../tabId');
    var PANEL_ID = require('./cloud/panelId');
    var RESOURCE = "User";
    var XML_ROOT = "USER";
    var settings_hbs = {};
    var settings;
    var datastores_hbs = [];
    var datastores;

    var rezerv_clone_datastores;
    var rezerv_clone_settings;
    var rezerv_settings_hbs;
    /*
      CONSTRUCTOR
     */

    function Panel(info, tabId) {

        this.tabId = tabId || TAB_ID;
        this.title = Locale.tr("Cloud");
        this.icon = "fa-list-alt";

        this.element = info[XML_ROOT];

        return this;
    }

    Panel.PANEL_ID = PANEL_ID;
    Panel.prototype.html = _html;
    Panel.prototype.setup = _setup;

    return Panel;

    /*
      FUNCTION DEFINITIONS
     */

    function _html() {

        return TemplateEasyInfo();
    }

    function _setup(context) {
        var that = this;
        that.onshow = _onShow(context, that);

        datastore_init();
        settings_init();

        return false;
    }

    function _onShow(context, that) {

        $.get("settings", function(data, status){
            OpenNebula.Datastore.list({success: function(r,res){
                    settings = data.response;
                    datastores = res;

                    datastores_hbs = [];
                    var check;
                    for(var key in datastores){
                        if (datastores[key].DATASTORE.TEMPLATE.TYPE == 'SYSTEM_DS'){
                            if (datastores[key].DATASTORE.TEMPLATE.DEPLOY == "TRUE"){
                                datastores_hbs.push({ID:datastores[key].DATASTORE.ID, NAME:datastores[key].DATASTORE.NAME,DISK_TYPE:datastores[key].DATASTORE.TEMPLATE.DRIVE_TYPE,DEPLOY:true});
                                check = 'checked ';
                            }else{
                                datastores_hbs.push({ID:datastores[key].DATASTORE.ID, NAME:datastores[key].DATASTORE.NAME,DISK_TYPE:datastores[key].DATASTORE.TEMPLATE.DRIVE_TYPE, DEPLOY:false});
                                check = '';
                            }
                            $('#datastores_body').append('<tr role="row"><td>'+ datastores[key].DATASTORE.ID +'</td><td>'+ datastores[key].DATASTORE.NAME +'</td>' +
                                '<td><select id="'+ datastores[key].DATASTORE.ID +'" style="width: 80%;" class="datastores_select_disk_type"></select></td>' +
                                '<td id="deploy_switch">' +
                                '<label class="tetswitch"><input type="checkbox" id="togBtn" '+ check +'><div class="tetslider round"></div></label></td></tr>');
                        }
                    }


                    settings_hbs = {};
                    for(var i in settings){
                        if (settings[i] != null){
                            if (settings[i].indexOf('{') == 0){
                                var tree = JSON.parse(settings[i]);
                                settings_hbs[i] = {bool_tree:true,value:tree};
                            }else{
                                settings_hbs[i] = {bool_tree:false,value:settings[i]};
                            }
                        }
                    }
                    console.log(settings_hbs);
                    var flag_circle;
                    for(var i in settings_hbs){

                        if (settings_hbs[i].bool_tree){
                            flag_circle = '<td class="td_key_setting" style="font-weight: bold;"><span id="setting_tree_circle"><a href="#"><i class="fa fa-arrow-circle-right"/></a></span>' +
                                '<span id="setting_tree_key_span" style="cursor: pointer;">'+ i +'</span></td>';
                            for(var j in settings_hbs[i].value){
                                flag_circle += '<tr class="tr_setting_'+ j +'" style="display: none">' +
                                    '<td class="td_key_setting" style="text-align: center;">'+ j +'</td>' +
                                    '<td class="td_value_setting">'+ settings_hbs[i].value[j] +'</td>' +
                                    '<td style="width: 60px;">' +
                                    '<span id="div_edit_setting">' +
                                    '<a id="div_edit_'+ j +'" class="edit_e" href="#"> <i class="fa fa-pencil-square-o"/></a>' +
                                    '</span>' +
                                    '<span id="div_minus_setting">' +
                                    '<a id="div_minus_'+ j +'" class="remove_x" href="#"> <i class="fa fa-trash-o right"/></a>' +
                                    '</span></td></tr>';
                            }
                        }else{
                            flag_circle = '<td class="td_key_setting" style="font-weight: bold;"><span>&#8195;'+ i +'</span></td>' +
                                '<td class="td_value_setting">'+ settings_hbs[i].value +'</td>' +
                                '<td style="width: 60px;">' +
                                '<span id="div_edit_setting">' +
                                '<a id="div_edit_'+ i +'" class="edit_e" href="#"> <i class="fa fa-pencil-square-o"/></a>' +
                                '</span>' +
                                '<span id="div_minus_setting">' +
                                '<a id="div_minus_'+ i +'" class="remove_x" href="#"> <i class="fa fa-trash-o right"/></a>' +
                                '</span></td>';
                        }

                        $('#settings_body').append('<tr class="tr_setting_'+ i +'">'+flag_circle+'</tr>');
                        $('#settings_key_vars').append('<option value="'+ i +'">');
                    }


                    if (settings.DISK_TYPES == undefined){
                        var disk_type = [];
                    }else{
                        var disk_type = settings['DISK_TYPES'].split(',');
                    }

                    var datastores_select = $('#datastores_body .datastores_select_disk_type');
                    var len =  datastores_select.length;for (var i = 0; i < len; i++) {
                        if (datastores_hbs[i].DISK_TYPE != undefined){
                            for(var k in disk_type){
                                if (datastores_hbs[i].DISK_TYPE == disk_type[k]){
                                    $(datastores_select[i]).append('<option selected>'+ disk_type[k] +'</option>');
                                }else{
                                    $(datastores_select[i]).append('<option>'+ disk_type[k] +'</option>');
                                }
                            }
                        }else{
                            $(datastores_select[i]).append('<option selected disabled>Select disk type</option>');
                            for(var k in disk_type){
                                $(datastores_select[i]).append('<option>'+ disk_type[k] +'</option>');
                            }
                        }
                    }

                    $('#datastores_body #0').append('<option selected disabled>Select disk type disabled</option>');
                    $('#datastores_body #0').prop('disabled',true);
                    $('#datastores_body #0').parent().next('#deploy_switch').children().children('#togBtn').prop('disabled',true);


                    for(var i in settings_hbs){
                        if (settings_hbs[i].bool_tree == true){
                            var kol = 0;
                            var pre_name = [];
                            for(var j in settings_hbs[i].value){
                                pre_name.push(j);
                                kol++
                                if (kol == 2){break;}
                            }
                            if (pre_name.length > 1){
                                if (Object.keys(settings_hbs[i].value).length > 2){
                                    $('.tr_setting_'+i).children('.td_key_setting').append('<small style="color: grey;">&emsp;'+pre_name[0]+', '+pre_name[1]+'...</small>');
                                }else{
                                    $('.tr_setting_'+i).children('.td_key_setting').append('<small style="color: grey;">&emsp;'+pre_name[0]+', '+pre_name[1]+'</small>');
                                }

                            }else{
                                $('.tr_setting_'+i).children('.td_key_setting').append('<small style="color: grey;">&emsp;'+pre_name[0]+'</small>');
                            }
                        }
                    }

                    rezerv_clone_datastores = $('tbody#datastores_body').clone();
                    rezerv_datastores_hbs = JSON.parse(JSON.stringify(datastores_hbs));

                    rezerv_clone_settings = $('tbody#settings_body').clone();
                    rezerv_settings_hbs = JSON.parse(JSON.stringify(settings_hbs));

                    set_events();

                }});
        });
    }

    function circle_event() {
        $('#settings_body #setting_tree_circle').off('click');
        $('#settings_body #setting_tree_key_span').off('click');

        $('#settings_body #setting_tree_circle').click(function () {
            if ($(this).children().children().attr('class') == 'fa fa-arrow-circle-right'){
                $(this).children().children().switchClass('fa-arrow-circle-right','fa-arrow-circle-down');
                $(this).parent().children('small').toggle();
            }else{
                $(this).children().children().switchClass('fa-arrow-circle-down','fa-arrow-circle-right');
                $(this).parent().children('small').toggle();
            }

            var name = $(this).next().text();
            for (var k in settings_hbs[name].value) {
                $('tr.tr_setting_' + name).nextAll('tr.tr_setting_' + k.replace(/\./g,'\\.')).eq(0).toggle();
            }

        });

        $('#settings_body #setting_tree_key_span').click(function () {
            $(this).prev('#setting_tree_circle').click();
        });
    }

    function edit_event() {
        $('#settings_body #div_edit_setting').off('click');
        $('#settings_body #div_edit_setting').click(function () {
            var tr_setting = $(this).parent().parent();
            var td_value = tr_setting.children('.td_value_setting');
            if (td_value.children('input').length > 0){
                var str = td_value.children('input.input_edit_value_setting').val();
                td_value.html(str);
                var key = tr_setting.attr('class').substring(11);
                for(var j in settings_hbs){
                    if (j == key){
                        settings_hbs[j].value = str;
                        return;
                    }else if(settings_hbs[j].bool_tree == true){
                        for(var k in settings_hbs[j].value){
                            if (k == key){
                                settings_hbs[j].value[k] = str;
                                return;
                            }
                        }
                    }
                }
            }else{
                var str = td_value.text();
                td_value.html("<input class='input_edit_value_setting' type='text'></input>");
                td_value.children('input.input_edit_value_setting').val(str);
            }
        });
    }

    function minus_event() {
        $('#settings_body #div_minus_setting').off('click');
        $('#settings_body #div_minus_setting').click(function () {

            var key = $(this).parent().parent().prevAll('tr').has('small').eq(0).attr('class').substring(11);
            var key1 = $(this).parent().parent().attr('class').substring(11);

            if (settings_hbs[key] != undefined){
                if(settings_hbs[key].bool_tree == true){
                    if(settings_hbs[key].value[key1] != undefined){
                        delete settings_hbs[key].value[key1];
                        var pre_name = Object.keys(settings_hbs[key].value);
                        if (pre_name.length == 0){
                            delete settings_hbs[key];
                            $(this).parent().parent().prev().remove();
                            $(this).parent().parent().remove();
                        }else{
                            $(this).parent().parent().remove();
                            $('.tr_setting_'+key).children('.td_key_setting').children('small').text('');
                            if (pre_name.length > 1){
                                if (pre_name.length > 2){
                                    $('.tr_setting_'+key).children('.td_key_setting').children('small').append('&emsp;'+pre_name[0]+', '+pre_name[1]+'...</small>');;
                                }else{
                                    $('.tr_setting_'+key).children('.td_key_setting').children('small').append('&emsp;'+pre_name[0]+', '+pre_name[1]+'</small>');;
                                }
                            }else{
                                $('.tr_setting_'+key).children('.td_key_setting').children('small').append('&emsp;'+pre_name[0]+'</small>');;
                            }
                        }
                    }
                }
            }
            if (settings_hbs[key1] != undefined){
                $(this).parent().parent().remove();
                delete settings_hbs[key1];
            }

        });
    }

    function set_events() {
        circle_event();
        edit_event();
        minus_event();
    }

    function datastore_init() {
        $('#datastores_but_reset').click(function () {

            $('tbody#datastores_body').remove();
            $("thead#datastores_thead").after(rezerv_clone_datastores);

            rezerv_clone_datastores = $('tbody#datastores_body').clone();

            var datastores = $('#datastores_body .datastores_select_disk_type');
            var len =  datastores.length;
            for (var i = 0; i < len; i++) {
                if (datastores_hbs[i].DISK_TYPE != undefined){
                    $(datastores[i]).val(datastores_hbs[i].DISK_TYPE);
                }else{
                    $(datastores[i]).val('Select disk type');
                }
            }
            $('#datastores_body #0').val('Select disk type disabled');
        });


        $('#datastores_but_submit').click(function () {
            console.log(datastores_hbs, datastores);
            var datastores = $('#datastores_body .datastores_select_disk_type');
            var len =  datastores.length;
            for (var i = 0; i < len; i++) {
                if (datastores_hbs[i].DISK_TYPE != $(datastores[i]).val()){
                    OpenNebula.Datastore.append({data:{id:datastores_hbs[i].ID,extra_param:'DRIVE_TYPE = '+$(datastores[i]).val()}});
                    datastores_hbs[i].DISK_TYPE = $(datastores[i]).val();
                    Notifier.notifyMessage('Changed disk type');
                }
                var dep = $(datastores[i]).parent().next('#deploy_switch').children().children('#togBtn').prop('checked');
                if (datastores_hbs[i].DEPLOY != dep){
                    if ($(datastores[i]).val() != null){
                        if (dep == true){
                            OpenNebula.Datastore.append({data:{id:datastores_hbs[i].ID,extra_param:'DEPLOY = TRUE'}});
                        }else{
                            OpenNebula.Datastore.append({data:{id:datastores_hbs[i].ID,extra_param:'DEPLOY = FALSE'}});
                        }
                        datastores_hbs[i].DEPLOY = dep;
                        Notifier.notifyMessage('Changed deploy');
                    }else{
                        Notifier.notifyError('Select disk type');
                    }

                }
            }
            rezerv_clone_datastores = $('tbody#datastores_body').clone();
        });

    }

    function settings_init() {
        $('#settings_but_reset').click(function () {
            $('tbody#settings_body').remove();
            $("thead#settings_thead").after(rezerv_clone_settings);
            settings_hbs = rezerv_settings_hbs;

            set_events();

            rezerv_settings_hbs = JSON.parse(JSON.stringify(settings_hbs));
            rezerv_clone_settings = $('tbody#settings_body').clone();
        });

        $('input[name="new_key_setting"]').keyup(function(){
            var that = this;
            $('datalist#settings_key1_vars').empty();
            var key = $(that).val();
            if (settings_hbs[key] != undefined){
                if (settings_hbs[key].bool_tree == true){
                    for(var i in settings_hbs[key].value){
                        $('datalist#settings_key1_vars').append('<option value="'+ i +'">');
                    }
                }else{
                    $('datalist#settings_value_vars').append('<option value="'+ settings_hbs[key].value +'">');
                }
            }
        });

        $('input[name="new_key1_setting"]').keyup(function(){
            var that = this;
            $('datalist#settings_value_vars').empty();
            var key = $('input[name="new_key_setting"]').val();
            var key1 = $(that).val();
            if (settings_hbs[key] != undefined){
                if (settings_hbs[key].value[key1] != undefined){
                    $('datalist#settings_value_vars').append('<option value="'+ settings_hbs[key].value[key1] +'">');
                }
            }
        });

        $('button#setting_new_field').click(function () {
            var new_key = $('input[name="new_key_setting"]').val();
            var new_key1 = $('input[name="new_key1_setting"]').val();
            var new_val =  $('input[name="new_value_setting"]').val();
            var len = settings_hbs.length;

            if (new_key != '' && new_val != ''){

                if (settings_hbs[new_key] != undefined){
                    if (settings_hbs[new_key].bool_tree == true && new_key1 != ''){
                        if (settings_hbs[new_key].value[new_key1] != undefined){
                            $('.tr_setting_'+new_key.replace(/\./g,'\\.')).nextAll('.tr_setting_'+new_key1.replace(/\./g,'\\.')).children('.td_value_setting').text(new_val);
                            settings_hbs[new_key].value[new_key1] = new_val;
                            //set_events();
                        }else{
                            var pre_name = [];
                            for(var j in settings_hbs[new_key].value){
                                pre_name.push(j);
                            }
                            var last_name = pre_name[pre_name.length - 1];
                            if ($('.tr_setting_'+new_key.replace(/\./g,'\\.')).nextAll('.tr_setting_'+last_name.replace(/\./g,'\\.')).css('display') == 'none'){
                                var styl = 'display: none;';
                            }else{
                                var styl = 'display: table-row';
                            }

                            $('.tr_setting_'+new_key.replace(/\./g,'\\.')).nextAll('.tr_setting_'+last_name.replace(/\./g,'\\.')).after('<tr class="tr_setting_'+new_key1+'" style="'+styl+'">' +
                                '<td class="td_key_setting" style="text-align: center;">'+new_key1+'</td>' +
                                '<td class="td_value_setting">'+new_val+'</td>' +
                                '<td style="width: 60px;">' +
                                '<span id="div_edit_setting">' +
                                '<a id="div_edit_'+new_key1+'" class="edit_e" href="#"> <i class="fa fa-pencil-square-o"></i></a>' +
                                '</span>' +
                                '<span id="div_minus_setting">' +
                                '<a id="div_minus_'+new_key1+'" class="remove_x" href="#"> <i class="fa fa-trash-o right"></i></a>' +
                                '</span></td></tr>'
                            );

                            settings_hbs[new_key].value[new_key1] = new_val;
                            $('.tr_setting_'+new_key.replace(/\./g,'\\.')).children('.td_key_setting').children('small').text('');
                            if (pre_name.length > 1){
                                $('.tr_setting_'+new_key.replace(/\./g,'\\.')).children('.td_key_setting').children('small').append('&emsp;'+pre_name[0]+', '+pre_name[1]+'...');
                            }else{
                                $('.tr_setting_'+new_key.replace(/\./g,'\\.')).children('.td_key_setting').children('small').append('&emsp;'+pre_name[0]+', '+new_key1);
                            }
                            set_events();
                        }
                    }else{
                        if (settings_hbs[new_key].bool_tree == false){
                            $('.tr_setting_'+new_key.replace(/\./g,'\\.')).children('.td_value_setting').text(new_val);
                        }
                        set_events();
                    }
                }else {
                    if (new_key1 == '') {
                        $('tbody#settings_body').append('<tr class="tr_setting_' + new_key + '">' +
                            '<td class="td_key_setting" style="font-weight: bold;">' +
                            '<span>&emsp;' + new_key + '</span>' +
                            '</td>' +
                            '<td class="td_value_setting">' + new_val + '</td>' +
                            ' <td style="width: 60px;">' +
                            '<span id="div_edit_setting">' +
                            '<a id="div_edit_' + new_key + '" class="edit_e" href="#"> <i class="fa fa-pencil-square-o"></i></a>' +
                            '</span>' +
                            '<span id="div_minus_setting">' +
                            '<a id="div_minus_' + new_key + '" class="remove_x" href="#"> <i class="fa fa-trash-o right"></i></a>' +
                            '</span></td></tr>'
                        );
                        settings_hbs[new_key] = {bool_tree: false, value: new_val};
                        set_events();
                    }else{
                        $('tbody#settings_body').append('<tr class="tr_setting_' + new_key + '">' +
                            '<td class="td_key_setting" style="font-weight: bold;">' +
                            '<span id="setting_tree_circle">' +
                            '<a href="#"><i class="fa fa-arrow-circle-down"></i></a></span>' +
                            '<span id="setting_tree_key_span" style="cursor: pointer;">' + new_key + '</span><small style="color: grey;display: none;">&emsp;' + new_key1 + '</small></td></tr>' +
                            '<tr class="tr_setting_' + new_key1 + '">' +
                            '<td class="td_key_setting" style="text-align: center;">' + new_key1 + '</td>' +
                            '<td class="td_value_setting">' + new_val + '</td>' +
                            ' <td style="width: 60px;">' +
                            '<span id="div_edit_setting">' +
                            '<a id="div_edit_' + new_key1 + '" class="edit_e" href="#"> <i class="fa fa-pencil-square-o"></i></a>' +
                            '</span>' +
                            '<span id="div_minus_setting">' +
                            '<a id="div_minus_' + new_key1 + '" class="remove_x" href="#"> <i class="fa fa-trash-o right"></i></a>' +
                            '</span></td></tr>'
                        );
                        settings_hbs[new_key] = {bool_tree: true, value: {}};
                        settings_hbs[new_key].value[new_key1] = new_val;
                        set_events();
                    }
                }
            }
        });

        $('#settings_but_submit').click(function () {
            for(var i in settings_hbs){
                if (settings[i] != undefined){
                    if (settings_hbs[i].bool_tree == true){
                        if (JSON.stringify(settings_hbs[i].value) != settings[i]){

                            var keys = {'added':[],'changed':[],'deleted':[]};
                            var obj_sett = JSON.parse(settings[i]);
                            for(var j in settings_hbs[i].value){
                                if (obj_sett[j] == undefined){
                                    keys.added.push(j);
                                }else if (settings_hbs[i].value[j] != obj_sett[j]){
                                    keys.changed.push(j);
                                }
                            }
                            for(var j in obj_sett){
                                if (settings_hbs[i].value[j] == undefined){
                                    keys.deleted.push(j);
                                }
                            }
                            $.ajax({
                                url: '/settings/'+i,
                                type: 'POST',
                                data: '{"body":"'+ getBodyStr(settings_hbs[i].value) +'"}',
                                success: function(msg) {

                                }
                            });
                            for(var j in keys){
                                if (keys[j].length != 0){
                                    Notifier.notifySubmit('Field have been '+ j,keys[j],i);
                                }
                            }
                            settings[i] = JSON.stringify(settings_hbs[i].value);
                        }
                    }else{
                        if (settings_hbs[i].value != settings[i]){
                            $.ajax({
                                url: '/settings/'+i,
                                type: 'POST',
                                data: '{"body":"'+ settings_hbs[i].value +'"}',
                                success: function(msg) {

                                }
                            });
                            Notifier.notifySubmit('Field have been changed',i);
                            settings[i] = settings_hbs[i].value;
                        }
                    }
                }else{
                    if (settings_hbs[i].bool_tree == true){
                        $.ajax({
                            url: '/settings',
                            type: 'POST',
                            data: '{"name":"'+i+'","body":"'+  getBodyStr(settings_hbs[i].value) +'"}',
                            success: function(msg) {

                            }
                        });
                        Notifier.notifySubmit('Field have been added',Object.keys(settings_hbs[i].value),i);
                        settings[i] = JSON.stringify(settings_hbs[i].value);
                    }else{
                        $.ajax({
                            url: '/settings',
                            type: 'POST',
                            data: '{"name":"'+ i +'","body":"'+ settings_hbs[i].value +'"}',
                            success: function(msg) {

                            }
                        });
                        Notifier.notifySubmit('Field have been added',i);
                        settings[i] = settings_hbs[i].value;
                    }
                }
            }
            var del_key = [];
            for(var i in settings){
                if (settings_hbs[i] == undefined){
                    $.ajax({
                        url: '/settings/'+i,
                        type: 'DELETE',
                        data: '{"name":"'+i+'"}',
                        success: function(msg) {

                        }
                    });
                    del_key.push(i);
                    delete settings[i];
                }
            }
            if (del_key.length != 0){
                Notifier.notifySubmit('Field has been deleted',del_key);
            }

            rezerv_clone_settings = $('tbody#settings_body').clone();
            rezerv_settings_hbs = JSON.parse(JSON.stringify(settings_hbs));

        });
    }


    function getBodyStr(obj) {
        var body_str = '{';
        var keys = Object.keys(obj);
        var last_item = keys[keys.length -1];
        var val1;
        for(var k in obj){
            val1 = JSON.stringify(JSON.stringify(obj[k]));
            if (last_item != k){
                body_str += '\\"'+k+'\\":\\"'+val1.slice(3,val1.length-3)+'\\",';
            }else{
                body_str += '\\"'+k+'\\":\\"'+val1.slice(3,val1.length-3)+'\\"}';
            }
        }
        return body_str;
    }

});