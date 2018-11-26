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
        context.on("click", ".provision-pricing-table", function(){
            $(".provision-pricing-table").css('border','1px solid #f4f4f4');
            $(".provision-pricing-table").removeClass('checktemp');
            $(this).css('border','1px solid #2E9CB9');
            $(this).addClass('checktemp');
            var id_template = $(this).attr('opennebula_id');
            console.log(id_template);
            OpenNebula.Template.show({data:{'id':id_template},success: function(a,b){
                    $('.inputuser').css('display','none');
                    $('.unputpass').css('display','none');
                    for (key in b.VMTEMPLATE.TEMPLATE.USER_INPUTS) {
                        if(~b.VMTEMPLATE.TEMPLATE.USER_INPUTS[key].indexOf('password')){
                            $('.unputpass').css('display','');
                        }
                        if(~b.VMTEMPLATE.TEMPLATE.USER_INPUTS[key].indexOf('User')){
                            $('.inputuser').css('display','');
                        }

                    }
                }});
        });

        context.on("click",".butreinstall",function () {
            var OpenNebula = require('opennebula');
            var username = $('#user_vm').val();
            var password = $('#pass_vm').val();
            var vm_id = $(".provision_info_vm").attr("vm_id");
            var id_template = $('.checktemp').attr('opennebula_id');
            if($('#pass_vm').val() == ''){
                alert('введите пароль');
            }else if($('#user_vm').val() == ''){
                OpenNebula.VM.reinstall({
                    data: {
                        "id":vm_id, "template_id":id_template, "password": password
                    },
                    success: function(r, response){ console.log(r); console.log(response); },
                    error: function(r, response){ console.log(response); }
                });
            }else{
                OpenNebula.VM.reinstall({
                    data: {
                        "id":vm_id, "template_id":id_template, "username": username, "password": password
                    },
                    success: function(r, response){ console.log(r); console.log(response); },
                    error: function(r, response){ console.log(response); }
                });
            }

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
