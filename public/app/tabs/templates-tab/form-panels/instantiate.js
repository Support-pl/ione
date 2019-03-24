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

  /*
    CONSTANTS
   */

  var FORM_PANEL_ID = require('./instantiate/formPanelId');
  var TAB_ID = require('../tabId');
  var settings;
  var disk_cost = 1;
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

  $.ajax({
    url: 'settings',
    type: 'GET',
    success: function(r, res) {
      settings = r.response;
      FormPanel.prototype.setTemplateIds = _setTemplateIds;
      FormPanel.prototype.htmlWizard = _html;
      FormPanel.prototype.submitWizard = _submitWizard;
      FormPanel.prototype.onShow = _onShow;
      FormPanel.prototype.setup = _setup;
      FormPanel.prototype.calculateCost = _calculateCost;
    }
  });

  return FormPanel;

  /*
    FUNCTION DEFINITIONS
   */

  function _html() {
    if (config.user_config["default_view"] == 'user'){
      this.default_user_view = true;
    }else{
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
    $.each($(".template-row", this.formContext), function(){
      var varibl = $('#CostVaribl').val();

      var memory_val = parseFloat( $(".capacity_cost_div .cost_value").attr('value') )/1024 | 0;
      var cpu_val = parseFloat( $(".vcpu_input_wrapper .vcpu_input input").val());
      var disk_val = parseFloat( $(".provision_create_template_disk_cost_div .cost_value").attr('value') );
      var publickip_cost = parseFloat( $(".publicip_cost_div .cost_value").attr('value') );

      if(Number.isNaN(memory_val)){
        memory_val = 0.000;
      }
      if(Number.isNaN(cpu_val)){
        cpu_val = 0.000;
      }
      if(Number.isNaN(disk_val)){
        disk_val = 0.000;
      }
      if(Number.isNaN(publickip_cost)){
        publickip_cost = 0.000;
      }

      var capasity_cost = JSON.parse(settings.CAPACITY_COST);
      var memory_cost =  memory_val*capasity_cost.MEMORY_COST;
      var cpu_cost =  cpu_val*capasity_cost.CPU_COST;
      var disks_costs = JSON.parse(settings.DISK_COSTS);

      if ($('select[wizard_field="DRIVE"]').val() == "HDD"){
        disk_cost = disks_costs.HDD * disk_val;
      }else if ($('select[wizard_field="DRIVE"]').val() == "SSD"){
        disk_cost = disks_costs.SSD * disk_val;
      }


      if (varibl == 'COST / HOUR' || varibl == 'Стоимость / Час'){
        var time_val = 1;
      }else if (varibl == 'COST / DAY' || varibl == 'Стоимость / День'){
        var time_val = 24;
      }else if (varibl == 'COST / WEEK' || varibl == 'Стоимость / Неделя'){
        var time_val = 168;
      }else if (varibl == 'COST / MONTH' || varibl == 'Стоимость / Месяц'){
        var time_val = 706;
      }

      var capacity_text = ((memory_cost*1 + cpu_cost*1) * time_val).toFixed(3);
      var disk_text = ((time_val * disk_cost)/1024).toFixed(3);
      var publicip_text =(publickip_cost * time_val).toFixed(3);

      $('.capacity_cost_div span.cost_value').text(capacity_text);
      $('.provision_create_template_disk_cost_div span.cost_value').text(disk_text);
      $(".publicip_cost_div .cost_value").text(publicip_text);


      var total = capacity_text*1 + disk_text*1 + publicip_text*1;

      if (total != 0 && Config.isFeatureEnabled("showback")) {

        $(".total_cost_div .cost_value", $(this)).text( (total).toFixed(2) );
      }
    });
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
    }else{
      action = "instantiate";
    }

    $.each(this.selected_nodes, function(index, template_id) {
      var extra_info = {
        'hold': hold
      };

      var tmp_json = WizardFields.retrieve($(".template_user_inputs" + template_id, context));
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
        }else{
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

      extra_info['template'] = tmp_json;
      console.log(extra_info);
        for (var i = 0; i < n_times_int; i++) {
          extra_info['vm_name'] = vm_name.replace(/%i/gi, i); // replace wildcard
          Sunstone.runAction("Template."+action, [template_id], extra_info);
          // OpenNebula.VM.list({success: function(r,res){
          //     res[res.length-1].VM.ID
          // }});
          //OpenNebula.VM.update({ id: id, template: template })
        }
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
          }else{
            var default_user_view = false;
          }

          if (selected_nodes[0] == '478'){
            var azure_template = true;
          }else{
            var azure_template = false;
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


          $('.memory_input_wrapper', context).removeClass("large-6 medium-8").addClass("large-12 medium-12");

          NicsSection.insert(template_json,
            $(".nicsContext"  + template_json.VMTEMPLATE.ID, context),
            { 'forceIPv4': true,
              'securityGroups': Config.isFeatureEnabled("secgroups")
            });

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

          $('input[wizard_field="PUBLIC_IP"][checked]').removeAttr('checked');


          if(Config.isFeatureEnabled("instantiate_persistent")){
            $("input.instantiate_pers", context).on("change", function(){
              var persistent = $(this).prop('checked');

              if(persistent){
                $("#vm_n_times_disabled", context).show();
                $("#vm_n_times", context).hide();
              } else {
                $("#vm_n_times_disabled", context).hide();
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
            $("#vm_n_times_disabled", context).hide();
            $("#vm_n_times", context).show();
          }

          if ($('#left_colum').height() >= $('#right_colum').height()){
            $('#left_colum').css('padding-bottom','0%');
          }else{
            $('#left_colum').css('padding-bottom','80%');
          }
          Tips.setup(context);

          $('#CostVaribl').change(function() {
            var val = $(this).val();
            $('.publicip_cost_div .cost_span').text(val);
            _calculateCost(context);
          });

          $('select[wizard_field="DRIVE"]').change(function() {
            _calculateCost();
          });

          if (azure_template == true){
            $('.disksContainer').append($('label:contains("VM Disk Size in GB")'));
            $('.OC_name_Container').append($('label:contains("OS name(choose from list below or type in the next field)")'));
            $('.capacityContext').append($('label:contains("VM Instance Size")'));
            $('.capacityContext').append($('label:contains("VM Location")'));
          }


          $('input[wizard_field="PUBLIC_IP"]').on( "click", function() {
            if ($(this).val() == 'YES' && $('span.publicip_cost_div').length == false){

              var costvaribl = $('#CostVaribl').val();
              $(this).parent().find('br').after('<span class="publicip_cost_div" hidden="" style="display:inline;color:#8a8a8a;font-weight: normal;">'+
                  '<span class="cost_value" value="'+settings.PUBLIC_IP_COST+'"></span>'+
                  '<span class="cost_span">'+costvaribl+'</span><br></span>');
              _calculateCost(context);
            }else if($(this).val() == 'NO' && $('span.publicip_cost_div').length == true){
              $('span.publicip_cost_div').remove();
              _calculateCost(context);
            }
          });

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
