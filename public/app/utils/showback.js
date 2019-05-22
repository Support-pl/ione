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

  var TemplateHTML = require('hbs!./showback/html');
  var Locale = require('utils/locale');
  var OpenNebulaVM = require('opennebula/vm');
  var Notifier = require('utils/notifier');
  var ResourceSelect = require('utils/resource-select');
  var Settings = require('opennebula/settings');
  var lists_month;

  require('flot');
  require('flot.stack');
  require('flot.resize');
  require('flot.tooltip');
  require('flot.time');

  function _html(){
    var html = TemplateHTML({});

    return html;
  }

  // context is a jQuery selector
  // The following options can be set:
  //   fixed_user     fix an owner user ID. Use "" to fix to "any user"
  //   fixed_group    fix an owner group ID. Use "" to fix to "any group"
  function _setup(context, opt) {
    if (opt == undefined){
      opt = {};
    }



    //--------------------------------------------------------------------------
    // VM owner: all, group, user
    //--------------------------------------------------------------------------

    if (opt.fixed_user != undefined){
      $("#showback_user_container", context).hide();
    } else {
      ResourceSelect.insert({
          context: $('#showback_user_select', context),
          resourceName: 'User',
          initValue: -1,
          extraOptions: '<option value="-1">' + Locale.tr("<< me >>") + '</option>'
        });
    }

    if (opt.fixed_group != undefined){
      $("#showback_group_container", context).hide();
    } else {
      ResourceSelect.insert({
          context: $('#showback_group_select', context),
          resourceName: 'Group',
          emptyValue: true
        });
    }

    showback_dataTable = $("#showback_datatable",context).dataTable({
      "bSortClasses" : false,
      "bDeferRender": true,
      "iDisplayLength": 6,
      "sDom": "t<'row collapse'<'small-12 columns'p>>",
      "aoColumnDefs": [
          { "bVisible": false, "aTargets": [0,1,2]},
          { "sType": "num", "aTargets": [4]}
        ]
    });

    showback_dataTable.fnSort( [ [0, "desc"] ] );


    showback_dataTable.on("click", "tbody tr", function(){
      var cells = showback_dataTable.fnGetData(this);
      var year = cells[1];
      var month = cells[2];


      if (config.user_id == '721'){
        $('.test_table').hide();
        $('#test_datatable_wrapper').remove();
        $('#test_datatable').remove();
        $('#div_test_datatable').append('<table id="test_datatable" class="hover"><thead><tr></tr></thead><tbody></tbody><tfoot><tr id="tr_total"></tr></tfoot></table>');
        var months_days = days_month(2019,month);
        var vms = {};
        $('#test_datatable thead tr').append('<th>'+Locale.tr("DAY")+'</th>');
        for(var i in lists_month[month]['vms']) {
          $('#test_datatable thead tr').append('<th>'+i+'</th>');
          vms[i] = lists_month[month]['vms'][i];
        }
        $('#test_datatable thead tr').append('<th>'+Locale.tr("Total")+'</th>');
        var showback = [];
        for(var i in lists_month[month]){
          if (!isNaN(i)){
            var pole = [i];
            for(var j in  vms){
              if ( lists_month[month][i][j] != undefined){
                pole.push(lists_month[month][i][j]);
              }else{
                pole.push('-');
              }
            }
            pole.push(lists_month[month][i]['day_total'].toFixed(2));

            showback.push(pole);
          }
        }
        $('#test_datatable #tr_total').append('<td>'+Locale.tr("Total")+'</td>');
        for(var j in  vms){
          if (vms[j]['time'].toFixed(2) < 0.01){
            $('#test_datatable #tr_total').append('<td>'+vms[j]['cost'].toFixed(2)+'</td>');
          }else{
            $('#test_datatable #tr_total').append('<td>'+vms[j]['cost'].toFixed(2)+'/'+vms[j]['time'].toFixed(2)+'</td>');
          }
        }
        $('#test_datatable #tr_total').append('<td>'+lists_month[month]['total'].toFixed(2)+'</td>');


        test_dataTable = $("#test_datatable", context).dataTable({
          scrollX: true,
          scrollCollapse: true
        });

        test_dataTable.fnClearTable();
        $('.test_table').show();
        test_dataTable.fnAddData(showback);

        $("#test_title", context).text(Locale.months[month-1] + " " + year + " " + Locale.tr("VMs"));
        $(".showback_select_a_row", context).hide();
      }else{
        showback_vms_dataTable = $("#showback_vms_datatable",context).dataTable({
          "bSortClasses" : false,
          "bDeferRender": true,
          "aoColumnDefs": [
            { "sType": "num", "aTargets": [0,3,4]}
          ]
        });

        showback_vms_dataTable.fnClearTable();
        showback_vms_dataTable.fnAddData(
            showback_dataTable.data("vms_per_date")[year][month].VMS);
        $("#showback_vms_title", context).text(
            Locale.months[month-1] + " " + year + " " + Locale.tr("VMs"));
        $(".showback_vms_table", context).show();
        $(".showback_select_a_row", context).hide();
      }

    });

    //--------------------------------------------------------------------------
    // Submit request
    //--------------------------------------------------------------------------

    $("#showback_submit", context).on("click", function(){
      var options = {};

      if (config.user_id == '721'){
        var uid = config.user_id;
        var edate = Math.round(Date.now() / 1000);
        var param = {uid:uid,stime:0,etime:edate,group_by_day:true,success:function (req, res) {
            lists = req.response;
            lists_month = create_list_months(lists);

            OpenNebulaVM.showback({
              // timeout: true,
              success: function(req, response){
                _fillShowback(context, req, response);
              },
              error: Notifier.onError,
              data: options
            });
          }};
        Settings.showback(param);
      }



      var userfilter;
      var group;

      if (opt.fixed_user != undefined){
        userfilter = opt.fixed_user;
      } else {
        userfilter = $("#showback_user_select .resource_list_select", context).val();
      }

      if (opt.fixed_group != undefined){
        group = opt.fixed_group;
      } else {
        group = $("#showback_group_select .resource_list_select", context).val();
      }

      if(userfilter != ""){
        options.userfilter = userfilter;
      }

      if(group != ""){
        options.group = group;
      }



      return false;
    });
  }

  function _fillShowback(context, req, response) {
    $("#showback_no_data", context).hide();

    if(response.SHOWBACK_RECORDS == undefined){
      $("#showback_placeholder", context).show();
      $("#showback_content", context).hide();

      $("#showback_no_data", context).show();
      return false;
    }

    var vms_per_date = {};
    $.each(response.SHOWBACK_RECORDS.SHOWBACK, function(index, showback){
      if (vms_per_date[showback.YEAR] == undefined) {
        vms_per_date[showback.YEAR] = {};
      }

      if (vms_per_date[showback.YEAR][showback.MONTH] == undefined) {
        vms_per_date[showback.YEAR][showback.MONTH] = {
          "VMS": [],
          "TOTAL": 0
        };
      }

      vms_per_date[showback.YEAR][showback.MONTH].VMS.push(
        [ showback.VMID,
          showback.VMNAME,
          showback.UNAME,
          showback.HOURS,
          showback.TOTAL_COST
        ]);

      vms_per_date[showback.YEAR][showback.MONTH].TOTAL += parseFloat(showback.TOTAL_COST);
    });

    var series = []
    var showback_data = [];
    $.each(vms_per_date, function(year, months){
      $.each(months, function(month, value){
        series.push(
          [ (new Date(year, month-1)).getTime(),
            year,
            month,
            Locale.months[month-1] + " " + year, value.TOTAL.toFixed(2)
          ]);

        showback_data.push([(new Date(year, month-1)), value.TOTAL.toFixed(2) ]);
      });
    });

    showback_dataTable.fnClearTable();
    if (series.length > 0) {
      showback_dataTable.data("vms_per_date", vms_per_date);
      if (config.user_id == '721'){
        var series = [];
        for(var i in lists_month){
          series.push([123,'2019',i,Locale.months[i-1] + ' 2019',lists_month[i].total]);
        }
        showback_dataTable.fnAddData(series);
      }else{
        showback_dataTable.fnAddData(series);
      }

    }

    var showback_plot_series = [];
    showback_plot_series.push(
    {
      label: Locale.tr("Showback"),
      data: showback_data
    });

    var options = {
      // colors: [ "#cdebf5", "#2ba6cb", "#6f6f6f" ]
      colors: [ "#2ba6cb", "#707D85", "#AC5A62" ],
      legend: {
        show: false
      },
      xaxis : {
        mode: "time",
        color: "#efefef",
        size: 8,
        minTickSize: [1, "month"]
      },
      yaxis : {
        show: false
      },
      series: {
        bars: {
          show: true,
          lineWidth: 0,
          barWidth: 24 * 60 * 60 * 1000 * 20,
          fill: true,
          align: "left"
        }
      },
      grid: {
        borderWidth: 1,
        borderColor: "#efefef",
        hoverable: true
      }
      //tooltip: true,
      //tooltipOpts: {
      //    content: "%x"
      //}
    };

    var showback_plot = $.plot(
        $("#showback_graph", context), showback_plot_series, options);

    $("#showback_placeholder", context).hide();
    $("#showback_content", context).show();
  }

  function days_month(year,month) {
    return 32 - new Date(year, month-1, 32).getDate();
  }

  function create_list_months(lists) {
    var list_months = {};

    for(var i in lists){
      if (lists[i].TOTAL > 0){
        for(var j in lists[i].showback){
          var day = lists[i].showback[j].date.split('/')[0] * 1;
          var month = lists[i].showback[j].date.split('/')[1] * 1;
          var cost = lists[i].showback[j].TOTAL * 1;
          if (lists[i].showback[j].work_time.toFixed(4) < 0.01){
            var cost_and_hour = lists[i].showback[j].TOTAL.toFixed(2);
          }else{
            var cost_and_hour = lists[i].showback[j].TOTAL.toFixed(2) + '/' + lists[i].showback[j].work_time.toFixed(2);
          }

          if (list_months[month] == undefined){
            list_months[month] = {};
            list_months[month][day] = {};
            list_months[month][day][i] =  cost_and_hour;
          }else{
            if (list_months[month][day] == undefined){
              list_months[month][day] = {};
              list_months[month][day][i] =  cost_and_hour;
            }else{
              list_months[month][day][i] =  cost_and_hour;
            }
          }

          if (list_months[month][day]['day_total'] == undefined){
            list_months[month][day]['day_total'] = cost;
          }else{
            list_months[month][day]['day_total']+= cost;
          }

          if (list_months[month]['total'] == undefined){
            list_months[month]['total'] = cost;
          }else{
            list_months[month]['total'] += cost;
          }

          if (list_months[month]['vms'] == undefined){
            list_months[month]['vms'] = {};
            list_months[month]['vms'][i] = {'cost':cost,'time':lists[i].showback[j].work_time};
          }else{
            if (list_months[month]['vms'][i] == undefined){
              list_months[month]['vms'][i] = {'cost':cost,'time':lists[i].showback[j].work_time};
            }else{
              list_months[month]['vms'][i]['time'] += lists[i].showback[j].work_time;
              list_months[month]['vms'][i]['cost'] += cost;
            }
          }

        }
      }

    }
    
    console.log(list_months);
    return list_months;
  }
  


  return {
    'html': _html,
    'setup': _setup
  };
});
