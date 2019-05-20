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

    test_dataTable = $("#test_datatable", context).dataTable({
      "bSortClasses" : false,
      "bDeferRender": true,
      "aoColumnDefs": [
        { "sType": "num", "aTargets": [0,3,4]}
      ]
      // scrollY: "300px",
      // scrollX: true,
      // scrollCollapse: true,
      // paging: false,
      // "bSort": false,
      // "bPaginate": false,
      // "bInfo": false
    });

    test_fixcol_dataTable = $("#test_fixcol_datatable", context).dataTable({
      "bSortClasses" : false,
      "bDeferRender": true,
      "aoColumnDefs": [
        { "sType": "num", "aTargets": [0,3,4]}
      ]
      // paging: false,
      // "bSort": false,
      // "bPaginate": false,
      // "bInfo": false
    });


    showback_dataTable.on("click", "tbody tr", function(){
      var cells = showback_dataTable.fnGetData(this);
      var year = cells[1];
      var month = cells[2];

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
      console.log(showback_dataTable.data("vms_per_date")[year][month].VMS);
      $("#showback_vms_title", context).text(
                  Locale.months[month-1] + " " + year + " " + Locale.tr("VMs"));
      $(".showback_vms_table", context).show();
      $(".showback_select_a_row", context).hide();

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

            var months_days = days_months(2019);
            var lists = req.response;
            create_list_months(lists);

            // var months = {};
            // var shwback = [];
            // var fix_col = [];
            // for(var i in lists){
            //   if (lists[i].TOTAL > 0){
            //     fix_col.push([i]);
            //     var pole = [];
            //     for(var j in showback_days){
            //       for(var s in lists[i].showback){
            //         if (lists[i].showback[s].date == showback_days[j]){
            //           pole.push(lists[i].showback[s].TOTAL.toFixed(2));
            //           break;
            //         }
            //         if (s == lists[i].showback.length - 1){
            //           pole.push(0);
            //         }
            //       }
            //     }
            //
            //     shwback.push(pole);
            //
            //   }
            // }
            // console.log(shwback);
            // console.log(fix_col);
            //
            // test_fixcol_dataTable.fnAddData(fix_col);
            // test_dataTable.fnAddData(shwback);
            //
            $('#test_datatable_wrapper').css('padding-left','100px');
            $('#test_fixcol_datatable_wrapper').css({width:'10%',position:'absolute'});
            //
            $('.test_table').prop('hidden', false);
            //
            $('.test_fixcol_datatable').prop('hidden', false);
            // $('th:contains("Day")').click();
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

      OpenNebulaVM.showback({
        // timeout: true,
        success: function(req, response){
          _fillShowback(context, req, response);
        },
        error: Notifier.onError,
        data: options
      });

      return false;
    });
  }

  function _my_fill(lists) {
    var series = [];
    for(var i in lists){
      var date = new Date("1/"+ lists[i] +"/2019"),
          locale = "en-us",
          month = date.toLocaleString(locale, { month: "long" });
      var kk = [123,'2019','11',month + ' 2019',];

    }
    showback_dataTable.fnAddData(series);
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
      console.log(1,vms_per_date,series);
      showback_dataTable.data("vms_per_date", vms_per_date);
      showback_dataTable.fnAddData(series);
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

  function days_months(year) {
    var showback_days = {};
    var month = 1;
    while(month <= 12){
      showback_days[month] = 32 - new Date(year, month-1, 32).getDate();
      month++;
    }
    console.log(showback_days);
    return showback_days;
  }

  function create_list_months(lists) {
    var list_months = {};

    for(var i in lists){
      if (lists[i].TOTAL > 0){
        for(var j in lists[i].showback){
          var day = lists[i].showback[j].date.split('/')[0] * 1;
          var month = lists[i].showback[j].date.split('/')[1] * 1;
          var total = lists[i].showback[j].TOTAL;
          var total_and_hour = lists[i].showback[j].TOTAL.toFixed(2) + '/' + lists[i].showback[j].work_time.toFixed(4);

          if (list_months[month] == undefined){
            list_months[month] = {};
            list_months[month][day] = {};
            list_months[month][day][i] =  total_and_hour;
          }else{
            if (list_months[month][day] == undefined){
              list_months[month][day] = {};
              list_months[month][day][i] =  total_and_hour;
            }else{
              list_months[month][day][i] =  total_and_hour;
            }
          }

          if (list_months[month]['total'] == undefined){
            list_months[month]['total'] = total;
          }else{
            list_months[month]['total'] += total;
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
