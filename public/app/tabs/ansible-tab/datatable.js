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

    // OpenNebula.Ansible.list({
    //     options: {force: true}, success: function (a, result) {
    //         for (key in result) {
    //             html += '<div class="playbook">' + result[key].ANSIBLE.name + '</div>';
    //         }
    //         $('.playbooks').append(html);
    //     }
    // });

    var TabDataTable = require('utils/tab-datatable');
    var SunstoneConfig = require('sunstone-config');
    var Locale = require('utils/locale');
    var LabelsUtils = require('utils/labels/utils');

    /*
      CONSTANTS
     */

    var RESOURCE = "Ansible";
    var XML_ROOT = "ANSIBLE";
    var TAB_NAME = require('./tabId');
    var LABELS_COLUMN = 5;
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
            Locale.tr("Name"),
            Locale.tr("Description"),
            Locale.tr("Owner"),
            Locale.tr("Group"),
        ];

        this.selectOptions = {

        };

        this.totalClusters = 0;

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
        this.totalClusters++;
        return [

            '<input class="check_item" type="checkbox" id="'+RESOURCE.toLowerCase()+'_' +
            element.id + '" name="selected_items" value="' +
            element.id + '"/>',
            element.id,
            element.name,
            element.description,
            element.uname,
            element.gname,

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
        this.totalClusters = 0;
    }

    function _postUpdateView() {
        $(".total_clusters").text(this.totalClusters);
    }

});
