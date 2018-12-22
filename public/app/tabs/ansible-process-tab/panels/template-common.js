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

    var Locale = require('utils/locale');
    var TemplateUtils = require('utils/template-utils');

    /*
      TEMPLATES
     */

    var TemplateInfo = require('hbs!./body/html');

    /*
      CONSTANTS
     */

    var PANEL_ID = require('./body/panelId');
    var XML_ROOT = "ANSIBLEPROCESS"

    /*
      CONSTRUCTOR
     */

    function Panel(info) {
        this.title = Locale.tr("BODY");
        this.icon = "fa-file-o";

        this.element = info[XML_ROOT];

        return this;
    };

    Panel.prototype.html = _html;
    Panel.prototype.setup = _setup;

    return Panel;

    /*
      FUNCTION DEFINITIONS
     */

    function _html() {
        return TemplateInfo({
            'element': this.element,
            'templateString': TemplateUtils.templateToString(this.element.body)
        });
    }

    function _setup(context) {
    }
});
