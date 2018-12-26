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
    var Sunstone = require('sunstone');
    var Notifier = require('utils/notifier');
    var Locale = require('utils/locale');
    var DataTable = require('./datatable');
    var OpenNebulaResource = require('opennebula/ansible-process');
    var OpenNebulaAction = require('opennebula/action');
    var CommonActions = require('utils/common-actions');
    var Navigation = require('utils/navigation');
    var CREATE_DIALOG_ID = require('./form-panels/create/formPanelId');
    var CLONE_DIALOG_ID = require('./dialogs/clone/dialogId');

    var RESOURCE = "AnsibleProcess";
    var XML_ROOT = "ANSIBLE_PROCESS";
    var TAB_ID = require('./tabId');

    var _commonActions = new CommonActions(OpenNebulaResource, RESOURCE, TAB_ID,
        XML_ROOT, Locale.tr("Ansible created"));

    var _actions = {
        "AnsibleProcess.create" : _commonActions.create(),
        "AnsibleProcess.list" : _commonActions.list(),
        "AnsibleProcess.show" : _commonActions.show(),
        "AnsibleProcess.refresh" : _commonActions.refresh(),
        "AnsibleProcess.delete" : _commonActions.multipleAction('del'),
        "AnsibleProcess.create_dialog" : _commonActions.showCreate(CREATE_DIALOG_ID),
        "AnsibleProcess.update_dialog" : _commonActions.checkAndShowUpdate(),
        "AnsibleProcess.show_to_update" : _commonActions.showUpdate(CREATE_DIALOG_ID),
        "AnsibleProcess.run" : {
            type: "multiple",
            call: OpenNebulaResource.run,
            callback: function(request, response) {
              Notifier.notifyCustom(Locale.tr("Process started"));
            },
            elements: function(opts) {
              return Sunstone.getDataTable(TAB_ID).elements(opts);
            },
            error: function(request, response){
              Notifier.onError(request, response);
            },
            notify: false
          }
    };


    return _actions;
});
