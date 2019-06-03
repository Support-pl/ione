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

    var TabDataTable = require('utils/tab-datatable');
    var SunstoneConfig = require('sunstone-config');
    var Locale = require('utils/locale');
    var LabelsUtils = require('utils/labels/utils');
    var Humanize = require('utils/humanize');

    /*
      CONSTANTS
     */

    var RESOURCE = "AnsibleProcess";
    var XML_ROOT = "ANSIBLE_PROCESS";
    var TAB_NAME = require('./tabId');
    var LABELS_COLUMN = 6;
    var TEMPLATE_ATTR = 'TEMPLATE';

    /*
      CONSTRUCTOR
     */

    function Table(dataTableId, conf) {
        this.conf = conf || {};
        this.tabId = TAB_NAME;
        this.dataTableId = dataTableId;
        this.resource = RESOURCE;
        this.xmlRoot = XML_ROOT;
        this.labelsColumn = LABELS_COLUMN;
        this.dataTableOptions = {
            "bAutoWidth": false,
            "bSortClasses" : false,
            "bDeferRender": true,
            "aoColumnDefs": [
                {"bSortable": false, "aTargets": ["check"] },
                {"sWidth": "35px", "aTargets": [0]},
                {"bVisible": true, "aTargets": SunstoneConfig.tabTableColumns(TAB_NAME)},
                {"bVisible": false, "aTargets": ['_all']}
            ]
        };



        this.columns = [
            Locale.tr("ID"),
            Locale.tr("Playbook"),
            Locale.tr("User"),
            Locale.tr("Create time"),
            Locale.tr("Install ID"),
            Locale.tr("Status")
        ];

        this.selectOptions = {

        };

        this.totalProcesses = 0;

        TabDataTable.call(this);

    }

    Table.prototype = Object.create(TabDataTable.prototype);
    Table.prototype.constructor = Table;
    Table.prototype.elementArray = _elementArray;
    Table.prototype.preUpdateView = _preUpdateView;
    Table.prototype.postUpdateView = _postUpdateView;

    return Table;


    /*
      FUNCTION DEFINITIONS
     */

    function _elementArray(element_json) {
        var element = element_json[XML_ROOT];


        this.totalProcesses++;
        return [

            '<input class="check_item" type="checkbox" id="'+RESOURCE.toLowerCase()+'_' +
            element.proc_id + '" name="selected_items" value="' +
            element.proc_id + '"/>',
            element.proc_id,
            element.playbook_name,
            element.uname,
            Humanize.prettyTime(element.create_time),
            element.install_id,
            element.status
        ];
    }

    function _lengthOf(ids){
        var l = 0;
        if ($.isArray(ids))
            l = ids.length;
        else if (!$.isEmptyObject(ids))
            l = 1;

        return l;
    }

    function _preUpdateView() {
        this.totalProcesses = 0;
    }

    function _postUpdateView() {
        $(".total_processes").text(this.totalProcesses);
        if($('.odd').text().search('NaN:NaN:NaN NaN/NaN/NaN') != '-1'){
            $('.odd').html('<td valign="top" colspan="7" class="dataTables_empty">\n' +
                '<span class="text-center" style="font-size: 18px; color: #999">\n' +
                '  <br>\n' +
                '  <span class="fa-stack fa-3x" style="color: #dfdfdf"> \n' +
                '    <i class="fa fa-cloud fa-stack-2x"></i> \n' +
                '    <i class="fa fa-info-circle fa-stack-1x fa-inverse"></i>\n' +
                '  </span>\n' +
                '  <br>\n' +
                '  <span style=" color: #999">There is no data available</span>\n' +
                '</span>\n' +
                '<br>\n' +
                '</td>')
        }
    }

});
