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

define(function (require) {
  var TemplateHTML = require("hbs!./showback/html");
  var Locale = require("utils/locale");
  var OpenNebulaVM = require("opennebula/vm");
  var Notifier = require("utils/notifier");
  var ResourceSelect = require("utils/resource-select");
  var Settings = require("opennebula/settings");
  var Tips = require("utils/tips");

  var showbackList = require("./showback/showbackList")

  var reqLists;
  var Colors = {};
  var select_labels = {
    cost: true,
    cpu: false,
    memory: false,
    disk: false,
    pub_ip: false,
    work_time: false
  };

  require("flot");
  require("flot.stack");
  require("flot.resize");
  require("flot.tooltip");
  require("flot.time");

  function _html() {
    var html = TemplateHTML({});

    return html;
  }


  // context is a jQuery selector
  // The following options can be set:
  //   fixed_user     fix an owner user ID. Use "" to fix to "any user"
  //   fixed_group    fix an owner group ID. Use "" to fix to "any group"
  function _setup(context, opt) {
    if (opt == undefined) {
      opt = {};
    }
    constrColors();
    //--------------------------------------------------------------------------
    // VM owner: all, group, user
    //--------------------------------------------------------------------------
    var that = this;
    that.onshow = _onShow(context, that);
    if (opt.fixed_user != undefined) {
      $("#showback_user_container", context).hide();
    } else {
      ResourceSelect.insert({
        context: $("#showback_user_select", context),
        resourceName: "User",
        initValue: -1,
        extraOptions: '<option value="-1">' + Locale.tr("<< me >>") + "</option>"
      });
    }

    if (opt.fixed_group != undefined) {
      $("#showback_group_container", context).hide();
    } else {
      ResourceSelect.insert({
        context: $("#showback_group_select", context),
        resourceName: "Group",
        emptyValue: true
      });
    }

    showback_dataTable = $("#showback_datatable", context).dataTable({
      bSortClasses: false,
      bDeferRender: true,
      iDisplayLength: 6,
      sDom: "t<'row collapse'<'small-12 columns'p>>",
      aoColumnDefs: [{
        bVisible: false,
        aTargets: [0, 1, 2]
      },
      {
        sType: "num",
        aTargets: [4]
      },
      {
        aDataSort: [0],
        aTargets: [3]
      }
      ]
    });

    showback_dataTable.fnSort([
      [3, "desc"]
    ]);

    showback_dataTable.on("click", "tbody tr", function () {
      var cells = showback_dataTable.fnGetData(this);
      var year = cells[1];
      var month = cells[2];

      if (showbackList.list[year][month]['MonthTotal']['cost'] > 0) {
        create_diagram(getDataset(year, month), year, month);
        $("#test_table_graph").show();
        $('#show_all_vms').show();
        $('#test_table_graph_legend p[data-percent="0.00"]').hide();
        $("#test_table_graph_legend").show();
      }

      update_table_template(year, month)
      test_dataTable = $("#test_datatable", context).dataTable({
        scrollX: true,
        scrollCollapse: true,
        bInfo: false,
        bPaginate: false,
        "bSort": false,
        aoColumnDefs: [{
          bVisible: false,
          aTargets: [0]
        }],
      });

      test_dataTable2 = $("#test_datatable2", context).dataTable({
        scrollX: true,
        scrollCollapse: true,
        bInfo: false,
        bPaginate: false,
        "bSort": false
      });

      $("#table_test_title").off("click", ".showback_div_label");
      $("#table_test_title .showback_div_label", context)
        .css("border", "2px solid #00000036")
        .removeClass("active");
      $("#table_test_title #label_cost", context)
        .css("border", "2px solid #4dbbd3")
        .addClass("active");

      $("#table_test_title", context).on(
        "click",
        ".showback_div_label",
        function () {
          if (getSelectLabel(this)) {
            test_dataTable.fnClearTable();
            let showback = getShowback(year, month)
            console.log('showback table data', showback)
            test_dataTable.fnAddData(showback);
            test_dataTable2.fnClearTable();
            test_dataTable2.fnAddData(showback);
            ////////
            let num = 0;
            let sum = 0;
            for (let vmId in showbackList.list[year][month]['VMsMonthTotal']) {
              sum = 0
              for (let l in select_labels) {
                if (select_labels[l]) {
                  sum += showbackList.list[year][month]['VMsMonthTotal'][vmId][l];
                }
              }

              console.log('summa', sum);
              $("#test_datatable #tr_total td").eq(num).text(isNaN(sum) ? 0.00 : sum.toFixed(2));
              num++;
            }
            let total = 0
            for (let label in select_labels) {
              if (select_labels[label]) {
                total += showbackList.list[year][month]['MonthTotal'][label];
              }
            }
            $("#test_datatable #tr_total td").eq(num).text(total.toFixed(2));
            ////////

            $('#test_datatable tbody tr').hover(function () {
              let indx = $('#test_datatable tbody tr').index($(this));
              let second_row = $('#test_datatable2 tbody tr').eq(indx);
              $(second_row).css('background-color', '#f4f4f4');
              $(this).css('background-color', '#f4f4f4');
            }, function () {
              let indx = $('#test_datatable tbody tr').index($(this));
              let second_row = $('#test_datatable2 tbody tr').eq(indx);
              $(second_row).css('background-color', 'white');
              $(this).css('background-color', 'white');
            }
            );

            $('#test_datatable2 tbody tr').hover(function () {
              let indx = $('#test_datatable2 tbody tr').index($(this));
              let second_row = $('#test_datatable tbody tr').eq(indx);
              $(second_row).css('background-color', '#f4f4f4');
              $(this).css('background-color', '#f4f4f4');
            }, function () {
              let indx = $('#test_datatable2 tbody tr').index($(this));
              let second_row = $('#test_datatable tbody tr').eq(indx);
              $(second_row).css('background-color', 'white');
              $(this).css('background-color', 'white');
            }
            );

            test_dataTable.$("tr").css("border-top", "1px solid lightgray");
            test_dataTable2.$("tr").css("border-top", "1px solid lightgray");
          }
        }
      );

      $("#test_datatable", context).on(
        "click",
        'tbody [role="row"]',
        function () {
          var cells = test_dataTable.fnGetData(this);
          var day = cells[0];
          let indx = $('#test_datatable tbody tr').index($(this));
          let second_row = $('#test_datatable2 tbody tr').eq(indx);
          if ($(this).hasClass("Shown")) {
            $(this).removeClass("Shown").next("tr").remove();

            $(second_row).removeClass('Shown').next('tr').remove();
            $(second_row).find("td").eq(0).text(day);
          } else {
            $(this).addClass("Shown").after(more_info(year, month, day));
            $(this).next("tr").show(500);

            $(second_row).addClass("Shown").find("td").eq(0).text(day + " " + getWeekDay(new Date(2019, month - 1, day)));
            $(second_row).after("<tr hidden><td>CPU<br>Disk<br>Memory<br>Public ip<br>Time</td>");
            $(second_row).next("tr").show(500)
          }
        }
      );

      $("#test_datatable2", context).on(
        "click",
        'tbody [role="row"]',
        function () {
          var cells = test_dataTable.fnGetData(this);
          var day = cells[0];
          let indx = $('#test_datatable2 tbody tr').index($(this));
          let second_row = $('#test_datatable tbody tr').eq(indx);
          if ($(this).hasClass("Shown")) {
            $(this).removeClass("Shown").next("tr").remove();
            $(this).find("td").eq(0).text(day);

            $(second_row).removeClass("Shown").next("tr").remove();
          } else {
            $(this).addClass("Shown").find("td").eq(0).text(day + " " + getWeekDay(new Date(2019, month - 1, day)));
            $(this).after("<tr hidden><td>CPU<br>Disk<br>Memory<br>Public ip<br>Time</td>");
            $(this).next("tr").show(500);

            $(second_row).addClass("Shown").after(more_info(year, month, day));
            $(second_row).next("tr").show(500);
          }
        }
      );

      test_dataTable.fnClearTable();
      $(".test_table").show();
      let showback = getShowback(year, month)
      test_dataTable.fnAddData(showback);

      test_dataTable.$("tr").css("border-top", "1px solid lightgray");

      test_dataTable.fnSort([
        [0, "desc"]
      ]);

      test_dataTable2.fnClearTable();
      test_dataTable2.fnAddData(showback);

      $('#test_datatable tbody tr').hover(function () {
        let indx = $('#test_datatable tbody tr').index($(this));
        let second_row = $('#test_datatable2 tbody tr').eq(indx);
        $(second_row).css('background-color', '#f4f4f4');
        $(this).css('background-color', '#f4f4f4');
      }, function () {
        let indx = $('#test_datatable tbody tr').index($(this));
        let second_row = $('#test_datatable2 tbody tr').eq(indx);
        $(second_row).css('background-color', 'white');
        $(this).css('background-color', 'white');
      }
      );

      $('#test_datatable2 tbody tr').hover(function () {
        let indx = $('#test_datatable2 tbody tr').index($(this));
        let second_row = $('#test_datatable tbody tr').eq(indx);
        $(second_row).css('background-color', '#f4f4f4');
        $(this).css('background-color', '#f4f4f4');
      }, function () {
        let indx = $('#test_datatable2 tbody tr').index($(this));
        let second_row = $('#test_datatable tbody tr').eq(indx);
        $(second_row).css('background-color', 'white');
        $(this).css('background-color', 'white');
      }
      );

      test_dataTable2.$("tr").css("border-top", "1px solid lightgray");
      $('#div_test_datatable2 tr[role="row"]').eq(0).css('height', $('#div_test_datatable tr[role="row"]').eq(0).css('height'));
      test_dataTable2.fnSort([
        [0, "desc"]
      ]);
      $("#test_title", context).text(
        Locale.months[month - 1] + " " + year + " " + Locale.tr("VMs")
      );
      $(".showback_select_a_row", context).hide();
    });

    //--------------------------------------------------------------------------
    // Submit request
    //--------------------------------------------------------------------------
  }

  function _onShow(context, that) {
    var uid = config.user_id;
    var edate = Math.round(Date.now() / 1000);
    var param = {
      uid: uid,
      stime: 0,
      etime: edate,
      group_by_day: true,
      success: function (req, res) {
        console.log('Get showback ->', req, res)
        reqLists = req.response.computing;
        // lists_month = create_list_months(lists);
        showbackList.create_list_months(reqLists);
        //console.log(666, req.response);
        _fillShowback(context);
      }
    };
    Settings.showbackV2(param);
    // Settings.showback(param);

    Tips.setup(context);

    return false;
  }

  function _fillShowback(context) {
    $("#showback_no_data", context).hide();

    var showback_data = [];
    showback_dataTable.fnClearTable();

    var series = [];
    for (let [year, valueY] of Object.entries(showbackList.list)) {
      for (let [month, valueM] of Object.entries(valueY)) {
        // console.log(month, valueM);
        if (valueM.MonthTotal.cost) {
          series.push([
            year + month,
            year,
            month,
            Locale.months[month - 1] + " " + year,
            valueM.MonthTotal.cost.toFixed(2)
          ]);
          showback_data.push([
            new Date(year, month - 1),
            valueM.MonthTotal.cost.toFixed(2)
          ]);
        }
      }
    }

    if (series.length > 0) {
      showback_dataTable.fnAddData(series);
    } else {
      $("#showback_placeholder i")
        .eq(0)
        .remove();
      $("#showback_placeholder i")
        .eq(0)
        .removeClass("fa-stack-3x")
        .addClass("fa-stack-2x");
      $("#showback_no_data").show();
      return false;
    }

    var showback_plot_series = [];
    showback_plot_series.push({
      label: Locale.tr("Showback"),
      data: showback_data
    });

    var options = {
      // colors: [ "#cdebf5", "#2ba6cb", "#6f6f6f" ]
      colors: ["#2ba6cb", "#707D85", "#AC5A62"],
      legend: {
        show: false
      },
      xaxis: {
        mode: "time",
        color: "#efefef",
        size: 8,
        minTickSize: [1, "month"]
      },
      yaxis: {
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
      $("#showback_graph", context),
      showback_plot_series,
      options
    );

    $("#showback_placeholder", context).hide();
    $("#showback_content", context).show();
  }
  //////////////////////////////////////////////////////////

  function update_table_template(year, month) {
    $(".test_table").hide();
    $("#test_datatable_wrapper").remove();
    $("#test_datatable2_wrapper").remove();
    $("#test_datatable").remove();
    $("#test_datatabl2").remove();
    $("#div_test_datatable").append(
      '<table id="test_datatable" class="hover"><thead><tr></tr></thead><tbody></tbody><tfoot><tr id="tr_total"></tr></tfoot></table>'
    );
    $("#div_test_datatable2").append(
      '<table id="test_datatable2" class="hover"><thead><tr><th>DAY</th></tr></thead><tbody></tbody><tfoot></tfoot></table>'
    );
    // var months_days = days_month(2019, month);
    // var vms = {};

    $("#test_datatable thead tr").append("<th>" + Locale.tr("DAY") + "</th>");

    for (let vmId in showbackList.list[year][month]["VMsMonthTotal"]) {
      $("#test_datatable thead tr").append(
        "<th>" + reqLists[vmId].name + "</th>"
      );

      $("#test_datatable #tr_total").append(
        "<td>" + showbackList.list[year][month]["VMsMonthTotal"][vmId]["cost"].toFixed(2) + "</td>"
      );
      // vms[i] = showbackList[year][month]["VMsMonthTotal"][vmId];
    }

    $("#test_datatable thead tr").append("<th>" + Locale.tr("Total") + "</th>");

    $("#test_datatable #tr_total").append(
      "<td>" + showbackList.list[year][month]["MonthTotal"]['cost'].toFixed(2) + "</td>"
    );
    // return showbackList[year][month]["VMsMonthTotal"];
  }

  function check_data(data) {
    if (data * 1 > 0) {
      return data.toFixed(2);
    } else {
      return "-";
    }
  }

  function more_info(year, month, day) {
    var more_tr = '<tr hidden>';
    // "<tr hidden><td>CPU<br>Disk<br>Memory<br>Public ip<br>Time</td>";
    for (var vmId in showbackList.list[year][month]['VMsMonthTotal']) {
      if (showbackList.list[year][month][day][vmId]) {
        more_tr +=
          "<td>" +
          check_data(showbackList.list[year][month][day][vmId].cpu) +
          "<br>" +
          check_data(showbackList.list[year][month][day][vmId].disk) +
          "<br>" +
          check_data(showbackList.list[year][month][day][vmId].memory) +
          "<br>" +
          check_data(showbackList.list[year][month][day][vmId].pub_ip) +
          "<br>" +
          check_data(showbackList.list[year][month][day][vmId].work_time) +
          "</td>";
      } else {
        more_tr += "<td></td>";
      }
    }
    more_tr +=
      "<td>" +
      check_data(showbackList.list[year][month][day]["DayTotal"].cpu) +
      "<br>" +
      check_data(showbackList.list[year][month][day]["DayTotal"].disk) +
      "<br>" +
      check_data(showbackList.list[year][month][day]["DayTotal"].memory) +
      "<br>" +
      check_data(showbackList.list[year][month][day]["DayTotal"].pub_ip) +
      "<br>" +
      check_data(showbackList.list[year][month][day]["DayTotal"].work_time) +
      "</td></tr>";
    return more_tr;
  }

  function getWeekDay(date) {
    var days = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ];
    return days[date.getDay()];
  }

  function getShowback(year, month) {
    var showback = [];
    let pole = [];
    let sum = 0;
    for (let day in showbackList.list[year][month]) {
      if (!isNaN(day)) {
        pole = [day];
        for (let vmId in showbackList.list[year][month]['VMsMonthTotal']) {
          if (showbackList.list[year][month][day][vmId]) {
            sum = 0;
            for (let l in select_labels) {
              // console.log(year, month, day, vmId, l, '--->', showbackList.list[year][month][day][vmId][l])
              if (select_labels[l] == true && showbackList.list[year][month][day][vmId][l] > 0) {
                sum += showbackList.list[year][month][day][vmId][l];
              }
            }
            if (sum > 0) {
              pole.push(sum.toFixed(2));
            } else {
              pole.push("-");
            }
          } else {
            pole.push("-");
          }
        }
        sum = 0;
        for (var l in select_labels) {
          if (
            select_labels[l] == true &&
            showbackList.list[year][month][day]["DayTotal"][l] > 0
          ) {
            sum += showbackList.list[year][month][day]["DayTotal"][l];
          }
        }
        if (sum > 0) {
          pole.push(sum.toFixed(2));
        } else {
          pole.push("-");
        }
        showback.push(pole);
      }
    }
    return showback;
  }

  function getSelectLabel(that) {
    var flag = true;
    switch ($(that).attr("id")) {
      case "label_cost":
        offLabelsButOne("cost");
        break;
      case "label_cpu":
        checkStatus("cpu", flag);
        break;
      case "label_memory":
        checkStatus("memory", flag);
        break;
      case "label_disk":
        checkStatus("disk", flag);
        break;
      case "label_pub_ip":
        checkStatus("pub_ip", flag);
        break;
      case "label_work_time":
        offLabelsButOne("work_time");
        break;
    }
    CheckSelectLabels();
    //console.log($(that).attr("id"),select_labels);
    return flag;
  }

  function checkStatus(label, flag) {
    var kolOn = 0;
    for (var i in select_labels) {
      if (select_labels[i] == true && i != "work_time" && i != "cost") {
        kolOn++;
      }
    }

    if (select_labels[label] == true) {
      if (kolOn > 1) {
        select_labels[label] = false;
      } else {
        flag = false;
      }
    } else {
      select_labels[label] = true;
      select_labels["work_time"] = false;
      select_labels["cost"] = false;
    }
  }

  function offLabelsButOne(label) {
    for (var i in select_labels) {
      select_labels[i] = false;
    }
    select_labels[label] = true;
  }

  function CheckSelectLabels() {
    for (var i in select_labels) {
      if (select_labels[i]) {
        $("#label_" + i)
          .css("border", "2px solid #4dbbd3")
          .addClass("active");
      } else {
        $("#label_" + i)
          .css("border", "2px solid #00000036")
          .removeClass("active");
      }
    }
  }

  function getDataset(year, month) {
    var total = showbackList.list[year][month]['MonthTotal']['cost'];
    var legend_arr = [];
    var dataset = [];
    var kk = 0;
    $("#test_table_graph_legend").text("");
    for (let vmId in showbackList.list[year][month]['VMsMonthTotal']) {
      var percent = (100 / (total / showbackList.list[year][month]['VMsMonthTotal'][vmId]['cost'])).toFixed(2);
      legend_arr.push({
        val_percent: percent,
        vmsId: vmId,
        label: vmId + " - " + reqLists[vmId].name
      });
    }
    legend_arr.sort(function (a, b) {
      return a.val_percent == b.val_percent ? 0 : +(a.val_percent * 1 < b.val_percent * 1) || -1;
    });
    legend_arr.forEach(element => {
      $("#test_table_graph_legend").append(
        '<p data-percent="' + element.val_percent + '" data-vmsId="' + element.vmsId +
        '" style="float: left;width: 50%;"><i class="fa fa-square" aria-hidden="true" style="color:' +
        Colors.names[kk] + '"></i>  ' + element.label + "</p>"
      );
      if (element.val_percent > 0) {
        dataset.push({
          value: element.val_percent,
          color: Colors.names[kk],
          vmsId: element.vmsId
        });
      }
      if (kk != 6) {
        kk++;
      } else {
        kk = 0;
      }
    });

    return dataset;
  }

  function create_diagram(dataset, year, month) {
    var maxValue = 25;
    $("#test_table_graph").text("");
    var container = $("#test_table_graph");

    var addSector = function (data, startAngle, collapse) {
      var sectorDeg = 3.6 * data.value;
      var skewDeg = 90 + sectorDeg;
      var rotateDeg = startAngle;
      if (collapse) {
        skewDeg++;
      }

      var sector = $("<div>", {
        class: "sector"
      }).css({
        background: data.color,
        transform: "rotate(" + rotateDeg + "deg) skewY(" + skewDeg + "deg)"
      }).attr({
        "data-percent": data.value,
        "data-vmsId": data.vmsId
      });
      container.append(sector);

      return startAngle + sectorDeg;
    };

    dataset.reduce(function (prev, curr) {
      return (function addPart(data, angle) {
        if (data.value <= maxValue) {
          return addSector(data, angle, false);
        }

        return addPart({
          value: data.value - maxValue,
          vmsId: data.vmsId,
          color: data.color
        },
          addSector({
            value: maxValue,
            vmsId: data.vmsId,
            color: data.color
          },
            angle,
            true
          )
        );
      })(curr, prev);
    }, 0);


    $('#test_table_graph .sector').hover(function () {
      let vmsid = $(this).attr('data-vmsid');
      $('#test_table_graph .sector:not([data-vmsid="' + vmsid + '"])').css('opacity', '0.3');
      let percent = $('#test_table_graph_legend p[data-vmsid="' + vmsid + '"]').attr('data-percent');
      $('#test_table_graph').attr('data-percent', percent + '%');
      $('#test_table_graph_legend p:not([data-vmsid="' + vmsid + '"])').hide();
      let legend_vm = $('#test_table_graph_legend p[data-vmsid="' + vmsid + '"]').css('width', '100%').html();
      let info_field_name = { 'Total': 'cost', 'CPU': 'cpu', 'Memory': 'memory', 'Disk': 'disk', 'Public IP': 'pub_ip', 'Work time': 'work_time' };
      let full_info_vm = '<span>';
      // console.log(showbackList.list[year][month]['VMsMonthTotal'][vmsid]);
      for (let i in info_field_name) {
        // console.log(info_field_name[i])
        full_info_vm += '<br>' + i + ': ' + showbackList.list[year][month]['VMsMonthTotal'][vmsid][info_field_name[i]].toFixed(2);

      }
      full_info_vm += '</span>';
      $('#test_table_graph_legend p[data-vmsid="' + vmsid + '"]').html(legend_vm + full_info_vm);
    }, function () {
      let vmsid = $(this).attr('data-vmsid');
      $('#test_table_graph .sector:not([data-vmsid="' + vmsid + '"])').css('opacity', '1');
      $('#test_table_graph').attr('data-percent', '100%');
      $('#test_table_graph_legend p[data-vmsid="' + vmsid + '"]').css('width', '50%').find('span').remove();
      $('#test_table_graph_legend p').show();
      if (!$('#show_all_vms input').prop('checked')) {
        $('#test_table_graph_legend p[data-percent="0.00"]').hide();
      }
    }
    );

    $('#test_table_graph_legend p').hover(function () {
      $('#test_table_graph .sector:not([data-vmsid="' + $(this).attr('data-vmsid') + '"])').css('opacity', '0.3');
      $('#test_table_graph').attr('data-percent', $(this).attr('data-percent') + '%');
    }, function () {
      $('#test_table_graph .sector:not([data-vmsid="' + $(this).attr('data-vmsid') + '"])').css('opacity', '1');
      $('#test_table_graph').attr('data-percent', '100%');
    });

    $('#show_all_vms input').change(function () {
      if ($(this).prop('checked')) {
        $('#test_table_graph_legend p').show();
      } else {
        $('#test_table_graph_legend p[data-percent="0.00"]').hide();
      }
    });
  }

  function constrColors() {
    Colors.names = [
      "#add8e6",
      "#00ccff",
      "#90ee90",
      "#ffb6c1",
      "#ffcc66",
      "lightsalmon",
      "lightseagreen"
    ];
  }

  return {
    html: _html,
    setup: _setup
  };
});