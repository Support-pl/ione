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
    var PermissionsTable = require('./permissions-table');
    var Sunstone = require("sunstone");
    var TemplateUtils = require("utils/template-utils");
    var Humanize = require('utils/humanize');
    var OpenNebula = require('opennebula');
    var Config = require('sunstone-config');
    var Navigation = require('utils/navigation');

    /*
      CONSTANTS
     */

    var TAB_ID = require("../tabId");
    var PANEL_ID = require("./info/panelId");
    var RESOURCE = "Ansible";
    var XML_ROOT = "ANSIBLE";

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
        var permissionsall = this.element.extra_data.PERMISSIONS;
        var permissions = {
            OWNER_U: permissionsall.charAt(0),
            OWNER_M: permissionsall.charAt(1),
            OWNER_A: permissionsall.charAt(2),
            GROUP_U: permissionsall.charAt(3),
            GROUP_M: permissionsall.charAt(4),
            GROUP_A: permissionsall.charAt(5),
            OTHER_U: permissionsall.charAt(6),
            OTHER_M: permissionsall.charAt(7),
            OTHER_A: permissionsall.charAt(8),

        };

        this.element.ID = this.element.id;
        this.element.UID = this.element.uid;
        this.element.UNAME = this.element.uname;
        this.element.GID = this.element.gid;
        this.element.GNAME = this.element.gname;
        this.element.PERMISSIONS = permissions;
        this.element.create_time = Humanize.prettyTime(this.element.create_time);

        // Hide information in the template table. Unshow values are stored
        // in the unshownTemplate object to be used when the element info is updated.
        that.unshownTemplate = {};
        that.strippedTemplate = {};
        var unshownKeys = [
            "id", "uid", "uname", "UNAME", "gname",
            "GNAME", "gid", "body", "description", "name",
            "ID", "UID", "GID","PERMISSIONS"
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
        var renameTrHTML = RenameTr.html(TAB_ID, RESOURCE, this.element.name);
        var permissionsTableHTML = PermissionsTable.html(TAB_ID, RESOURCE, this.element);
        var blocksupportedos = '';

        if(this.element.extra_data.SUPPORTED_OS != null) {
            var supported_os = this.element.extra_data.SUPPORTED_OS.split(',');
            for (var i = 0; i < supported_os.length; i++){
                r_col = "#" + ((1 << 24) * Math.random() | 0).toString(16);
                if(r_col.length == 6){
                    r_col += '0';
                }
                blocksupportedos += '<div class="" style="margin-left: 10px; padding: 0px 10px 0px 10px; float: left; text-align: center; border: 2px solid '+ r_col +';\n' +
                    '    border-radius: 100px !important; margin-bottom: 5px;">' + supported_os[i] + '</div>';
            }
        }else{
            r_col = "#" + ((1 << 24) * Math.random() | 0).toString(16);
            if(r_col.length == 6){
                r_col += '0';
            }
            blocksupportedos += '<div class="" style="margin-left: 10px; float: left; padding: 0px 10px 0px 10px; border: 2px solid; text-align: center;'+ r_col +';\n' +
                '    border-radius: 100px !important;margin-bottom: 5px;">404 (NOT FOUND)</div>';
        }
        blocksupportedos += '<div class"large-2 columns"></div>';

        var templateTableHTML = TemplateTable.html(
            this.strippedTemplate,
            RESOURCE,
            Locale.tr("Attributes"));


        return TemplateHTML({
            "element": this.element,
            "renameTrHTML": renameTrHTML,
            "permissionsTableHTML": permissionsTableHTML,
            "templateTableHTML": blocksupportedos
        });
    }




    function _setup(context) {
        var that = this;

        PermissionsTable.setup(TAB_ID, RESOURCE, this.element, context);
        RenameTr.setup(TAB_ID, RESOURCE, this.element.id, context);

        TemplateTable.setup(this.strippedTemplate, RESOURCE, this.element.id, context, this.unshownTemplate);

    }
});
