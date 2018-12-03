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

    var RESOURCE = "Ansible";
    var XML_ROOT = "ansible_playbook";
    var TAB_ID = require('./tabId');

    var _commonActions = new CommonActions(OpenNebulaResource, RESOURCE, TAB_ID,
        XML_ROOT, Locale.tr("Ansible created"));

    var _actions = {
        "Ansible.list" : _commonActions.list(),
        "Ansible.show" : _commonActions.show(),
        "Ansible.refresh" : _commonActions.refresh(),
        "Ansible.delete" : _commonActions.del(),
        "Ansible.update_template" : _commonActions.updateTemplate(),
        "Ansible.append_template" : _commonActions.appendTemplate(),
        "Ansible.update_dialog" : _commonActions.checkAndShowUpdate(),
        "Ansible.rename": _commonActions.singleAction('rename'),

    };

    return _actions;
});
