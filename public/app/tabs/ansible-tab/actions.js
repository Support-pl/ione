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
    var OpenNebulaResource = require('opennebula/ansible');
    var OpenNebulaAction = require('opennebula/action');
    var CommonActions = require('utils/common-actions');
    var Navigation = require('utils/navigation');
    var CREATE_DIALOG_ID = require('./form-panels/create/formPanelId');
    var CLONE_DIALOG_ID = require('./dialogs/clone/dialogId');

    var RESOURCE = "Ansible";
    var XML_ROOT = "ANSIBLE";
    var TAB_ID = require('./tabId');

    var _commonActions = new CommonActions(OpenNebulaResource, RESOURCE, TAB_ID,
        XML_ROOT, Locale.tr("Ansible created"));

    var _actions = {
        "Ansible.create" : _commonActions.create(),
        "Ansible.list" : _commonActions.list(),
        "Ansible.show" : _commonActions.show(),
        "Ansible.refresh" : _commonActions.refresh(),
        "Ansible.delete" : _commonActions.del(),
        "Ansible.update" : _commonActions.update(),
        "Ansible.chmod" : _commonActions.singleAction('chmod'),
        "Ansible.chown": _commonActions.multipleAction('chown'),
        "Ansible.chgrp": _commonActions.multipleAction('chgrp'),
        "Ansible.rename": _commonActions.singleAction('rename'),
        "Ansible.create_dialog" : _commonActions.showCreate(CREATE_DIALOG_ID),
        "Ansible.update_dialog" : _commonActions.checkAndShowUpdate(),
        "Ansible.show_to_update" : _commonActions.showUpdate(CREATE_DIALOG_ID),
        "Ansible.clone_dialog"  : {
            type: "custom",
            call: function(){
              Sunstone.getDialog(CLONE_DIALOG_ID).setParams(
                { tabId : TAB_ID,
                  resource : RESOURCE
                });
              Sunstone.getDialog(CLONE_DIALOG_ID).reset();
              Sunstone.getDialog(CLONE_DIALOG_ID).show();
            }
        },
        "Ansible.clone" : {
            type: "single",
            call: OpenNebulaResource.clone,
            callback: function(request, response) {
              console.log(response);
              OpenNebulaAction.clear_cache(RESOURCE);
              Notifier.notifyCustom(Locale.tr("Ansible Playbook created"),
                Navigation.link(" ID: " + response.response, "ansible-tab", response.response),
                false);
            },
            error: Notifier.onError,
            notify: true
        },
        "Ansible.run" :{
            type: 'single',
            call: function (){
                var pl_book_id = Sunstone.getDataTable('ansible-tab').elements()[0];
                $('#ansible_'+pl_book_id).prop('checked',true);

                Sunstone.showFormPanel('ansible-process-tab','createAnsibleForm','create')
            }
        }
    };


    return _actions;
});
