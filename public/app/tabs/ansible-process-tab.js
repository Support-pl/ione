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
  var Buttons = require('./ansible-process-tab/buttons');
  var Actions = require('./ansible-process-tab/actions');
  var Table = require('./ansible-process-tab/datatable');

  var TAB_ID = require('./ansible-process-tab/tabId');
  var DATATABLE_ID = "dataTableAnsibleProcess";


  var _dialogs = [
    require('./ansible-process-tab/dialogs/clone')
  ];

  var _panels = [
   require('./ansible-process-tab/panels/info'),
   require('./ansible-process-tab/panels/body')
  ];
  

  //var _panelsHooks = [
  //  require('../utils/hooks/header')
  //];

  var _formPanels = [
   require('./ansible-process-tab/form-panels/create')
  ];


  var Tab = {
    tabId: TAB_ID,
    title: Locale.tr("Processes"),
    icon: 'fa-cogs',
    listHeader: Locale.tr("Processes"),
    infoHeader: Locale.tr("Processe"),
    subheader: '<span>\
        <span class="total_processes"/> <small>'+Locale.tr("TOTAL")+'</small>\
      </span>',
    resource: 'Ansible_process',
    buttons: Buttons,
    actions: Actions,
    dataTable: new Table(DATATABLE_ID, {actions: true, info: true}),
    panels: _panels,
    formPanels: _formPanels,
    dialogs: _dialogs,
    tabClass: "subTab",
    parentTab: "automatization-top-tab",
  };
  //console.log(content);

  return Tab;
});
