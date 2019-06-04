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
  var TemplateHTML = require('hbs!./instantiate/html');
  var TemplateRowHTML = require('hbs!./instantiate/templateRow');
  var Sunstone = require('sunstone');
  var Notifier = require('utils/notifier');
  var OpenNebulaTemplate = require('opennebula/template');
  var Locale = require('utils/locale');
  var Tips = require('utils/tips');
  var UserInputs = require('utils/user-inputs');
  var WizardFields = require('utils/wizard-fields');
  var TemplateUtils = require('utils/template-utils');
  var DisksResize = require('utils/disks-resize');
  var NicsSection = require('utils/nics-section');
  var VMGroupSection = require('utils/vmgroup-section');
  var VcenterVMFolder = require('utils/vcenter-vm-folder');
  var CapacityInputs = require('tabs/templates-tab/form-panels/create/wizard-tabs/general/capacity-inputs');
  var Config = require('sunstone-config');
  var HostsTable = require('tabs/hosts-tab/datatable');
  var DatastoresTable = require('tabs/datastores-tab/datatable');
  var OpenNebula = require('opennebula');
  var Settings = require('opennebula/settings');
  /*
    CONSTANTS
   */

  var FORM_PANEL_ID = require('./instantiate/formPanelId');
  var TAB_ID = require('../tabId');
  var settings;
  var for_template;
  var azure_template;
  var user_info;
  /*
    CONSTRUCTOR
   */

  function FormPanel() {
    this.formPanelId = FORM_PANEL_ID;
    this.tabId = TAB_ID;

    this.actions = {
      'instantiate': {
        'title': Locale.tr("Instantiate VM Template"),
        'buttonText': Locale.tr("Instantiate"),
        'resetButton': false
      }
    };

    this.template_objects = [];

    BaseFormPanel.call(this);
  }

  FormPanel.FORM_PANEL_ID = FORM_PANEL_ID;
  FormPanel.prototype = Object.create(BaseFormPanel.prototype);
  FormPanel.prototype.constructor = FormPanel;
  FormPanel.prototype.setTemplateIds = _setTemplateIds;
  FormPanel.prototype.htmlWizard = _html;
  FormPanel.prototype.submitWizard = _submitWizard;
  FormPanel.prototype.onShow = _onShow;
  FormPanel.prototype.setup = _setup;
  FormPanel.prototype.calculateCost = _calculateCost;


  return FormPanel;

  /*
    FUNCTION DEFINITIONS
   */

  function _html() {
    if (config.user_config["default_view"] == 'user'){
      this.default_user_view = true;
    } else {
      this.default_user_view = false;
    }
    return TemplateHTML({
      'formPanelId': this.formPanelId,
      'default_user_view': this.default_user_view
    });
  }

  function _setup(context) {
    var that = this;

  }

  function _calculateCost(){
    Settings.cloud({success:function(r, res) {
        settings = r.response;
        var memory_val = parseFloat( $(".capacity_cost_div .cost_value").attr('value') )/1024;
        var cpu_val = parseFloat( $(".vcpu_input_wrapper .vcpu_input input").val());
        var disk_val = parseFloat( $(".provision_create_template_disk_cost_div .cost_value").attr('value') );
        var publicip_val = 1 * $('#amt_public_ip').val();

        if ($('#publicip_cost_div').length != 0){
          var publicip_cost = settings.PUBLIC_IP_COST * publicip_val;
        } else {
          var publicip_cost = 0;
        }

        if(Number.isNaN(memory_val)){
          memory_val = 0;
        }
        if(Number.isNaN(cpu_val)){
          cpu_val = 0;
        }
        if(Number.isNaN(disk_val)){
          disk_val = 0;
        }

        var settings_disks_costs = JSON.parse(settings.DISK_COSTS);

        var capasity_cost = JSON.parse(settings.CAPACITY_COST);
        var memory_cost =  memory_val*capasity_cost.MEMORY_COST;
        var cpu_cost =  cpu_val*capasity_cost.CPU_COST;
        var disk_cost = settings_disks_costs[$('[wizard_field="DRIVE"]').val()] * disk_val;

        if(Number.isNaN(disk_cost)){
          disk_cost = 0;
        }

        var time_val = $('#CostVaribl').val()*1;

        var capacity_text = ((memory_cost*1 + cpu_cost*1) * time_val).toFixed(3);
        var disk_text = ((time_val * disk_cost)/1024).toFixed(3);
        var publicip_text =(publicip_cost * time_val).toFixed(3);

        $('.capacity_cost_div span.cost_value').text(capacity_text);
        $('.provision_create_template_disk_cost_div span.cost_value').text(disk_text);
        $(".publicip_cost_div .cost_value").text(publicip_text);

        var total = capacity_text*1 + disk_text*1 + publicip_text*1;

        if (Config.isFeatureEnabled("showback")) {
          $(".total_cost_div .cost_value").text( (total).toFixed(2) );
        }
      }});
  }

  function _submitWizard(context) {
    var that = this;
    if (!this.selected_nodes || this.selected_nodes.length == 0) {
      Notifier.notifyError(Locale.tr("No template selected"));
      Sunstone.hideFormPanelLoading();
      return false;
    }


    var vm_name = $('#vm_name', context).val();
    var n_times = $('#vm_n_times', context).val();
    var n_times_int = 1;

    if (n_times.length) {
      n_times_int = parseInt(n_times, 10);
    }

    var hold = $('#hold', context).prop("checked");

    var action;

    if ($("input.instantiate_pers", context).prop("checked")){
      action = "instantiate_persistent";
      n_times_int = 1;
    } else {
      action = "instantiate";
    }

    $.each(this.selected_nodes, function(index, template_id) {
      var extra_info = {
        'hold': hold
      };

      var tmp_json = WizardFields.retrieve($(".template_user_inputs" + template_id, context));
      //tmp_json.DRIVE = $('select[wizard_field="DRIVE"]').val();
      if (azure_template == true){
        for_template.OS_DISK_SIZE = $('[wizard_field="OS_DISK_SIZE"]').val();
        for_template.OS_IMAGE = $('[wizard_field="OS_IMAGE"]').val();
        for_template.USER_OS_NAME = $('[wizard_field="USER_OS_NAME"]').val();
        for_template.SIZE = $('[wizard_field="SIZE"]').val();
        for_template.LOCATION = $('[wizard_field="LOCATION"]').val();
        for_template.PUBLIC_IP = $('[wizard_field="PUBLIC_IP"]').val();
        for_template.ALLOW_PORTS = $('[wizard_field="ALLOW_PORTS"]').val();
      }

      for_template.DRIVE = $('[wizard_field="DRIVE"]').val();
      $.extend(tmp_json, for_template);
      var disks = DisksResize.retrieve($(".disksContext"  + template_id, context));
      if (disks.length > 0) {
        delete disks[0]['VCENTER_DS_REF'];
        delete disks[0]['VCENTER_INSTANCE_ID'];
        tmp_json.DISK = disks;
      }

      var networks = NicsSection.retrieve($(".nicsContext"  + template_id, context));

      var vmgroup = VMGroupSection.retrieve($(".vmgroupContext"+ template_id, context));
      if(vmgroup){
        $.extend(tmp_json, vmgroup);
      }

      var sched = WizardFields.retrieveInput($("#SCHED_REQUIREMENTS"  + template_id, context));
      if(sched){
        tmp_json.SCHED_REQUIREMENTS = sched;
      }

      var sched_ds = WizardFields.retrieveInput($("#SCHED_DS_REQUIREMENTS"  + template_id, context));
      if(sched_ds){
        tmp_json.SCHED_DS_REQUIREMENTS = sched_ds;
      }

      var nics = [];
      var pcis = [];

      $.each(networks, function(){
        if (this.TYPE == "NIC"){
          pcis.push(this);
        } else {
          nics.push(this);
        }
      });

      if (nics.length > 0) {
        tmp_json.NIC = nics;
      }

      // Replace PCIs of type nic only
      var original_tmpl = that.template_objects[index].VMTEMPLATE;

      var regular_pcis = [];

      if(original_tmpl.TEMPLATE.PCI != undefined){
        var original_pcis;

        if ($.isArray(original_tmpl.TEMPLATE.PCI)){
          original_pcis = original_tmpl.TEMPLATE.PCI;
        } else if (!$.isEmptyObject(original_tmpl.TEMPLATE.PCI)){
          original_pcis = [original_tmpl.TEMPLATE.PCI];
        }

        $.each(original_pcis, function(){
          if(this.TYPE != "NIC"){
            regular_pcis.push(this);
          }
        });
      }

      pcis = pcis.concat(regular_pcis);

      if (pcis.length > 0) {
        tmp_json.PCI = pcis;
      }

      if (Config.isFeatureEnabled("vcenter_vm_folder")){
        if(!$.isEmptyObject(original_tmpl.TEMPLATE.HYPERVISOR) &&
            original_tmpl.TEMPLATE.HYPERVISOR === 'vcenter'){
          $.extend(tmp_json, VcenterVMFolder.retrieveChanges($(".vcenterVMFolderContext"  + template_id)));
        }
      }

      capacityContext = $(".capacityContext"  + template_id, context);
      $.extend(tmp_json, CapacityInputs.retrieveChanges(capacityContext));

      if (config.user_config.default_view == 'user'){
        if ($('#input_private_ip').prop('checked') == false && $('#input_public_ip').prop('checked') == false){
          $(".nicsContext"  + template_id+' .provision_network_selector').css({'padding-left': '5px','border': '0.1rem solid #ec5840','border-radius': '20px'});
          $('.provision_network_selector  legend').css({'color':'#ec5840','border-bottom-color': '#ec5840'});

          Notifier.notifyError(Locale.tr("У машины нет IP адреса"));
          if (config.user_config.default_view == 'user'){
            return false;
          }
        }
        var nic = [];
        if ($('#input_public_ip').prop('checked') == true){
          var amt_public = $('#amt_public_ip').val() * 1;
          var publ_net_def = JSON.parse(settings.PUBLIC_NETWORK_DEFAULTS);
          for (var i = 0; i < amt_public; i++){
            nic.push({NETWORK_ID:publ_net_def.NETWORK_ID});
          }
        }
        if ($('#input_private_ip').prop('checked') == true){
          var amt_private = $('#amt_private_ip').val() * 1;
          for (var i = 0; i < amt_private; i++) {
            nic.push({NETWORK: 'user-'+config.user_id+'-vnet'});
          }
        }

        $.extend(tmp_json,  {NIC:nic});
        console.log(tmp_json);
      }

      extra_info['template'] = tmp_json;

      OpenNebula.User.show({data:{id:config.user_id},success: function(r,res) {
        user_info = {User_id: res.USER.ID, ID_GROUP: res.USER.GROUPS.ID, BALANCE: res.USER.TEMPLATE.BALANCE};

        if (user_info.ID_GROUP != '0'){
          $('#CostVaribl').val(24);
          _calculateCost();
          var user_balance = user_info.BALANCE * 1;
          if (user_balance < parseFloat($(".total_cost_div .cost_value").text())){
            Notifier.notifyError(Locale.tr("Пополните баланс"));
            return false;
          }
        }

        for (var i = 0; i < n_times_int; i++) {
          extra_info['vm_name'] = vm_name.replace(/%i/gi, i);
          if ($('label:contains("Password")').children('input[wizard_field="PASSWORD"]').length != 0){
            if (config.user_config.default_view != 'user'){
              Sunstone.runAction("Template."+action, [template_id], extra_info);
            }else if ($('label:contains("Password")').children('input[wizard_field="PASSWORD"]').val() == $('label:contains("Password")').children('input.repeat_pas').val()){
              Sunstone.runAction("Template."+action, [template_id], extra_info);
            } else {
              console.log(1,$('label:contains("Password")').children('input[wizard_field="PASSWORD"]').val());
              console.log(2,$('label:contains("Password")').children('input.repeat_pas').val());

              Notifier.notifyError('Passwords doesn\'t match');
            }
          }else{
            Sunstone.runAction("Template."+action, [template_id], extra_info);
          }

          // OpenNebula.VM.list({success: function(r,res){
          //     res[res.length-1].VM.ID
          // }});
          //OpenNebula.VM.update({ id: id, template: template })
        }
      }});
      return false;
    });
    return false;
  }

  function _setTemplateIds(context, selected_nodes) {
    var that = this;

    this.selected_nodes = selected_nodes;
    this.template_objects = [];
    this.template_base_objects = {};

    var templatesContext = $(".list_of_templates", context);

    var idsLength = this.selected_nodes.length;
    var idsDone = 0;

    $.each(this.selected_nodes, function(index, template_id) {
      OpenNebulaTemplate.show({
        data : {
          id: template_id,
          extended: false
        },
        timeout: true,
        success: function (request, template_json) {
          that.template_base_objects[template_json.VMTEMPLATE.ID] = template_json;
        }
      });
    });

    templatesContext.html("");
    $.each(this.selected_nodes, function(index, template_id) {
      OpenNebulaTemplate.show({
        data : {
          id: template_id,
          extended: true
        },
        timeout: true,
        success: function (request, template_json) {
          that.template_objects.push(template_json);

          var options = {
            'select': true,
            'selectOptions': {
              'multiple_choice': true
            }
          }

          that.hostsTable = new HostsTable('HostsTable' + template_json.VMTEMPLATE.ID, options);
          that.datastoresTable = new DatastoresTable('DatastoresTable' + template_json.VMTEMPLATE.ID, options);

          if (config.user_config["default_view"] == 'user'){
            var default_user_view = true;
          } else {
            var default_user_view = false;
          }

          if (template_json.VMTEMPLATE.NAME.toLowerCase().indexOf('azure') >= 0){
            azure_template = true;
          } else {
            azure_template = false;
          }

          templatesContext.append(
            TemplateRowHTML(
              { element: template_json.VMTEMPLATE,
                capacityInputsHTML: CapacityInputs.html(),
                hostsDatatable: that.hostsTable.dataTableHTML,
                dsDatatable: that.datastoresTable.dataTableHTML,
                default_user_view: default_user_view,
                azure_template:azure_template
              }) );

          $(".provision_host_selector" + template_json.VMTEMPLATE.ID, context).data("hostsTable", that.hostsTable);
          $(".provision_ds_selector" + template_json.VMTEMPLATE.ID, context).data("dsTable", that.datastoresTable);

          var selectOptions = {
            'selectOptions': {
              'select_callback': function(aData, options) {
                var hostTable = $(".provision_host_selector" + template_json.VMTEMPLATE.ID, context).data("hostsTable");
                var dsTable = $(".provision_ds_selector" + template_json.VMTEMPLATE.ID, context).data("dsTable");
                generateRequirements(hostTable, dsTable, context, template_json.VMTEMPLATE.ID);
              },
              'unselect_callback': function(aData, options) {
                var hostTable = $(".provision_host_selector" + template_json.VMTEMPLATE.ID, context).data("hostsTable");
                var dsTable = $(".provision_ds_selector" + template_json.VMTEMPLATE.ID, context).data("dsTable");
                generateRequirements(hostTable, dsTable, context, template_json.VMTEMPLATE.ID);
               }
            }
          }
          that.hostsTable.initialize(selectOptions);
          that.hostsTable.refreshResourceTableSelect();
          that.datastoresTable.initialize(selectOptions);
          that.datastoresTable.filter("system", 10);
          that.datastoresTable.refreshResourceTableSelect();

          var reqJSON = template_json.VMTEMPLATE.TEMPLATE.SCHED_REQUIREMENTS;
          if (reqJSON) {
            $('#SCHED_REQUIREMENTS' + template_json.VMTEMPLATE.ID, context).val(reqJSON);
            var req = TemplateUtils.escapeDoubleQuotes(reqJSON);
            var host_id_regexp = /(\s|\||\b)ID=\\"([0-9]+)\\"/g;
            var hosts = [];
            while (match = host_id_regexp.exec(req)) {
                hosts.push(match[2]);
            }
            var selectedResources = {
              ids : hosts
            }
            that.hostsTable.selectResourceTableSelect(selectedResources);
          }

          var dsReqJSON = template_json.VMTEMPLATE.TEMPLATE.SCHED_DS_REQUIREMENTS;
          if (dsReqJSON) {
            $('#SCHED_DS_REQUIREMENTS' + template_json.VMTEMPLATE.ID, context).val(dsReqJSON);
            var dsReq = TemplateUtils.escapeDoubleQuotes(dsReqJSON);
            var ds_id_regexp = /(\s|\||\b)ID=\\"([0-9]+)\\"/g;
            var ds = [];
            while (match = ds_id_regexp.exec(dsReq)) {
              ds.push(match[2]);
            }
            var selectedResources = {
              ids : ds
            }
            that.datastoresTable.selectResourceTableSelect(selectedResources);
          }

          if (azure_template == false){
            DisksResize.insert({
              template_base_json: that.template_base_objects[template_json.VMTEMPLATE.ID],
              template_json: template_json,
              disksContext: $(".disksContext"  + template_json.VMTEMPLATE.ID, context),
              force_persistent: $("input.instantiate_pers", context).prop("checked"),
              cost_callback: _calculateCost,
              uinput_mb: true
            });
          }

          if (default_user_view == true){
            $('#input_public_ip').click(function () {
              if ($(this).prop('checked')){
                $('#amt_public_ip').prop('disabled',false);
                $('#element_cost').append('<div id="publicip_cost_div" style="width: 100%">' +
                    '<span class="publicip_cost_div">' +
                    '<i class="fa fa-globe"></i>&nbsp;'+Locale.tr("Network")+'<br>' +
                    '<span class="cost_value" style="font-size: 1.4rem;">'+settings.PUBLIC_IP_COST+'</span>&nbsp;' +
                    '<span>'+Locale.tr("BYN") +' / '+ Locale.tr("HOUR")+'</span>' +
                    '</span></div>');
                _calculateCost();
              } else {
                if ($('#publicip_cost_div').length != 0){
                  $('#amt_public_ip').prop('disabled',true);
                  $('#publicip_cost_div').remove();
                  _calculateCost();
                }
              }
            });

            $('#input_private_ip').click(function () {
              if ($(this).prop('checked')){
                $('#amt_private_ip').prop('disabled',false);
              } else {
                  $('#amt_private_ip').prop('disabled',true);
              }
            });

            $('#amt_public_ip').change(function(){_calculateCost();});
          } else {
            $('.cpu_input_wrapper').css('width','100%');
            $('.cpu_input_wrapper label').css({float: 'left', width: '45%'});
            $('.cpu_input_wrapper div').css({float: 'left', width: '45%'});


            NicsSection.insert(template_json,
                $(".nicsContext"  + template_json.VMTEMPLATE.ID, context),
                { 'forceIPv4': true,
                  'securityGroups': Config.isFeatureEnabled("secgroups")
                });
          }

          VMGroupSection.insert(template_json,
            $(".vmgroupContext"+ template_json.VMTEMPLATE.ID, context));

          vcenterVMFolderContext = $(".vcenterVMFolderContext"  + template_json.VMTEMPLATE.ID, context);
          VcenterVMFolder.setup(vcenterVMFolderContext);
          VcenterVMFolder.fill(vcenterVMFolderContext, template_json.VMTEMPLATE);

          var inputs_div = $(".template_user_inputs" + template_json.VMTEMPLATE.ID, context);

            UserInputs.vmTemplateInsert(
                inputs_div,
                template_json,
                {text_header: '<i class="fa fa-gears"></i> ' + Locale.tr("Attributes")});

          inputs_div.data("opennebula_id", template_json.VMTEMPLATE.ID);

          capacityContext = $(".capacityContext"  + template_json.VMTEMPLATE.ID, context);
          CapacityInputs.setup(capacityContext);
          CapacityInputs.fill(capacityContext, template_json.VMTEMPLATE);

          if (template_json.VMTEMPLATE.TEMPLATE.HYPERVISOR == "vcenter"){
            $(".memory_input .mb_input input", context).attr("pattern", "^([048]|\\d*[13579][26]|\\d*[24680][048])$");
          } else {
            $(".memory_input .mb_input input", context).removeAttr("pattern");
          }

          var cpuCost    = template_json.VMTEMPLATE.TEMPLATE.CPU_COST;
          var memoryCost = template_json.VMTEMPLATE.TEMPLATE.MEMORY_COST;
          var memoryUnitCost = template_json.VMTEMPLATE.TEMPLATE.MEMORY_UNIT_COST;

          if (memoryCost && memoryUnitCost && memoryUnitCost == "GB") {
            memoryCost = (memoryCost*1024).toString();
          }

          if (cpuCost == undefined){
            cpuCost = 1;
          }

          if (memoryCost == undefined){
            memoryCost = 1;
          } else {
            if (memoryUnitCost == "GB"){
              memoryCost = memoryCost / 1024;
            }
          }

          if ((cpuCost != 0 || memoryCost != 0) && Config.isFeatureEnabled("showback")) {

            CapacityInputs.setCallback(capacityContext, function(values){
              var cost = 0;

              if (values.MEMORY != undefined){
                cost += memoryCost * values.MEMORY;
              }

              if (values.CPU != undefined){
                cost += cpuCost * values.CPU;
              }

              //$(".cost_value", capacityContext).html(cost.toFixed(3));
              $(".cost_value", capacityContext).attr('value',cost.toFixed(3));
              _calculateCost(context);
            });
          }

          idsDone += 1;
          if (idsLength == idsDone){
            Sunstone.enableFormPanelSubmit(that.tabId);
          }

          if(Config.isFeatureEnabled("instantiate_persistent")){
            $("input.instantiate_pers", context).on("change", function(){
              var persistent = $(this).prop('checked');

              if(persistent){
                $("#vm_n_times", context).hide();
              } else {
                $("#vm_n_times", context).show();
              }

              $.each(that.template_objects, function(index, template_json) {
                DisksResize.insert({
                  template_json:    template_json,
                  disksContext:     $(".disksContext"  + template_json.VMTEMPLATE.ID, context),
                  force_persistent: persistent,
                  cost_callback: that.calculateCost.bind(that),
                  uinput_mb: true
                });
              });

            });
          } else {
            $("#vm_n_times", context).show();
          }

          Tips.setup(context);

          $('#CostVaribl').change(function() {
            var val = $('#CostVaribl option[value="'+$(this).val()+'"]').text();
            var select_time = 'BYN /'+val.split('/')[1];
            $('.publicip_cost_div .cost_span').text(val);

            $('.capacity_cost_div span:contains("BYN")').text(select_time);
            $('.provision_create_template_disk_cost_div span:contains("BYN")').text(select_time);
            $('.total_cost_div span:contains("BYN")').text(select_time);
            $('.publicip_cost_div span:contains("BYN")').text(select_time);
            _calculateCost(context);
          });



          for_template = {};

          if ($('.instantiate_user_inputs label select[wizard_field="DRIVE"]').length != 0 ){
            $('.disksContainer').append($('label select[wizard_field="DRIVE"]').parent());
            $('label select[wizard_field="DRIVE"]').parent().css('height','50px');
            $('label select[wizard_field="DRIVE"]').css({float : "right", width: "45%", 'margin-right': "10%"});

            $('select[wizard_field="DRIVE"]').change(function() {
              _calculateCost();
            });
          }

          if (default_user_view){
            $('label:contains("Password")').append('Repeat password<br><input type="password" value="" class="repeat_pas" required="">');
          }


          var logos = config.vm_logos;
          var select_oc = template_json.VMTEMPLATE.NAME.toLowerCase();
          $('#OC_name img').attr('src','');
          for(var i in logos){
            if (select_oc.indexOf(logos[i].name.toLowerCase().split(' ')[0]) >= 0){
              if (logos[i].name.toLowerCase().split(' ')[0] == 'windows'){
                $('#OC_name img').attr('src',logos[i*1+1].path);
              }else{
                $('#OC_name img').attr('src',logos[i].path);
              }
              break;
            }
          }


          if (azure_template == true){
            $('.disksContainer').append($('input[wizard_field="OS_DISK_SIZE"]').parent().parent().parent());
            $('.OC_name_Container').append($('label select[wizard_field="OS_IMAGE"]').parent());
            $('.OC_name_Container').append($('label textarea[wizard_field="USER_OS_NAME"]').parent());


            $('.capacityContext').append($('label select[wizard_field="SIZE"]').parent());
            $('.capacityContext').append($('label select[wizard_field="LOCATION"]').parent());
            $('label select[wizard_field="LOCATION"]').css('mardin','0');
            $('label select[wizard_field="LOCATION"]').parent().append('<span></span>');

            $('.nicsContainer').append($('label input[wizard_field="PUBLIC_IP"]').parent());
            $('.nicsContainer').append($('label textarea[wizard_field="ALLOW_PORTS"]').parent());

            var network_label = $('label input[wizard_field="PUBLIC_IP"]').parent();
            $(network_label).css('height', '50px');
            var network_label_text = $(network_label).text().split('?')[0];
            $(network_label).text('');
            $(network_label).append(network_label_text+'<div style="width: 50%;float: right;width: 58%;">YES<input style="margin-right: 20px;" checked="" type="radio" name="bool_one2" value="YES" wizard_field="PUBLIC_IP" required="">NO<input type="radio" name="bool_one2" value="NO" wizard_field="PUBLIC_IP" required=""></div>');

            var nic_label =  $('label textarea[wizard_field="ALLOW_PORTS"]').parent();
            var nic_label_text = $(nic_label).text();
            $(nic_label).text('');
            nic_label.append('<div style="width: 40%;float: left;">'+nic_label_text+'</div><textarea type="text" rows="1" wizard_field="ALLOW_PORTS" style="float: right; width: 58%; height: 100px; resize: none;"></textarea>')



            $.each($(".capacityContext").children(), function(){
              $(this).css('height','50px');
              $(this).children().css({'float':'right','width':'60%'});
              if ($(this)[0] == $('label select[wizard_field="SIZE"]').parent()[0]){
                $(this).html($('label select[wizard_field="SIZE"]'));
                $(this).children().css({'float':'','width':'30%'});
                $(this).append('<input class="inp_ram" type="number" disabled value="0" style="width: 20%;float: right;">');
                $(this).append('<label style="width: 8%;float: right;">RAM</label>');
                $(this).append('<input class="inp_cpu" type="number" disabled value="0" style="width: 20%;float: right;margin-right: 4%;">');
                $(this).append('<label style="float: right;width: 8%;">CPU</label>');
              }
            });

            $.each($(".disksContainer").children(), function(){
              $(this).css('height','50px');
              $(this).children().css({'float':'right','width':'65%'});
            });

            $('select[wizard_field="SIZE"]').change(function() {
              var azure_skus = JSON.parse(settings.AZURE_SKUS);
              if (azure_skus[$(this).val()] != undefined){
                $('.inp_cpu').val(JSON.parse(azure_skus[$(this).val()]).CPU);
                $('.inp_ram').val(JSON.parse(azure_skus[$(this).val()]).RAM);
              } else {
                $('.inp_cpu').val(0);
                $('.inp_ram').val(0);
              }
            });
          }

          if ($('#left_colum').height() >= $('#right_colum').height()){
            $('#left_colum').css('padding-bottom','1%');
          } else {
            $('#left_colum').css('height',$('#right_colum').css('height'));
          }

        },
        error: function(request, error_json, container) {
          Notifier.onError(request, error_json, container);
          $("#instantiate_vm_user_inputs", context).empty();
        }
      });
    });
  }

  function _onShow(context) {
    Sunstone.disableFormPanelSubmit(this.tabId);
    $('#vms-tabsubmit_button').hide();
    $('#vm_createContainer .select-resources').hide();
    $("input.instantiate_pers", context).change();

    var templatesContext = $(".list_of_templates", context);
    templatesContext.html("");

    Tips.setup(context);
    return false;
  }

  function generateRequirements(hosts_table, ds_table, context, id) {
      var req_string=[];
      var req_ds_string=[];
      var selected_hosts = hosts_table.retrieveResourceTableSelect();
      var selected_ds = ds_table.retrieveResourceTableSelect();

      $.each(selected_hosts, function(index, hostId) {
        req_string.push('ID="'+hostId+'"');
      });

      $.each(selected_ds, function(index, dsId) {
        req_ds_string.push('ID="'+dsId+'"');
      });

      $('#SCHED_REQUIREMENTS' + id, context).val(req_string.join(" | "));
      $('#SCHED_DS_REQUIREMENTS' + id, context).val(req_ds_string.join(" | "));
  };
});
