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
                'title': Locale.tr("Create Playbook"),
                'buttonText': Locale.tr("Create"),
                'resetButton': true
            },
            'update': {
                'title': Locale.tr("Update Playbook"),
                'buttonText': Locale.tr("Update"),
                'resetButton': false
            }
        }

        var that = this;

        BaseFormPanel.call(this);
    };

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
        return TemplateWizardHTML({
            'formPanelId': this.formPanelId
        });
    }

    function _setup(context) {
        var that = this;

        WizardFields.fillInput($("#body", context), " - hosts: <%group%>");

        $('#body').keyup(function () {
            $('#control-i-check').removeClass('check-syntax-ok').addClass('check-syntax-false');
            $('#ansible-tabsubmit_button button').prop('disabled', true);
        });

        $(".check_syntax").on("click",function () {
            $.ajax({
                url: '/ansible/check_syntax',
                type: 'POST',
                dataType: 'json',
                data: JSON.stringify({"body":$('#body').val()}),
                success: function(response) {
                    console.log(response.response[0]);
                    if(response.response[0]){
                        $('#body_label').removeClass('is-invalid-label');
                        $('#body').removeClass('is-invalid-input');
                        $('#control-i-check').addClass('check-syntax-ok').removeClass('check-syntax-false');
                        $('#ansible-tabsubmit_button button').prop('disabled', false);
                    } else {
                        $('#body_label').addClass('is-invalid-label');
                        $('#body').addClass('is-invalid-input');
                        $('#control-i-check').removeClass('check-syntax-ok').addClass('check-syntax-false');
                        $('#ansible-tabsubmit_button button').prop('disabled', true);
                        Notifier.notifyError('Body syntax error');
                    }
                },
                error: function(response) {
                    console.log(response);
                    return callbackError ?
                        callbackError(request, OpenNebulaError(response)) : null;
                }
            })
        });

        $('#playbook_file_upload').bind("click" , function () {
            $('#playbook_file').click();
        });

        $( "#playbook_file" ).change(function() {
            var file = document.getElementById('playbook_file').files[0];
            var reader = new FileReader();
            reader.onload = function() {
                $('#body').val(reader.result);
                $('#body_label').append(file.name);
            }
            reader.readAsText(file);
        });

        return false;
    }

    function _submitWizard(context) {

        var that = this;
        var name            = $('#name').val();
        var description     = $('#description').val();
        var supported_os    = $('#supported_os').val();
        var body            = $('#body').val();

        console.log(body);
        if(this.action == "create"){
            Sunstone.runAction(
                "Ansible.create",
                { name: name, body: body, description : description, extra_data: {PERMISSIONS: '111000000', SUPPORTED_OS: supported_os}}
            );
        } else if(this.action == "update") {
            Sunstone.runAction(
                "Ansible.update",
                this.resourceId,
                { name: name, body: body, description : description, extra_data: {PERMISSIONS: this.resource.extra_data.PERMISSIONS, SUPPORTED_OS: supported_os}}
            );
        }
        return false;
    };


    function _fill(context, element) {
      if (this.action != "update") {
        return;
      }
      
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

    }

    function _onShow(context) {
        $('#ansible-tabsubmit_button button').prop('disabled', true);
    }


});
