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
    var TemplateHTML = require('hbs!./reinstall/html');
    var Sunstone = require('sunstone');
    var Tips = require('utils/tips');
    var Locale = require('utils/locale');

    /*
      CONSTANTS
     */

    var DIALOG_ID = require('./reinstall/dialogId');
    var TAB_ID = require('../tabId')

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
    Dialog.prototype.html = _html;
    Dialog.prototype.onShow = _onShow;
    Dialog.prototype.setup = _setup;
    Dialog.prototype.setElement = _setElement;

    return Dialog;

    /*
      FUNCTION DEFINITIONS
     */
    $(".provision-pricing-table").on("click", function(){
        $(this).css('border','1px solid #2E9CB9');
    });



    function _html() {
        return TemplateHTML({
            'dialogId': this.dialogId
        });
    }

    function _setup(context) {
        var that = this;
        var OpenNebula = require('opennebula');
        var Locale = require('utils/locale');
        var Notifier = require('utils/notifier');

        var ProvisionVmsList = require('tabs/provision-tab/vms/list');


        context.on("click",".checkbox_playbooks", function(){
            if($(this).is(':checked')){
                $('.checkbox_playbooks').prop('checked',false);
                $(this).prop('checked',true);
            }
        });

        context.on("click", ".provision-pricing-table", function(){
            $(".provision-pricing-table").css('border','1px solid #f4f4f4');
            $(".provision-pricing-table").removeClass('checktemp');
            $(this).css('border','1px solid #2E9CB9');
            $(this).addClass('checktemp');
            var id_template = $(this).attr('opennebula_id');
            OpenNebula.Template.show({data:{'id':id_template},success: function(a,b){
                    $('.inputuser').css('display','none');
                    $('.inputpass').css('display','none');
                    $('#vm_username').attr('checkus','false');
                    $('.inputrootpass').addClass('hidden');
                    for (key in b.VMTEMPLATE.TEMPLATE.USER_INPUTS) {
                        if(~b.VMTEMPLATE.TEMPLATE.USER_INPUTS[key].indexOf('password')){
                            $('.inputpass').css('display','');
                        }
                        if(~b.VMTEMPLATE.TEMPLATE.USER_INPUTS[key].indexOf('User')){
                            $('.inputuser').css('display','');
                            $('#vm_username').attr('checkus','true');
                        }
                    }
                    if($('#vm_username').attr('checkus') != 'true'){
                        $('.inputrootpass').removeClass('hidden');
                    }
                }});
        });

        context.on("click",".button-reinstall-dialog",function () {
            var OpenNebula = require('opennebula');
            var username = $('#vm_username').val();
            var password = $('#vm_password').val();
            var vm_id = $(".provision_info_vm").attr("vm_id");
            var id_template = $('.checktemp').attr('opennebula_id');
            if(password == '') {
                alert(Locale.tr("Password-field cannot be empty") + '!');
            } else if($('#vm_username').attr('checkus') == 'true' && username == '') {
                alert(Locale.tr("Username-field cannot be empty") + '!');
            } else {
                $('.reinstall-first-step').addClass('hidden');
                $('.reinstall-second-step').removeClass('hidden');
            }
        })

        context.on("click",".button-reinstall-confirm",function () {
            var OpenNebula = require('opennebula');
            var username = $('#vm_username').val();
            var password = $('#vm_password').val();
            var vm_id = $(".provision_info_vm").attr("vm_id");
            var id_template = $('.checktemp').attr('opennebula_id');

            function refresh(){
                location.reload();
                OpenNebula.Action.clear_cache("VM");
                ProvisionVmsList.show(0);
            }
            function parse_result(response){
                if(response.error != undefined){
                    Notifier.notifyError('ReinstallError: ' + response.error);
                    var id = $('#reinstalldialogvm').data('close');
                    if (id) {
                      triggers($('#reinstalldialogvm'), 'close');
                    } else {
                      $('#reinstalldialogvm').trigger('close.zf.trigger');
                    };
                } else {
                    refresh();
                }
            }

            if($(".checkbox_playbooks:checked").val() != undefined) {
                OpenNebula.Ansible.show({
                    data: {id: $(".checkbox_playbooks:checked").val()},
                    success: function (r, res) {
                        ansible = true;
                        ansible_local_id = $(".checkbox_playbooks:checked").val();
                        ansible_vars = res.ANSIBLE.VARS;
                        for (key in ansible_vars){
                            ansible_vars[key] = $('.'+key+res.ANSIBLE.id).val();
                        };
                        if($('.inputuser').css('display') == 'none'){
                            OpenNebula.VM.reinstall({
                                data: {
                                    id:vm_id, template_id:id_template, password:password, ansible: true, ansible_local_id: ansible_local_id, ansible_vars: ansible_vars
                                },
                                success: function(r, response){ parse_result(response) },
                                error: function(r, response){ Notifier.notifyError('ReinstallError: ' + response.error); }
                            });
                        } else {
                            OpenNebula.VM.reinstall({
                                data: {
                                    id:vm_id, template_id:id_template, username:username, password:password, ansible: true, ansible_local_id: ansible_local_id, ansible_vars: ansible_vars
                                },
                                success: function(r, response){ parse_result(response) },
                                error: function(r, response){ Notifier.notifyError('ReinstallError: ' + response.error); }
                            });
                        }
                    }
                });

            }else{
                if($('.inputuser').css('display') == 'none'){
                    OpenNebula.VM.reinstall({
                        data: {
                            id:vm_id, template_id:id_template, password:password
                        },
                        success: function(r, response){ parse_result(response) },
                        error: function(r, response){ Notifier.notifyError('ReinstallError: ' + response.error); }
                    });
                } else {
                    OpenNebula.VM.reinstall({
                        data: {
                            id:vm_id, template_id:id_template, username:username, password:password
                        },
                        success: function(r, response){ parse_result(response) },
                        error: function(r, response){ Notifier.notifyError('ReinstallError: ' + response.error); }
                    });
                }
            };

        });

        context.on("click",".button-reinstall-cancel",function () {
            $('.reinstall-first-step').removeClass('hidden');
            $('.reinstall-second-step').addClass('hidden');
        })


        return false;
    }


    function _onShow(context) {
        this.setNames( {tabId: TAB_ID} );
        return false;
    }

    function _setElement(element) {
        this.element = element
    }
});
