/* -------------------------------------------------------------------------- */
/* Copyright 2018, IONe Cloud Project, Support.by                             */
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
    var OpenNebulaAction = require('./action');
    var Config = require('sunstone-config');
    var Notifier = require('utils/notifier');
    var RESOURCE = "SETTINGS";

    var Settings = {
        "resource": RESOURCE,
        "showback": function (params) {
            var callback = params.success;
            var data = JSON.stringify(params);

            $.ajax({
                url: '/ione_showback',
                type: 'POST',
                data: data,
                success: function (req, res) {
                    return callback ? callback(req, res) : null;
                },
                error: function (req, res) { Notifier.notifyError(req) }
            });
        },
        'showbackV2': function (params) {
            var callback = params.success;
            var data = JSON.stringify(params);

            $.ajax({
                url: '/ione_showback/v2',
                type: 'POST',
                data: data,
                success: function (req, res) {
                    return callback ? callback(req, res) : null;
                },
                error: function (req, res) { console.log('ERROR showbackV2->', req, res); Notifier.notifyError(req) }
            });
        },
        "cloud": function (params) {
            var callback = params.success;

            $.ajax({
                url: 'settings',
                type: 'GET',
                success: function (req, res) {
                    return callback ? callback(req, res) : null;
                },
                error: function (req, res) { Notifier.notifyError(req) }
            });
        }
    }

    return Settings;
})