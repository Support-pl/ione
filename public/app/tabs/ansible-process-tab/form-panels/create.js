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
        if (config.user_config.default_view == 'user'){
            var but_txt = Locale.tr("Run");
        }else{
            var but_txt = Locale.tr("Create");
        }
        this.actions = {
            'create': {
                'title': Locale.tr("Create Process"),
                'buttonText': but_txt,
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

        this.VMTable = new VMTable("vms_wizard_process", opts);

        return TemplateWizardHTML({
            'formPanelId': this.formPanelId,
            'VMTableHTML': this.VMTable.dataTableHTML,
            'Playbooks': Playbooks,
        });
    }

    function _setup(context) {

        $('div').on('click',function(){
            var Hosts = {};
            var HostsData = [];
            $('.login-pass-vm').find('input').each(function(index,data){
                HostsData.push(data.value);
            });
            for(var i = 0; i < HostsData.length; i += 4){
                Hosts[HostsData[i].split(' ')[0]] = [
                    HostsData[i].split(' ')[4] + ':' + HostsData[i + 1],
                    HostsData[i + 2] + ':' + HostsData[i + 3],
                ]
            };

            var Vars = {};
            $('.playbooks_vars').find('input').each(function(index, input){
                Vars[input.name] = input.value
            });

            var id_playbooks = $('#Playbooks').val();

            if(Object.keys(Hosts).length != 0 && Object.keys(HostsData).length != 0 && id_playbooks != ''){
                if($('.playbooks_vars').find('input').length != 0){
                    if(Object.keys(HostsData).length != 0) {
                        $('#ansible-process-tabsubmit_button button').prop('disabled', false);
                    }else{
                        $('#ansible-process-tabsubmit_button button').prop('disabled', true);
                    }
                }else{
                    $('#ansible-process-tabsubmit_button button').prop('disabled', false);
                }
            }else{
                $('#ansible-process-tabsubmit_button button').prop('disabled', true);
            }
        });

        $('#Playbooks').on('click',function () {

            var id_playbooks = $('#Playbooks').val();
            var playbook;
            var html = '';

            $('.playbooks_vars').html('');
            if(id_playbooks != '') {
                OpenNebula.Ansible.show({
                    data: {id: id_playbooks},
                    success: function (r, res) {
                        for (key in res.ANSIBLE.VARS){
                                html +='<div class="large-12 column" style="padding-left:0"><span style="font-size:15px;">'+ key + '' +
                                    '</span><input style="float:right;width:70%;" type="text" name="' +key+ '"></div>';
                        };
                        $('.playbooks_vars').append(html);
                        for (key in res.ANSIBLE.VARS){
                            if (isNaN(res.ANSIBLE.VARS[key]) == true && res.ANSIBLE.VARS[key].indexOf('\\') == 0) {
                                $("input[name="+key+"]").val(res.ANSIBLE.VARS[key].replace(/[\\"]+/g, '\"'));
                            }else{
                                $("input[name="+key+"]").val(res.ANSIBLE.VARS[key]);
                            }
                        }
                    }
                });
            }
        });

        $("#vms_wizard_process", context).on('click', 'tbody [role="row"]', function () {

            //if ($(this).find('td').eq(0).text() == 'RUNNING') {

                $('.fa-times').on('click', function () {
                    $('input[value="' + $(this).parent().attr("info") + '"]').parent().remove();
                });

                $('.login-pass-vm').html('');
                var allvm = new Object();
                var3 = 0;
                $('#selected_ids_row_vms_wizard_process').find('.radius.label').each(function (var1, var2) {
                    if ($(var2).attr('row_id') != undefined) {
                        $('.login-pass-vm').append('<div class="large-12 column"><div class="large-4 small-3 column">' + $(var2).attr("info") + '</div>' +
                            '<input type="hidden" value="' + $(var2).attr("info") + '">' +
                            '<div class="large-2 small-2 column"><input type="text" value"" name="port' + $(var2).attr('row_id') + '" id="port' + $(var2).attr('row_id') + '" placeholder="Port" value="52222" required></div>' +
                            '<div class="large-2 small-3 column"><input type="text" value"" name="login' + $(var2).attr('row_id') + '" id="login' + $(var2).attr('row_id') + '" placeholder="Login"></div>' +
                            '<div class="large-2 small-4 column"><input type="text" value"" name="password' + $(var2).attr('row_id') + '" id="password' + $(var2).attr('row_id') + '" placeholder="Password"></div>' +
                            '<div></div></div>');
                        allvm[var3] = $(var2).attr('row_id');
                        var3++;
                    }
                });
            // }else{
            //     $(this).removeClass('markrowchecked');
            //     $('.fa-times').last().click();
            // }
        });

        $('#checkbox_sshkey').on('click',function () {
            if($('#checkbox_sshkey').prop('checked') == true){
                $('.ssh_key_ok').removeClass('hidden');
            }else{
                $('.ssh_key_ok').addClass('hidden');
            }
        });



        var that = this;
        this.VMTable.initialize();
        
        return false;
    }

    function _submitWizard(context) {
        var that = this;

        var Hosts = {};
        var HostsData = [];
        $('.login-pass-vm').find('input').each(function(index,data){
            HostsData.push(data.value);
        });

        for(var i = 0; i < HostsData.length; i += 4){
            Hosts[HostsData[i].split(' ')[0]] = [
                HostsData[i].split(' ')[4] + ':' + HostsData[i + 1],
                HostsData[i + 2] + ':' + HostsData[i + 3],
            ]
        }

        var Vars = {};
        $('.playbooks_vars').find('input').each(function(index, input){
            Vars[input.name] = input.value
        });

        //if (Hosts)
        opts =  {
                    playbook_id:    $("#Playbooks").val(),
                    hosts:          Hosts,
                    vars:           Vars,
                    comment:        $("#comment").val()
                };
        Sunstone.runAction("AnsibleProcess.create", opts);

        return false;
    };


    function _fill(context, element) {
      
      element.ID = element.id
      element.NAME = element.name

      this.setHeader(element);

      this.resource     = element
      this.resourceId   = element.ID;

      // Fills the inputs

        var VMIds = element.VMs.ID;

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

        var playbooks;
        OpenNebula.Ansible.list({
            success: function(r, res){
                playbooks = res;

                if (Playbooks != playbooks){
                    var difference = playbooks.slice(Playbooks.length)
                    for(key in difference){
                        $('#Playbooks').append($('<option>', {value:difference[key].ANSIBLE.id, text:difference[key].ANSIBLE.id+':'+difference[key].ANSIBLE.name}));
                    }
                    Playbooks = playbooks;
                }
            }, error:function(r, res){

            }
        });


        if (Object.keys(Sunstone.getDataTable('ansible-tab').elements()).length !== 0){
            var idplaybook = Sunstone.getDataTable('ansible-tab').elements();
            $('#Playbooks').val(idplaybook);

            var id_playbooks = $('#Playbooks').val();
            var playbook;
            var html = '';
            $('.playbooks_vars').html('');
            if(id_playbooks != '') {
                OpenNebula.Ansible.show({
                    data: {id: id_playbooks},
                    success: function (r, res) {
                        for (key in res.ANSIBLE.VARS){
                            html +='<div class="large-12 column" style="padding-left:0"><span style="font-size:15px;">'+ key + '' +
                                '</span><input style="float:right;width:70%;" type="text" name="' +key+ '"></div>';
                        };
                        $('.playbooks_vars').append(html);
                        for (key in res.ANSIBLE.VARS){
                            if (isNaN(res.ANSIBLE.VARS[key]) == true && res.ANSIBLE.VARS[key].indexOf('\\') == 0) {
                                $("input[name="+key+"]").val(res.ANSIBLE.VARS[key].replace(/[\\"]+/g, '\"'));
                            }else{
                                $("input[name="+key+"]").val(res.ANSIBLE.VARS[key]);
                            }
                        }
                    }
                });
            }
        }

        $('#ansible-process-tabsubmit_button button').prop('disabled', true);
        this.VMTable.refreshResourceTableSelect();
    }


});
