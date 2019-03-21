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

  $.get("settings", function(data, status){
    settings = data.response;
    FormPanel.prototype.setTemplateIds = _setTemplateIds;
    FormPanel.prototype.htmlWizard = _html;
    FormPanel.prototype.submitWizard = _submitWizard;
    FormPanel.prototype.onShow = _onShow;
    FormPanel.prototype.setup = _setup;
    FormPanel.prototype.calculateCost = _calculateCost;
  });

  return FormPanel;

  /*
    FUNCTION DEFINITIONS
   */

  function _html() {
    if (config.user_config["default_view"] == 'user'){
      this.default_view = true;
    }else{
      this.default_view = false;
    }
    return TemplateHTML({
      'formPanelId': this.formPanelId,
      'default_view': this.default_view
    });
  }

  function _setup(context) {
    var that = this;

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

     $('#CostVaribl').change(function() {
       var val = $(this).val();
       $('.capacity_cost_div span').text(val);
       $('.provision_create_template_disk_cost_div span').text(val);
       $('.total_cost_div span').text(val);
       $('.publicip_cost_div span').text(val);
       _calculateCost(context);
     });

  }

  function _calculateCost(){
    $.each($(".template-row", this.formContext), function(){
      var varibl = $('#CostVaribl').val();
      var capacity_val = parseFloat( $(".capacity_cost_div .cost_value", $(this)).attr('value') );
      var disk_val = parseFloat( $(".provision_create_template_disk_cost_div .cost_value", $(this)).attr('value') );
      var publickip_val = parseFloat( $(".publicip_cost_div .cost_value", $(this)).attr('value') );
      var disks_costs = JSON.parse(settings.DISK_COSTS);
      if ($('select[wizard_field="DRIVE"]').val() == "HDD"){
        disk_cost = disks_costs.HDD;
      }else if ($('select[wizard_field="DRIVE"]').val() == "SSD"){
        disk_cost = disks_costs.SSD;
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

      $('.capacity_cost_div span.cost_value').text((capacity_val * time_val).toFixed(3));
      $('.provision_create_template_disk_cost_div span.cost_value').text((disk_val * time_val * disk_cost).toFixed(3));
      $(".publicip_cost_div .cost_value", $(this)).text((publickip_val * time_val).toFixed(3));

      var capacity_text = parseFloat( $(".capacity_cost_div .cost_value", $(this)).text() );
      var disk_text = parseFloat( $(".provision_create_template_disk_cost_div .cost_value", $(this)).text() );
      var publicip_text = parseFloat( $(".publicip_cost_div .cost_value", $(this)).text() );

      if(Number.isNaN(publicip_text)){
        publicip_text = 0;
      }

      if(Number.isNaN(capacity_text)){
        capacity_text = 0;
      }
      if(Number.isNaN(disk_text)){
        disk_text = 0;
      }

      var total = capacity_text + disk_text + publicip_text;

      if (total != 0 && Config.isFeatureEnabled("showback")) {
        $(".total_cost_div", $(this)).show();

        $(".total_cost_div .cost_value", $(this)).text( (capacity_text + disk_text + publicip_text).toFixed(3) );
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

      var real_disk_cost = parseFloat( $(".provision_create_template_disk_cost_div .cost_value").attr('value') ) * disk_cost + '';

      if (tmp_json.PUBLIC_IP == "YES"){
        $.extend(tmp_json,
                {
                  PUBLIC_IP_COST: settings.PUBLIC_IP_COST,
                  DRIVE_COST:real_disk_cost,
                  NIC: {
                    NETWORK: "btk-inet",
                    NETWORK_UNAME: "CloudAdmin"
                  }
                });
      } else {
        $.extend(tmp_json, {DRIVE_COST:real_disk_cost});
      }

      extra_info['template'] = tmp_json;
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

          templatesContext.append(
            TemplateRowHTML(
              { element: template_json.VMTEMPLATE,
                capacityInputsHTML: CapacityInputs.html(),
                hostsDatatable: that.hostsTable.dataTableHTML,
                dsDatatable: that.datastoresTable.dataTableHTML
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

          DisksResize.insert({
            template_base_json: that.template_base_objects[template_json.VMTEMPLATE.ID],
            template_json: template_json,
            disksContext: $(".disksContext"  + template_json.VMTEMPLATE.ID, context),
            force_persistent: $("input.instantiate_pers", context).prop("checked"),
            cost_callback: _calculateCost,
            uinput_mb: true
          });

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

          if (config.user_config["lang"] == "en_US") {
            UserInputs.vmTemplateInsert(
                inputs_div,
                template_json,
                {text_header: '<i class="fa fa-gears" style="padding-bottom: 27px;"></i> ' + Locale.tr("Custom Attributes")});
          }else{
            UserInputs.vmTemplateInsert(
                inputs_div,
                template_json,
                {text_header: '<i class="fa fa-gears"></i> ' + Locale.tr("Custom Attributes")});
          }

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
            cpuCost = Config.onedConf.DEFAULT_COST.CPU_COST;
          }

          if (memoryCost == undefined){
            memoryCost = Config.onedConf.DEFAULT_COST.MEMORY_COST;
          } else {
            if (memoryUnitCost == "GB"){
              memoryCost = memoryCost / 1024;
            }
          }

          if ((cpuCost != 0 || memoryCost != 0) && Config.isFeatureEnabled("showback")) {
            $(".capacity_cost_div", capacityContext).show();

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

          if ($('#disksContext').text() == ""){
            $('#disksContext').replaceWith( $('#OC_name') );
            $('#OC_name').css('width','34%');
            $('#OC_name').after($('#capacityContext'))
          }

          $('select[wizard_field="DRIVE"]').change(function() {
            _calculateCost();
          });

          $('input[wizard_field="PUBLIC_IP"]').on( "click", function() {
            if ($(this).val() == 'YES' && $('span.publicip_cost_div').length == false){

              var costvaribl = $('#CostVaribl').val();
              $(this).parent().find('br').after('<span class="publicip_cost_div" hidden="" style="display:inline;color:#8a8a8a;font-weight: normal;">'+
                  '<span class="cost_value" value="'+settings.PUBLIC_IP_COST+'"></span>'+
                  '<span>'+costvaribl+'</span><br></span>');
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
