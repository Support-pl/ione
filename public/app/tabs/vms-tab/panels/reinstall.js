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

    var Locale = require('utils/locale');
    var Config = require('sunstone-config');
    var Sunstone = require('sunstone');
    var Humanize = require('utils/humanize');
    var Notifier = require('utils/notifier');
    var OpenNebulaVM = require('opennebula/vm');
    var TemplateUtils = require('utils/template-utils');

    /*
      CONSTANTS
     */

    var TAB_ID = require('../tabId');
    var PANEL_ID = require('./reinstall/panelId');
    var REINSTALL_DIALOG_ID = require('../dialogs/reinstall/dialogId');
    var REVERT_DIALOG_ID = require('../dialogs/revert/dialogId');
    var RESOURCE = "VM"
    var XML_ROOT = "VM"
    /*
      CONSTRUCTOR
     */

    function Panel(info) {
        this.panelId = PANEL_ID;
        this.title = Locale.tr("reinstall");
        this.icon = "fa-laptop";

        this.element = info[XML_ROOT];

        return this;
    };

    Panel.PANEL_ID = PANEL_ID;
    Panel.prototype.html = _html;
    Panel.prototype.setup = _setup;

    return Panel;

    /*
      FUNCTION DEFINITIONS
     */

    function _html() {
        var that = this;
        var html = '<form id="snapshot_form" vmid="' + that.element.ID + '" >\
      <div class="row">\
      <div class="large-12 columns">\
         <table class="info_table dataTable">\
           <thead>\
             <tr>\
                <th>' + Locale.tr("ID") + '</th>\
                <th>' + Locale.tr("Name") + '</th>\
                <th>' + Locale.tr("Timestamp") + '</th>\
                <th>' + Locale.tr("Actions") + '</th>\
                <th>'

        if (Config.isTabActionEnabled("vms-tab", "VM.snapshot_create")) {
            // If VM is not RUNNING, then we forget about the attach disk form.
            if (that.element.STATE == OpenNebulaVM.STATES.ACTIVE && that.element.LCM_STATE == OpenNebulaVM.LCM_STATES.RUNNING) {
                html += '\
           <button id="reinstall" class="provision_reinstall_confirm_button" >' + Locale.tr("Reinstall") + '</button>'
            } else {
                html += '\
           <button id="reinstall" class="provision_reinstall_confirm_button" disabled="disabled">' + Locale.tr("Reinstall") + '</button>'
            }
        }

        html +=  '</th>\
              </tr>\
           </thead>\
           <tbody>';

        return html;
    }

    function _setup(context) {
        var that = this;
        context.on("click", ".provision_reinstall_confirm_button", function(){
            var button = $(this);
            var vm_id = $(".provision_info_vm", context).attr("vm_id");

            var template;
            OpenNebula.Template.list({data:{},success: function(a,b){template=b}});

            function func(){
                for (key in template){
                    console.log(template[key].VMTEMPLATE.TEMPLATE.PAAS_ACCESSIBLE);
                };
            }
            setTimeout(func,1000);
            return false;
        });
    }
});
