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
  var Locale = require('utils/locale');
  var Buttons = require('./ansible-tab/buttons');
  var Actions = require('./ansible-tab/actions');
  //var Table = require('./ansible-tab/datatable');

  var TAB_ID = require('./ansible-tab/tabId');
  //var DATATABLE_ID = "dataTableTemplates";

  var _dialogs = [
    require('./ansible-tab/dialogs/clone')
  ];

  var _panels = [
    require('./ansible-tab/panels/info'),
    require('./ansible-tab/panels/template')
  ];

  var _panelsHooks = [
    require('../utils/hooks/header')
  ];

  var _formPanels = [
    require('./ansible-tab/form-panels/create'),
    require('./ansible-tab/form-panels/import'),
    require('./ansible-tab/form-panels/instantiate')
  ];

  var Tab = {
    tabId: TAB_ID,
    title: Locale.tr("Automatization"),
    listHeader: Locale.tr("Playbooks"),
    infoHeader: Locale.tr("Playbook"),
    subheader: '<span>\
        <span class="total_templates"/> <small>'+Locale.tr("TOTAL")+'</small>\
      </span>',
    resource: 'Ansible',
    buttons: Buttons,
    actions: Actions,
    //dataTable: new Table(DATATABLE_ID, {actions: true, info: true}),
    panels: _panels,
    panelsHooks: _panelsHooks,
    formPanels: _formPanels,
    dialogs: _dialogs
  };

  return Tab;
});