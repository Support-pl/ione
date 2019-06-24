define(function(require) {
    /*
      This module insert a row with the name of the resource.
      The row can be edited and a rename action will be sent
     */
  
    var TemplatePermissionsTable = require('hbs!utils/panel/permissions-table/html');
    var TemplatePermissions = require('hbs!utils/panel/permissions-table/permissions');
    var TemplateOwner = require('hbs!utils/panel/permissions-table/owner');
    var TemplateGroup = require('hbs!utils/panel/permissions-table/group');
    var ResourceSelect = require('utils/resource-select');
    var Sunstone = require('sunstone');
    var Config = require('sunstone-config');
  
    /*
      Generate the tr HTML with the name of the resource and an edit icon
      @param {String} tabName
      @param {String} resourceType Resource type (i.e: Zone, Host, Image...)
      @param {Object} element OpenNebula object (i.e: element.ID, element.GNAME)
      @returns {String} HTML row
     */
    var _html = function(tabName, resourceType, element) {
      var permissionsHTML = '';
      if (Config.isTabActionEnabled(tabName, resourceType + '.chmod')) {
        permissionsHTML = TemplatePermissions({'element': element})
      }
  
      var ownerHTML = TemplateOwner({
        'tabName': tabName,
        'action': resourceType + '.chown',
        'element': element
      });
  
      var groupHTML = TemplateGroup({
        'tabName': tabName,
        'action': resourceType + '.chgrp',
        'element': element
      })
  
      var permissionsTableHTML = TemplatePermissionsTable({
        'resourceType': resourceType.toLowerCase(),
        'permissionsHTML': permissionsHTML,
        'ownerHTML': ownerHTML,
        'groupHTML': groupHTML
      })
  
      return permissionsTableHTML;
    };
  
    /*
      Initialize the row, clicking the edit icon will add an input to edit the name
      @param {String} tabName
      @param {String} resourceType Resource type (i.e: Zone, Host, Image...)
      @param {Object} element OpenNebula object (i.e: element.ID, element.GNAME)
      @param {jQuery Object} context Selector including the tr
     */
    var _setup = function(tabName, resourceType, element, context) {
      var resourceId = element.ID
      if (Config.isTabActionEnabled(tabName, resourceType + '.chmod')) {
        _setPermissionsTable(element, context);
  
        context.off('change', ".permission_check");
        context.on('change', ".permission_check", function() {
          var permissionsOctet = {octet : _buildOctet(context)};
          console.log(resourceType + ".chmod", resourceId, permissionsOctet)
          Sunstone.runAction(resourceType + ".chmod", resourceId, permissionsOctet);
        });
      }
  
      if (Config.isTabActionEnabled(tabName, resourceType + '.chown')) {
        context.off("click", "#div_edit_chg_owner_link");
        context.on("click", "#div_edit_chg_owner_link", function() {
            ResourceSelect.insert({
                context: $('#value_td_owner', context),
                resourceName: 'User',
                initValue: element.UID
              });
            console.log(element);
          });
  
        context.off("change", "#value_td_owner .resource_list_select");
        context.on("change", "#value_td_owner .resource_list_select", function() {
            var newOwnerId = $(this).val();
            if (newOwnerId != "") {
              Sunstone.runAction(resourceType + ".chown", [resourceId], newOwnerId);
            }
          });
      }
  
      if (Config.isTabActionEnabled(tabName, resourceType + '.chgrp')) {
        context.off("click", "#div_edit_chg_group_link");
        context.on("click", "#div_edit_chg_group_link", function() {
            ResourceSelect.insert({
                context: $('#value_td_group', context),
                resourceName: 'Group',
                initValue: element.GID
              });
            console.log(element);
          });
  
        context.off("change", "#value_td_group .resource_list_select");
        context.on("change", "#value_td_group .resource_list_select", function() {
            var newGroupId = $(this).val();
            if (newGroupId != "") {
              Sunstone.runAction(resourceType + ".chgrp", [resourceId], newGroupId);
            }
          });
      }
  
      return false;
    }
  
    //Returns an octet given a permission table with checkboxes
    var _buildOctet = function(context) {
        var owner = '';
        var group = '';
        var other = '';
    
        owner += $('.owner_u', context).is(':checked') ? '1' : '0'
        owner += $('.owner_m', context).is(':checked') ? '1' : '0'
        owner += $('.owner_a', context).is(':checked') ? '1' : '0'
    
        group += $('.group_u', context).is(':checked') ? '1' : '0'
        group += $('.group_m', context).is(':checked') ? '1' : '0'
        group += $('.group_a', context).is(':checked') ? '1' : '0'
    
        other += $('.other_u', context).is(':checked') ? '1' : '0'
        other += $('.other_m', context).is(':checked') ? '1' : '0'
        other += $('.other_a', context).is(':checked') ? '1' : '0'
    
        return "" + owner + group + other;
    };
  
    var _ownerUse = function(element) {
      return parseInt(element.PERMISSIONS.OWNER_U);
    };
    var _ownerManage = function(element) {
      return parseInt(element.PERMISSIONS.OWNER_M);
    };
    var _ownerAdmin = function(element) {
      return parseInt(element.PERMISSIONS.OWNER_A);
    };
  
    var _groupUse = function(element) {
      return parseInt(element.PERMISSIONS.GROUP_U);
    };
    var _groupManage = function(element) {
      return parseInt(element.PERMISSIONS.GROUP_M);
    };
    var _groupAdmin = function(element) {
      return parseInt(element.PERMISSIONS.GROUP_A);
    };
  
    var _otherUse = function(element) {
      return parseInt(element.PERMISSIONS.OTHER_U);
    };
    var _otherManage = function(element) {
      return parseInt(element.PERMISSIONS.OTHER_M);
    };
    var _otherAdmin = function(element) {
      return parseInt(element.PERMISSIONS.OTHER_A);
    };
  
    var _ownerPermStr = function(element) {
      var result = "";
      result += _ownerUse(element) ? "u" : "-";
      result += _ownerManage(element) ? "m" : "-";
      result += _ownerAdmin(element) ? "a" : "-";
      return result;
    };
  
    var _groupPermStr = function(element) {
      var result = "";
      result += _groupUse(element) ? "u" : "-";
      result += _groupManage(element) ? "m" : "-";
      result += _groupAdmin(element) ? "a" : "-";
      return result;
    };
  
    var _otherPermStr = function(element) {
      var result = "";
      result += _otherUse(element) ? "u" : "-";
      result += _otherManage(element) ? "m" : "-";
      result += _otherAdmin(element) ? "a" : "-";
      return result;
    };
  
    var _setPermissionsTable = function(element, context) {
      if (_ownerUse(element))
          $('.owner_u', context).attr('checked', 'checked');
      if (_ownerManage(element))
          $('.owner_m', context).attr('checked', 'checked');
      if (_ownerAdmin(element))
          $('.owner_a', context).attr('checked', 'checked');
      if (_groupUse(element))
          $('.group_u', context).attr('checked', 'checked');
      if (_groupManage(element))
          $('.group_m', context).attr('checked', 'checked');
      if (_groupAdmin(element))
          $('.group_a', context).attr('checked', 'checked');
      if (_otherUse(element))
          $('.other_u', context).attr('checked', 'checked');
      if (_otherManage(element))
          $('.other_m', context).attr('checked', 'checked');
      if (_otherAdmin(element))
          $('.other_a', context).attr('checked', 'checked');
    };
    
    return {
      'html': _html,
      'setup': _setup
    }
  });
  