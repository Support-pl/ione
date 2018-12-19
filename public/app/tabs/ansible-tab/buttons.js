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
  var Locale = require('utils/locale');

  var Buttons = {
    "Ansible.refresh" : {
      type: "action",
      layout: "refresh",
      alwaysActive: true
    },
    "Ansible.create_dialog" : {
      type: "create_dialog",
      layout: "create"
    },
    "Ansible.update_dialog" : {
      type: "action",
      layout: "main",
      text: Locale.tr("Update")
    },
    "Ansible.run" : {
      type: "action",
      layout: "main",
      text: Locale.tr("Instantiate")
    },
    "Ansible.chown" : {
      type: "confirm_with_select",
      text: Locale.tr("Change owner"),
      layout: "user_select",
      select: "User",
      tip: Locale.tr("Select the new owner"),
    },
    "Ansible.chgrp" : {
      type: "confirm_with_select",
      text: Locale.tr("Change group"),
      layout: "user_select",
      select: "Group",
      tip: Locale.tr("Select the new group"),
    },
    "Ansible.clone_dialog" : {
      type: "action",
      layout: "main",
      text: Locale.tr("Clone")
    },
    "Ansible.delete" : {
      type: "action",
      layout: "del",
      text: Locale.tr("Delete")
    }
  };

  return Buttons;
})
