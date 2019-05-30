/* -------------------------------------------------------------------------- */
/* Copyright 2002-2017, OpenNebula Project, OpenNebula Systems                */
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
/* -------------------------------------------------------------------------- */

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
    var for_hbs = [];
    var settings;
    var datastores_hbs = [];
    var datastores
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

    $.get("settings", function(data, status){
        OpenNebula.Datastore.list({success: function(r,res){
                settings = data.response;
                datastores = res;
                Panel.prototype.html = _html;
                Panel.prototype.setup = _setup;
        }});
    });


    return Panel;

    /*
      FUNCTION DEFINITIONS
     */

    function _html() {
        datastores_hbs = [];
        for(var key in datastores){
            if (datastores[key].DATASTORE.TEMPLATE.TYPE == 'SYSTEM_DS'){
                if (datastores[key].DATASTORE.TEMPLATE.DEPLOY == "TRUE"){
                    datastores_hbs.push({ID:datastores[key].DATASTORE.ID, NAME:datastores[key].DATASTORE.NAME,DISK_TYPE:datastores[key].DATASTORE.TEMPLATE.DRIVE_TYPE,DEPLOY:true});
                }else{
                    datastores_hbs.push({ID:datastores[key].DATASTORE.ID, NAME:datastores[key].DATASTORE.NAME,DISK_TYPE:datastores[key].DATASTORE.TEMPLATE.DRIVE_TYPE, DEPLOY:false});
                }

            }
        }

        for_hbs = [];
        for(var i in settings){
            if (settings[i] != null){
                if (settings[i].indexOf('{') == 0){
                    var tree = JSON.parse(settings[i]);
                    var arr = []
                    for(var j in tree){
                        arr.push({key1:j,value1:tree[j]});
                    }
                    if(i.indexOf('COST') != -1){
                        for_hbs.unshift({key:i,bool_tree:true,value:arr});
                    }else{
                        for_hbs.push({key:i,bool_tree:true,value:arr});
                    }
                }else{
                    if(i.indexOf('COST') != -1){
                        for_hbs.unshift({key:i,bool_tree:false,value:settings[i]});
                    }else{
                        for_hbs.push({key:i,bool_tree:false,value:settings[i]});
                    }
                }
            }
        }
        console.log(for_hbs);
        return TemplateEasyInfo({'settings':for_hbs,'datastores':datastores_hbs});
    }

    function _setup(context) {
        var that = this;
        if (settings['DISK_TYPES'] == undefined){
            var disk_type = [];
        }else{
            var disk_type = settings['DISK_TYPES'].split(',');
        }

        var datastores = $('#datastores_body .datastores_select_disk_type');
        var len =  datastores.length;

        for (var i = 0; i < len; i++) {
            if (datastores_hbs[i].DISK_TYPE != undefined){
                for(var k in disk_type){
                    if (datastores_hbs[i].DISK_TYPE == disk_type[k]){
                        $(datastores[i]).append('<option selected>'+ disk_type[k] +'</option>');
                    }else{
                        $(datastores[i]).append('<option>'+ disk_type[k] +'</option>');
                    }
                }
            }else{
                $(datastores[i]).append('<option selected disabled>Select disk type</option>');
                for(var k in disk_type){
                    $(datastores[i]).append('<option>'+ disk_type[k] +'</option>');
                }
            }
        }

        $('#datastores_body #0').append('<option selected disabled>Select disk type disabled</option>');
        $('#datastores_body #0').prop('disabled',true);
        $('#datastores_body #0').parent().next('#deploy_switch').children().children('#togBtn').prop('disabled',true);


        for(var i in for_hbs){
            if (for_hbs[i].bool_tree == true){
                if (for_hbs[i].value.length != 1){
                    $('.tr_setting_'+for_hbs[i].key).children('.td_key_setting').append('<small style="color: grey;">&emsp;'+for_hbs[i].value[0].key1+', '+for_hbs[i].value[1].key1+'...</small>');
                }else{
                    $('.tr_setting_'+for_hbs[i].key).children('.td_key_setting').append('<small style="color: grey;">&emsp;'+for_hbs[i].value[0].key1+'</small>');
                }

            }
        }

        var rezerv_clone_settings = $('tbody#settings_body').clone();
        var rezerv_for_hbs = JSON.parse(JSON.stringify(for_hbs));
        set_events();

        $('#datastores_but_reset').click(function () {
            for (var i = 1; i < len; i++) {
                $(datastores[i]).val(datastores_hbs[i].DISK_TYPE);
                $(datastores[i]).parent().next('#deploy_switch').children().children('#togBtn').prop('checked',datastores_hbs[i].DEPLOY);
            }
        });


        $('#datastores_but_submit').click(function () {
            for (var i = 1; i < len; i++) {
                if (datastores_hbs[i].DISK_TYPE != $(datastores[i]).val()){
                    OpenNebula.Datastore.append({data:{id:datastores_hbs[i].ID,extra_param:'DRIVE_TYPE = '+$(datastores[i]).val()}});
                }
                var dep = $(datastores[i]).parent().next('#deploy_switch').children().children('#togBtn').prop('checked');
                if (datastores_hbs[i].DEPLOY != dep){
                    if (dep == true){
                        OpenNebula.Datastore.append({data:{id:datastores_hbs[i].ID,extra_param:'DEPLOY = TRUE'}});
                    }else{
                        OpenNebula.Datastore.append({data:{id:datastores_hbs[i].ID,extra_param:'DEPLOY = FALSE'}});
                    }
                }
            }
        });



        $('#settings_but_reset').click(function () {
            $('tbody#settings_body').remove();
            $("thead#settings_thead").after(rezerv_clone_settings);
            for_hbs = rezerv_for_hbs;

            set_events()

            rezerv_for_hbs = JSON.parse(JSON.stringify(for_hbs));
            rezerv_clone_settings = $('tbody#settings_body').clone();
        });

        $('input[name="new_key_setting"]').keyup(function(){
            var that = this;
            $('datalist#settings_key1_vars').empty();
            $('#settings_key_vars option').each(function(indx, element){
                if ($(that).val() == $(element).val()){
                    var tree = JSON.parse(settings[$(that).val()]);
                    for(var i in tree){
                        $('datalist#settings_key1_vars').append('<option value="'+ i +'">');
                    }
                }
            });
        });

        $('input[name="new_key1_setting"]').keyup(function(){
            var that = this;
            $('datalist#settings_value_vars').empty();
            $('#settings_key1_vars option').each(function(indx, element){
                if ($(that).val() == $(element).val()){
                    var tree = JSON.parse(settings[$('input[name="new_key_setting"]').val()]);
                    $('datalist#settings_value_vars').append('<option value="'+ tree[$(this).val()] +'">');
                }
            });
        });

        $('button#setting_new_field').click(function () {
            var new_key = $('input[name="new_key_setting"]').val();
            var new_key1 = $('input[name="new_key1_setting"]').val();
            var new_val =  $('input[name="new_value_setting"]').val();
            var len = for_hbs.length;

            if (new_key != '' && new_val != ''){
                for (var i = 0; i < len; i++){
                    if(for_hbs[i].key == new_key){
                        if (for_hbs[i].bool_tree == true && new_key1 != ''){
                            var last_itm;
                            for(var j in for_hbs[i].value){
                                if (for_hbs[i].value[j].key1 == new_key1){
                                    $('.tr_setting_'+new_key).nextAll('.tr_setting_'+new_key1).children('.td_value_setting').text(new_val);
                                    for_hbs[i].value[j].value1 = new_val;
                                    set_events();
                                    return;
                                }
                                last_itm = for_hbs[i].value[j].key1;
                            }

                            if ($('.tr_setting_'+last_itm).css('display') == 'none'){
                                var styl = 'display: none;';
                            }else{
                                var styl = 'display: table-row';
                            }

                            $('.tr_setting_'+last_itm).after('<tr class="tr_setting_'+new_key1+'" style="'+styl+'">' +
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

                            for_hbs[i].value.push({key1:new_key1,value1:new_val});
                            $('.tr_setting_'+for_hbs[i].key).children('.td_key_setting').children('small').remove();
                            if ($('.tr_setting_'+for_hbs[i].key).children('.td_key_setting').children('small').css('display') == 'none'){
                                $('.tr_setting_'+for_hbs[i].key).children('.td_key_setting').append('<small style="color: grey;display: none">&emsp;'+for_hbs[i].value[0].key1+', '+for_hbs[i].value[1].key1+'...</small>');
                            }else{
                                $('.tr_setting_'+for_hbs[i].key).children('.td_key_setting').append('<small style="color: grey;">&emsp;'+for_hbs[i].value[0].key1+', '+for_hbs[i].value[1].key1+'...</small>');
                            }

                            set_events()
                            return;
                        }else{
                            if (for_hbs[i].bool_tree == false){
                                $('.tr_setting_'+for_hbs[i].key).children('.td_value_setting').text(new_val);
                            }
                            set_events()
                            return;
                        }
                    }
                }
                if (new_key1 == ''){
                    $('tbody#settings_body').append('<tr class="tr_setting_'+new_key+'">' +
                        '<td class="td_key_setting" style="font-weight: bold;">' +
                        '<span>&emsp;'+new_key+'</span>' +
                        '</td>' +
                        '<td class="td_value_setting">'+new_val+'</td>' +
                        ' <td style="width: 60px;">' +
                        '<span id="div_edit_setting">' +
                        '<a id="div_edit_'+new_key+'" class="edit_e" href="#"> <i class="fa fa-pencil-square-o"></i></a>' +
                        '</span>' +
                        '<span id="div_minus_setting">' +
                        '<a id="div_minus_'+new_key+'" class="remove_x" href="#"> <i class="fa fa-trash-o right"></i></a>' +
                        '</span></td></tr>'
                    );
                    for_hbs.push({key: new_key,bool_tree:false,value:new_val});
                    set_events();
                }else{
                    $('tbody#settings_body').append('<tr class="tr_setting_'+new_key+'">' +
                        '<td class="td_key_setting" style="font-weight: bold;">' +
                        '<span id="setting_tree_circle">' +
                        '<a href="#"><i class="fa fa-circle-o"></i></a></span>' +
                        '<span id="setting_tree_key_span" style="cursor: pointer;">'+new_key+'</span><small style="color: grey;display: none;">&emsp;'+new_key1+'</small></td></tr>'+
                        '<tr class="tr_setting_'+new_key1+'">' +
                        '<td class="td_key_setting" style="text-align: center;">'+new_key1+'</td>' +
                        '<td class="td_value_setting">'+new_val+'</td>' +
                        ' <td style="width: 60px;">' +
                        '<span id="div_edit_setting">' +
                        '<a id="div_edit_'+new_key1+'" class="edit_e" href="#"> <i class="fa fa-pencil-square-o"></i></a>' +
                        '</span>' +
                        '<span id="div_minus_setting">' +
                        '<a id="div_minus_'+new_key1+'" class="remove_x" href="#"> <i class="fa fa-trash-o right"></i></a>' +
                        '</span></td></tr>'
                    );
                    for_hbs.push({key: new_key,bool_tree:true,value:[{key1:new_key1, value1:new_val}]});
                    set_events();
                }
            }

        });

        $('#settings_but_submit').click(function () {
            for(var i in for_hbs){
                var check = false;
                for(var j in settings){
                    if (for_hbs[i].key == j){
                        if (for_hbs[i].bool_tree == true){
                            var body_str = '{';
                            var len = for_hbs[i].value.length - 1;
                            for(var k in for_hbs[i].value){
                                var val1 = JSON.stringify(JSON.stringify(for_hbs[i].value[k].value1));
                                if (k != len){
                                    body_str += '\\"'+for_hbs[i].value[k].key1+'\\":\\"'+val1.slice(3,val1.length-3)+'\\",';
                                }else{
                                    body_str += '\\"'+for_hbs[i].value[k].key1+'\\":\\"'+val1.slice(3,val1.length-3)+'\\"}';
                                }
                            }
                            if (body_str.replace(/\\"/g,'\"').replace(/\\\\\\"/g,'\\"') != settings[j]){

                                $.ajax({
                                    url: '/settings/'+j,
                                    type: 'POST',
                                    data: '{"body":"'+ body_str +'"}',
                                    success: function(msg) {
                                        Notifier.notifySubmit('Field have been added');
                                    }
                                });
                                settings[j] = body_str;
                            }
                            check = true;
                            break;
                        }else{
                            if(for_hbs[i].value != settings[j]){
                                $.ajax({
                                    url: '/settings/'+j,
                                    type: 'POST',
                                    data: '{"body":"'+ for_hbs[i].value +'"}',
                                    success: function(msg) {
                                        Notifier.notifySubmit('Field have been added')
                                    }
                                });
                                settings[j] = for_hbs[i].value;
                            }
                            check = true;
                            break;
                        }
                    }
                }
                if(check == false){
                    if (for_hbs[i].bool_tree == true){
                        var body_str = '{';
                        var len = for_hbs[i].value.length - 1;
                        for(var k in for_hbs[i].value){
                            var val1 = JSON.stringify(JSON.stringify(for_hbs[i].value[k].value1));
                            if (k != len){
                                body_str += '\\"'+for_hbs[i].value[k].key1+'\\":\\"'+val1.slice(3,val1.length-3)+'\\",';
                            }else{
                                body_str += '\\"'+for_hbs[i].value[k].key1+'\\":\\"'+val1.slice(3,val1.length-3)+'\\"}';
                            }
                        }

                        $.ajax({
                            url: '/settings',
                            type: 'POST',
                            data: '{"name":"'+for_hbs[i].key+'","body":"'+ body_str +'"}',
                            success: function(msg) {
                                Notifier.notifySubmit('Field have been added');
                                $.get("settings", function(data, status){
                                    settings = data.response;
                                });
                            }
                        });
                    }else{
                        $.ajax({
                            url: '/settings',
                            type: 'POST',
                            data: '{"name":"'+ for_hbs[i].key +'","body":"'+ for_hbs[i].value +'"}',
                            success: function(msg) {
                                Notifier.notifySubmit('Field have been added');
                                $.get("settings", function(data, status){
                                    settings = data.response;
                                });
                            }
                        });
                    }
                }
            }

            for(var i in settings){
                check = false;
                for(var j in for_hbs){
                    if (i == for_hbs[j].key){
                        check = true
                    }
                }
                if (check == false && i != ''){
                    $.ajax({
                        url: '/settings/'+i,
                        type: 'DELETE',
                        data: '{"name":"'+i+'"}',
                        success: function(msg) {
                            Notifier.notifySubmit('Field has been deleted');
                            $.get("settings", function(data, status){
                                settings = data.response;
                            });
                        }
                    });
                }
            }
        });

        return false;
    }


    function circle_event() {
        $('#settings_body #setting_tree_circle').click(function () {
                if ($(this).children().children().attr('class') == 'fa fa-circle'){
                    $(this).children().children().switchClass('fa-circle','fa-circle-o');
                    $(this).parent().children('small').toggle();
                }else{
                    $(this).children().children().switchClass('fa-circle-o','fa-circle');
                    $(this).parent().children('small').toggle();
                }
                var len = for_hbs.length;
                for (var j = 0; j < len; j++) {
                    if (for_hbs[j].key == $(this).next().text()) {
                        for (var k in for_hbs[j].value) {
                            $('tr.tr_setting_' + for_hbs[j].key).nextAll('tr.tr_setting_' + for_hbs[j].value[k].key1).eq(0).toggle();
                        }
                        return;
                    }
                }
        });

        $('#settings_body #setting_tree_key_span').click(function () {
            $(this).parent().children('#setting_tree_circle').click();
        });
    }

    function edit_event() {
        $('#settings_body #div_edit_setting').click(function () {
                var tr_setting = $(this).parent().parent();
                var td_value = tr_setting.children('.td_value_setting');

                if (td_value.children('input').length > 0){
                    var str = td_value.children('input.input_edit_value_setting').val();
                    td_value.html(str);
                    var key = tr_setting.attr('class').substring(11);
                    for(var j in for_hbs){
                        if (for_hbs[j].key == key){
                            for_hbs[j].value = str;
                            return;
                        }else if(for_hbs[j].bool_tree == true){
                            for(var k in for_hbs[j].value){
                                if (for_hbs[j].value[k].key1 == key){
                                    for_hbs[j].value[k].value1 = str;
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

        $('#settings_body #div_minus_setting').click(function () {
                var key1 = $(this).parent().parent().children('.td_key_setting').text();
                for(var j in for_hbs){
                    if(for_hbs[j].bool_tree == true){
                        for(var k in for_hbs[j].value){
                            if(for_hbs[j].value[k].key1 == key1){
                                for_hbs[j].value.splice(k,1);
                                if (for_hbs[j].value.length == 0){
                                    for_hbs.splice(j,1)
                                    $(this).parent().parent().prev().remove();
                                    $(this).parent().parent().remove();
                                    return;
                                }else{
                                    $(this).parent().parent().remove();
                                    return;
                                }
                            }
                        }
                    }
                }

                var key = $(this).parent().parent().attr('class').substring(11);
                for(var j in for_hbs){
                    if (for_hbs[j].key == key){
                        for_hbs.splice(j,1);
                        $(this).parent().parent().remove();
                        return;
                    }
                }
        });
    }

    function set_events() {
        circle_event();
        edit_event();
        minus_event();
    }

});
