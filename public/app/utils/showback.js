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
  var TemplateHTML = require("hbs!./showback/html");
  var Locale = require("utils/locale");
  var OpenNebulaVM = require("opennebula/vm");
  var Notifier = require("utils/notifier");
  var ResourceSelect = require("utils/resource-select");
  var Settings = require("opennebula/settings");
  var Tips = require("utils/tips");
  var lists_month;
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
        extraOptions:
          '<option value="-1">' + Locale.tr("<< me >>") + "</option>"
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
      aoColumnDefs: [
        { bVisible: false, aTargets: [0, 1, 2] },
        { sType: "num", aTargets: [4] },
        { aDataSort: [2], aTargets: [3] }
      ]
    });

    showback_dataTable.fnSort([[3, "desc"]]);

    showback_dataTable.on("click", "tbody tr", function() {
      var cells = showback_dataTable.fnGetData(this);
      var year = cells[1];
      var month = cells[2];

      var vms = update_table_template(month);
      if (lists_month[month].total.cost > 0) {
        create_diagram(getDataset(month));
        $("#test_table_graph").show();
        $("#test_table_graph_legend").show();
      }

      test_dataTable = $("#test_datatable", context).dataTable({
        scrollX: true,
        scrollCollapse: true,
        bInfo: false,
        bPaginate: false
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
        function() {
          if (getSelectLabel(this)) {
            test_dataTable.fnClearTable();
            test_dataTable.fnAddData(getShowback(month, vms));
            ////////
            var total = 0;
            var num = 1;
            for (var j in vms) {
              var sum = 0;
              for (var l in select_labels) {
                if (select_labels[l]) {
                  sum += vms[j][l];
                  total += vms[j][l];
                }
              }
              $("tr#tr_total:eq(1)")
                .find("td")
                .eq(num)
                .text(sum.toFixed(2));
              num++;
            }
            $("tr#tr_total:eq(1)")
              .find("td")
              .eq(num)
              .text(total.toFixed(2));
            ////////
            test_dataTable.$("tr").css("border-top", "1px solid lightgray");
          }
        }
      );

      $("#test_datatable", context).on(
        "click",
        'tbody [role="row"]',
        function() {
          var cells = test_dataTable.fnGetData(this);
          var day = cells[0];
          if ($(this).hasClass("Shown")) {
            $(this)
              .next("tr")
              .remove();
            $(this)
              .find("td")
              .eq(0)
              .text(day);
            $(this).removeClass("Shown");
          } else {
            $(this)
              .find("td")
              .eq(0)
              .text(day + " " + getWeekDay(new Date(2019, month - 1, day)));
            $(this).after(more_info(month, day, vms));
            $(this)
              .next("tr")
              .show(500);
            $(this).addClass("Shown");
          }
        }
      );

      test_dataTable.fnClearTable();
      $(".test_table").show();
      test_dataTable.fnAddData(getShowback(month, vms));

      test_dataTable.$("tr").css("border-top", "1px solid lightgray");

      test_dataTable.fnSort([[0, "desc"]]);
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
      success: function(req, res) {
        lists = req.response;
        lists_month = create_list_months(lists);
        _fillShowback(context);
      }
    };
    Settings.showback(param);

    Tips.setup(context);

    return false;
  }

  function _fillShowback(context) {
    $("#showback_no_data", context).hide();

    var showback_data = [];
    showback_dataTable.fnClearTable();

    var series = [];
    for (var i in lists_month) {
      series.push([
        123,
        "2019",
        i,
        Locale.months[i - 1] + " 2019",
        lists_month[i].total.cost.toFixed(2)
      ]);
      showback_data.push([
        new Date(2019, i - 1),
        lists_month[i].total.cost.toFixed(2)
      ]);
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

  function days_month(year, month) {
    return 32 - new Date(year, month - 1, 32).getDate();
  }

  function create_list_months(lists) {
    var list_months = {};

    for (var i in lists) {
      //if (lists[i].TOTAL > 0){
      for (var j in lists[i].showback) {
        var day = lists[i].showback[j].date.split("/")[0] * 1;
        var month = lists[i].showback[j].date.split("/")[1] * 1;

        var cost = lists[i].showback[j].TOTAL * 1;
        var cpu = lists[i].showback[j].CPU * 1;
        var disk = lists[i].showback[j].DISK * 1;
        var memor = lists[i].showback[j].MEMORY * 1;
        var pub_ip = lists[i].showback[j].PUBLIC_IP * 1;
        var work_time = lists[i].showback[j].work_time * 1;

        if (list_months[month] == undefined) {
          list_months[month] = {};
          list_months[month][day] = {};
          list_months[month][day][i] = {
            cost: cost,
            cpu: cpu,
            disk: disk,
            memory: memor,
            pub_ip: pub_ip,
            work_time: work_time
          };
        } else {
          if (list_months[month][day] == undefined) {
            list_months[month][day] = {};
            list_months[month][day][i] = {
              cost: cost,
              cpu: cpu,
              disk: disk,
              memory: memor,
              pub_ip: pub_ip,
              work_time: work_time
            };
          } else {
            list_months[month][day][i] = {
              cost: cost,
              cpu: cpu,
              disk: disk,
              memory: memor,
              pub_ip: pub_ip,
              work_time: work_time
            };
          }
        }

        if (list_months[month][day]["day_total"] == undefined) {
          list_months[month][day]["day_total"] = {
            cost: cost,
            cpu: cpu,
            disk: disk,
            memory: memor,
            pub_ip: pub_ip,
            work_time: work_time
          };
        } else {
          list_months[month][day]["day_total"]["cost"] += cost;
          list_months[month][day]["day_total"]["cpu"] += cpu;
          list_months[month][day]["day_total"]["disk"] += disk;
          list_months[month][day]["day_total"]["memory"] += memor;
          list_months[month][day]["day_total"]["pub_ip"] += pub_ip;
          list_months[month][day]["day_total"]["work_time"] += work_time;
        }

        if (list_months[month]["total"] == undefined) {
          list_months[month]["total"] = {
            cost: cost,
            cpu: cpu,
            disk: disk,
            memory: memor,
            pub_ip: pub_ip,
            work_time: work_time
          };
        } else {
          list_months[month]["total"]["cost"] += cost;
          list_months[month]["total"]["cpu"] += cpu;
          list_months[month]["total"]["disk"] += disk;
          list_months[month]["total"]["memory"] += memor;
          list_months[month]["total"]["pub_ip"] += pub_ip;
          list_months[month]["total"]["work_time"] += work_time;
        }

        if (list_months[month]["vms"] == undefined) {
          list_months[month]["vms"] = {};
          list_months[month]["vms"][i] = {
            name: lists[i].name,
            cost: cost,
            cpu: cpu,
            disk: disk,
            memory: memor,
            pub_ip: pub_ip,
            work_time: work_time
          };
        } else {
          if (list_months[month]["vms"][i] == undefined) {
            list_months[month]["vms"][i] = {
              name: lists[i].name,
              cost: cost,
              cpu: cpu,
              disk: disk,
              memory: memor,
              pub_ip: pub_ip,
              work_time: work_time
            };
          } else {
            list_months[month]["vms"][i]["cost"] += cost;
            list_months[month]["vms"][i]["cpu"] += cpu;
            list_months[month]["vms"][i]["disk"] += disk;
            list_months[month]["vms"][i]["memory"] += memor;
            list_months[month]["vms"][i]["pub_ip"] += pub_ip;
            list_months[month]["vms"][i]["work_time"] += work_time;
          }
        }
      }
      // }
    }

    //console.log(list_months);
    return list_months;
  }

  function update_table_template(month) {
    $(".test_table").hide();
    $("#test_datatable_wrapper").remove();
    $("#test_datatable").remove();
    $("#div_test_datatable").append(
      '<table id="test_datatable" class="hover"><thead><tr></tr></thead><tbody></tbody><tfoot><tr id="tr_total"></tr></tfoot></table>'
    );
    var months_days = days_month(2019, month);
    var vms = {};

    $("#test_datatable thead tr").append("<th>" + Locale.tr("DAY") + "</th>");
    for (var i in lists_month[month]["vms"]) {
      $("#test_datatable thead tr").append(
        "<th>" + lists_month[month]["vms"][i].name + "</th>"
      );
      vms[i] = lists_month[month]["vms"][i];
    }
    $("#test_datatable thead tr").append("<th>" + Locale.tr("Total") + "</th>");

    $("#test_datatable #tr_total").append(
      "<td>" + Locale.tr("Total") + "</td>"
    );
    for (var j in vms) {
      $("#test_datatable #tr_total").append(
        "<td>" + vms[j]["cost"].toFixed(2) + "</td>"
      );
    }
    $("#test_datatable #tr_total").append(
      "<td>" + lists_month[month]["total"].cost.toFixed(2) + "</td>"
    );
    return vms;
  }

  function check_data(data) {
    if (data * 1 > 0) {
      return data.toFixed(2);
    } else {
      return "-";
    }
  }

  function more_info(month, day, vms) {
    var more_tr =
      "<tr hidden><td>CPU<br>Disk<br>Memory<br>Public ip<br>Time</td>";
    for (var i in vms) {
      if (lists_month[month][day][i] != undefined) {
        more_tr +=
          "<td>" +
          check_data(lists_month[month][day][i].cpu) +
          "<br>" +
          check_data(lists_month[month][day][i].disk) +
          "<br>" +
          check_data(lists_month[month][day][i].memory) +
          "<br>" +
          check_data(lists_month[month][day][i].pub_ip) +
          "<br>" +
          check_data(lists_month[month][day][i].work_time) +
          "</td>";
      } else {
        more_tr += "<td></td>";
      }
    }
    more_tr +=
      "<td>" +
      check_data(lists_month[month][day]["day_total"].cpu) +
      "<br>" +
      check_data(lists_month[month][day]["day_total"].disk) +
      "<br>" +
      check_data(lists_month[month][day]["day_total"].memory) +
      "<br>" +
      check_data(lists_month[month][day]["day_total"].pub_ip) +
      "<br>" +
      check_data(lists_month[month][day]["day_total"].work_time) +
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

  function getShowback(month, vms) {
    var showback = [];
    for (var i in lists_month[month]) {
      if (!isNaN(i)) {
        var pole = [i];
        for (var j in vms) {
          if (lists_month[month][i][j] != undefined) {
            var sum = 0;
            for (var l in select_labels) {
              if (select_labels[l] == true && lists_month[month][i][j][l] > 0) {
                sum += lists_month[month][i][j][l];
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
            lists_month[month][i]["day_total"][l] > 0
          ) {
            sum += lists_month[month][i]["day_total"][l];
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
    //console.log(showback);
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

  function getDataset(month) {
    var total = lists_month[month].total.cost;
    var dataset = [];
    $("#test_table_graph_legend").text("");
    var kk = 0;
    for (var i in lists_month[month].vms) {
      var percent = (100 / (total / lists_month[month].vms[i].cost)).toFixed(2);
      dataset.push({ value: percent, color: Colors.names[kk] });
      $("#test_table_graph_legend").append(
        '<p><i class="fa fa-square" aria-hidden="true" style="color:' +
          Colors.names[kk] +
          '"></i>  ' +
          i +
          " - " +
          lists_month[month].vms[i].name +
          "</p>"
      );
      if (kk != 6) {
        kk++;
      } else {
        kk = 0;
      }
    }

    return dataset;
  }

  function create_diagram(dataset) {
    var maxValue = 25;
    $("#test_table_graph").text("");
    var container = $("#test_table_graph");

    var addSector = function(data, startAngle, collapse) {
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
      });
      container.append(sector);

      return startAngle + sectorDeg;
    };

    dataset.reduce(function(prev, curr) {
      return (function addPart(data, angle) {
        if (data.value <= maxValue) {
          return addSector(data, angle, false);
        }

        return addPart(
          {
            value: data.value - maxValue,
            color: data.color
          },
          addSector(
            {
              value: maxValue,
              color: data.color
            },
            angle,
            true
          )
        );
      })(curr, prev);
    }, 0);
  }

  function constrColors() {
    Colors.names = [
      "#add8e6",
      "#e0ffff",
      "#90ee90",
      "#ffb6c1",
      "#ffffe0",
      "lightsalmon",
      "lightseagreen"
    ];
  }

  return {
    html: _html,
    setup: _setup
  };
});
