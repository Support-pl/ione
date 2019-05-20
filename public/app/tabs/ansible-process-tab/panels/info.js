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

    var TemplateHTML = require("hbs!./info/html");
    var Locale = require("utils/locale");
    var RenameTr = require("utils/panel/rename-tr");
    var TemplateTable = require("utils/panel/template-table");
    var Sunstone = require("sunstone");
    var TemplateUtils = require("utils/template-utils");
    var Humanize = require('utils/humanize');
    var OpenNebula = require('opennebula');
    var Config = require('sunstone-config');
    var Navigation = require('utils/navigation');
    var VMTable = require('tabs/vms-tab/datatable');

    /*
      CONSTANTS
     */

    var TAB_ID = require("../tabId");
    var PANEL_ID = require("./info/panelId");
    var RESOURCE = "AnsibleProcess";
    var XML_ROOT = "ANSIBLE_PROCESS";

    var OVERCOMMIT_DIALOG_ID = require("utils/dialogs/overcommit/dialogId");

    /*
      CONSTRUCTOR
     */

    function Panel(info) {
        var that = this;

        this.title = Locale.tr("Info");
        this.icon = "fa-info-circle";

        this.element = info[XML_ROOT];
        this.percent = false;

        //this.element.id = this.element.proc_id;


        this.element.create_time = Humanize.prettyTime(this.element.create_time);
        this.element.start_time = this.element.start_time == -1 ? ' — ' : Humanize.prettyTime(this.element.start_time);
        this.element.end_time = this.element.end_time == -1 ? ' — ' : Humanize.prettyTime(this.element.end_time);

        // Hide information in the template table. Unshow values are stored
        // in the unshownTemplate object to be used when the element info is updated.
        that.unshownTemplate = {};
        that.strippedTemplate = {};
        var unshownKeys = [
            // "id", "uid", "uname", "UNAME", "gname",
            // "GNAME", "gid", "body", "description", "name",
            // "ID", "UID", "GID","PERMISSIONS"
        ];
        $.each(that.element, function(key, value) {
            if ($.inArray(key, unshownKeys) > -1) {
                that.unshownTemplate[key] = value;
            } else {
                that.strippedTemplate[key] = value;
            }
        });


        return this;
    }

    Panel.PANEL_ID = PANEL_ID;
    Panel.prototype.html = _html;
    Panel.prototype.setup = _setup;

    return Panel;

    /*
      FUNCTION DEFINITIONS
     */

    function _html() {

        return TemplateHTML({
            "element": this.element
        });
    }


    function _setup(context) {
        var that = this;

        OpenNebula.VM.list({
            success: function(r, res){
                res.forEach(
                    function(host){
                        if(Object.keys(that.element.hosts).includes(host.VM.ID.toString())){
                            var id = host.VM.ID;
                            var ip = that.element.hosts[host.VM.ID][0];
                            var codes = that.element.codes[that.element.hosts[host.VM.ID][0].split(':')[0]];
                            if (codes == undefined){
                                $('#tab-process-hosts').append(
                                    '<tr class="useless-string">' +
                                    '<td class="key_td">' + id + '</td>' +
                                    '<td>' + ip + '</td></tr>'
                                );
                            }else{
                                $('#tab-process-hosts').append(
                                    '<tr class="useless-string">' +
                                    '<td class="key_td">' + id + '</td>' +
                                    '<td>' + ip + '</td>' +
                                    '<td>' + 'ok=' + codes.ok + ' changed=' + codes.changed + ' unreachable=' + codes.unreachable + ' failed=' + codes.failed + '</td>' +
                                    '</tr>'
                                );
                            }
                        }
                    }
                )
            },
            error: function(r, res){ console.log('Error getting hosts, error:', res) }
        });

        RenameTr.setup(TAB_ID, RESOURCE, this.element.id, context);

        TemplateTable.setup(this.strippedTemplate, RESOURCE, this.element.id, context, this.unshownTemplate);

    }
});
