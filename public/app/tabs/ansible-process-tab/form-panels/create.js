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

    var BaseFormPanel = require('utils/form-panels/form-panel');
    var Sunstone = require('sunstone');
    var Locale = require('utils/locale');
    var Tips = require('utils/tips');
    var Notifier = require('utils/notifier');
    var ResourceSelect = require('utils/resource-select');
    var Config = require('sunstone-config');
    var WizardFields = require('utils/wizard-fields');
    var OpenNebula = require('opennebula');
    var CommonActions = require('utils/common-actions');
    var VMTable = require('tabs/vms-tab/datatable');

    /*
      TEMPLATES
     */

    var TemplateWizardHTML = require('hbs!./create/wizard');

    /*
      CONSTANTS
     */

    var FORM_PANEL_ID = require('./create/formPanelId');
    var TAB_ID = require('../tabId');

    /*
      CONSTRUCTOR
     */

    function FormPanel() {

        this.formPanelId = FORM_PANEL_ID;
        this.tabId = TAB_ID;
        this.actions = {
            'create': {
                'title': Locale.tr("Create Process"),
                'buttonText': Locale.tr("Create"),
                'resetButton': true
            }
        }

        var that = this;

        BaseFormPanel.call(this);
    };

    var Playbooks;
    OpenNebula.Ansible.list({
        success: function(r, res){
            Playbooks = res;
        }, error:function(r, res){

        }
    });

    FormPanel.FORM_PANEL_ID = FORM_PANEL_ID;
    FormPanel.prototype = Object.create(BaseFormPanel.prototype);
    FormPanel.prototype.htmlWizard = _htmlWizard;
    FormPanel.prototype.submitWizard = _submitWizard;
    FormPanel.prototype.onShow = _onShow;
    FormPanel.prototype.setup = _setup;
    FormPanel.prototype.fill = _fill;
    FormPanel.prototype.constructor = FormPanel;

    return FormPanel;

    /*
      FUNCTION DEFINITIONS
     */

    function _htmlWizard() {
        var opts = {
            info: false,
            select: true,
            selectOptions: {"multiple_choice": true}
        };

        this.VMTable = new VMTable("vms_wizard", opts);

        return TemplateWizardHTML({
            'formPanelId': this.formPanelId,
            'VMTableHTML': this.VMTable.dataTableHTML,
            'Playbooks': Playbooks,
        });
    }

    function _setup(context) {
        var that = this;
        this.VMTable.initialize();

        WizardFields.fillInput($("#body", context), " - hosts: <%group%>");

        $('#body').keyup(function () {
            $('#control-i-check').removeClass('check-syntax-ok').addClass('check-syntax-false');
            $('#ansible-tabsubmit_button button').prop('disabled', true);
        });


        return false;
    }

    function _submitWizard(context) {
        var that = this;

        var selectedVMList = that.VMTable.retrieveResourceTableSelect();

        var name            = $('#name').val();
        var description     = $('#description').val();
        var supported_os    = $('#supported_os').val();
        var body            = $('#body').val();

        if(this.action == "create"){
            var selectedVM = {};
            $.each(selectedHostsList, function(i,e){
                selectedHosts[e] = 1;
            });

            var cluster_json = {
                "VMs": {
                    "name": $('#name',context).val(),
                    "hosts": selectedHosts,
                    "vnets": selectedVNets,
                    "datastores": selectedDatastores
                }
            };


            Sunstone.runAction(
                "Ansible.create",
                { name: name, body: body, description : description, extra_data: {PERMISSIONS: '111000000', SUPPORTED_OS: supported_os}}
            );
        }
        return false;
    };


    function _fill(context, element) {
      
      element.ID = element.id
      element.NAME = element.name

      this.setHeader(element);

      this.resource     = element
      this.resourceId   = element.ID;

      // Fills the inputs
      WizardFields.fillInput($("#name", context), element.name);
      WizardFields.fillInput($("#body", context), element.body);
      WizardFields.fillInput($("#description", context), element.description);
      WizardFields.fillInput($("#supported_os", context), element.extra_data.SUPPORTED_OS);

        var VMIds = element.HOSTS.ID;

        if (typeof VMIds == 'string'){
            VMIds = [VMIds];
        }

        $('#name',context).val(name);
        $('#name',context).attr("disabled", "disabled");

        this.originalHostsList = [];

        // Select hosts belonging to the cluster
        if (VMIds){
            this.originalVMList = VMIds;
            this.VMTable.selectResourceTableSelect({ids: VMIds});
        }


    }

    function _onShow(context) {
        $('#ansible-tabsubmit_button button').prop('disabled', true);
        this.VMTable.refreshResourceTableSelect();
    }


});
