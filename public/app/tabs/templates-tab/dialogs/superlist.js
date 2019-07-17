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

    var BaseDialog = require('utils/dialogs/dialog');
    var TemplateHTML = require('hbs!./superlist/html');
    var Sunstone = require('sunstone');
    var Notifier = require('utils/notifier');
    var OpenNebulaTemplate = require('opennebula/template');

    /*
      CONSTANTS
     */

    var DIALOG_ID = require('./superlist/dialogId');
    var superlist = [];
    var superlist_dataTable;
    /*
      CONSTRUCTOR
     */

    function Dialog() {
        this.dialogId = DIALOG_ID;
        BaseDialog.call(this);
    };

    Dialog.DIALOG_ID = DIALOG_ID;
    Dialog.prototype = Object.create(BaseDialog.prototype);
    Dialog.prototype.constructor = Dialog;
    Dialog.prototype.html = _html;
    Dialog.prototype.onShow = _onShow;
    Dialog.prototype.setup = _setup;
    Dialog.prototype.setParams = _setParams;

    return Dialog;

    /*
      FUNCTION DEFINITIONS
     */

    function _html() {
        return TemplateHTML({
            'dialogId': this.dialogId
        });
    }

    function _setParams(params) {
        this.params = params;
        this.tabId = params.tabId;
        this.resource = params.resource;
    }

    function _setup(context) {
        var that = this;
        $('#'+DIALOG_ID+'input').on('input',function() {
            superlist_dataTable.fnClearTable();
            superlist_dataTable.fnAddData(search_oc($(this).val()));
            superlist_dataTable.fnSort( [ [1, "asc"] ] );
            superlist_dataTable.$('tr').css('border-top','1px solid lightgray');
        });

        $('#' + DIALOG_ID + '_datatable', context).on('click', 'tbody [role="row"]', function () {
            var cells = superlist_dataTable.fnGetData(this);
            var os_name = cells[1];
            $('[wizard_field="OS_IMAGE"]').val(os_name);
            $('#OC_image').empty();
            $('#OC_image').append(cells[0]);
            Sunstone.getDialog('superlistTemplateDialog').hide();
        });

    }

    function _onShow(context) {
        $('#dialog_header', context).text(this.params.dialog.label);
        $('#superlistTemplateDialog').css('top','30px');
        superlist_dataTable = $('#' + DIALOG_ID + '_datatable', context).dataTable({
            scrollY: '380px',
            scrollCollapse: true,
            "bInfo": false,
            "bPaginate": false,
            'aoColumnDefs': [{
                'bSortable': false,
                'aTargets': [0]
            }]
        });

        setSuperlist(JSON.parse(this.params.dialog.field_data));
        superlist_dataTable.fnClearTable();
        superlist_dataTable.fnAddData(superlist);
        superlist_dataTable.fnSort( [ [1, "asc"] ] );
        superlist_dataTable.$('tr').css('border-top','1px solid lightgray');
        return false;
    }

    function setSuperlist(setting_field) {
        superlist = [];
        for(var i in setting_field){
            superlist.push([getLogo(i),i]);
        }
    }

    function getLogo(search_name) {
        if (search_name != ''){
            var logos = config.vm_logos;
            for(var i in logos){
                var name_first = logos[i].name.toLowerCase().split(' ')[0];
                if (search_name.toLowerCase().indexOf(name_first) >= 0){
                    if (name_first == 'windows'){
                        return '<img id="'+search_name+'" class="datatable_item" src="'+logos[i*1+1].path+'" style="height: 50px;width: 50px;">';
                    }else{
                        return '<img id="'+search_name+'" class="datatable_item" src="'+logos[i].path+'" style="height: 50px;width: 50px;">';
                    }
                    break;
                }
            }
        }
        return '<img id="'+search_name+'" class="datatable_item" src="">';
    }

    function search_oc(search_name) {
        var items = [];
        if (search_name != ''){
            for(var i in superlist){
                if (superlist[i][1].toLowerCase().indexOf(search_name.toLowerCase()) >= 0){
                    items.push(superlist[i]);
                }
            }
        }else{
            items = superlist;
        }
        return items;
    }

});
