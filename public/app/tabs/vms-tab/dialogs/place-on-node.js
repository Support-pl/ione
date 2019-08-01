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
    var TemplateHTML = require('hbs!./place-on-node/html');
    var Sunstone = require('sunstone');
    var Notifier = require('utils/notifier');
    var Tips = require('utils/tips');
    var OpenNebula = require('opennebula');
    var Settings = require('opennebula/settings');
    /*
      CONSTANTS
     */

    var DIALOG_ID = require('./place-on-node/dialogId');
    var TAB_ID = require('../tabId')
    var settings;

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

    Settings.cloud({success:function(r, res) {
            if (r.error != undefined){
                Notifier.notifyError(r.error);
                return false;
            }
            settings = r.response;
            Dialog.prototype.html = _html;
            Dialog.prototype.onShow = _onShow;
            Dialog.prototype.setup = _setup;
    }});

    return Dialog;

    /*
      FUNCTION DEFINITIONS
     */

    function _html() {
        return TemplateHTML({
            'dialogId': this.dialogId
        });
    }

    function _setup(context) {
        var that = this;

        Tips.setup(context);
        $('#' + DIALOG_ID + 'Form', context).submit(function() {

            $.each(Sunstone.getDataTable(TAB_ID).elements(), function(index, elem) {
                var extra_info = {};

                extra_info['enforce'] = false;
                var vm_info = {}
                OpenNebula.VM.show({data:{id:elem},success: function(r,res){
                        vm_info['vm_hypervisor'] = res.VM.USER_TEMPLATE.HYPERVISOR;
                        vm_info['vm_drive'] = res.VM.USER_TEMPLATE.DRIVE;

                        var nodes = JSON.parse(settings.NODES_DEFAULT);
                        for (var indx in nodes)
                        if (~indx.indexOf(vm_info['vm_hypervisor'].toUpperCase())){
                            extra_info['host_id'] = nodes[indx];
                        }

                        OpenNebula.Datastore.list({success: function(r,res){
                                for(var key in res){
                                    if (res[key].DATASTORE.TEMPLATE.DEPLOY == 'TRUE' && res[key].DATASTORE.TEMPLATE.DRIVE_TYPE == vm_info['vm_drive'] && res[key].DATASTORE.TEMPLATE.TYPE == 'SYSTEM_DS'){
                                        extra_info['ds_id'] = res[key].DATASTORE.ID;
                                        break;
                                    }
                                }

                                if (extra_info['ds_id'] != undefined){
                                    Sunstone.runAction("VM.deploy_action", elem, extra_info);
                                }else{
                                    Notifier.notifyError('No datastor');
                                }

                                Sunstone.getDialog(DIALOG_ID).hide();
                                Sunstone.getDialog(DIALOG_ID).reset();
                        }});
                }});
            });
            return false;
        });
        return false;
    }

    function _onShow(dialog) {
        this.setNames( {tabId: TAB_ID} );

        return false;
    }
});
