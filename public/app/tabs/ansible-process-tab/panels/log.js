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

    var TemplateHTML = require("hbs!./log/html");
    var Locale = require("utils/locale");

    /*
      CONSTANTS
     */

    var TAB_ID = require('../tabId');
    var PANEL_ID = require('./log/panelId');
    var RESOURCE = "AnsibleProcess"
    var XML_ROOT = "ANSIBLE_PROCESS";


    /*
      CONSTRUCTOR
     */

    function Panel(info) {
        var that = this;

        this.title = Locale.tr("Log");
        this.icon = "fa-file-o";

        this.element = info[XML_ROOT];

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
            'element': this.element,
            'templateString': this.element.log
        });
    }

    function _setup(context) {
    }
});
