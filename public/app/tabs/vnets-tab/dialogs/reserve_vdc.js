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

define(function (require) {
  /*
    DEPENDENCIES
   */

	var BaseDialog = require('utils/dialogs/dialog');
	var TemplateHTML = require('hbs!./reserve_vdc/html');
	var Sunstone = require('sunstone');
	var Locale = require('utils/locale');
	var Network = require('opennebula/network');
	var Tips = require('utils/tips');
	var WizardFields = require('utils/wizard-fields');
	var Notifier = require('utils/notifier');

  /*
    CONSTANTS
   */

	var DIALOG_ID = require('./reserve_vdc/dialogId');
	var TAB_ID = require('../tabId');

  /*
    CONSTRUCTOR
   */

	function Dialog() {
		var that = this;

		this.dialogId = DIALOG_ID;

		BaseDialog.call(this);
	}

	Dialog.DIALOG_ID = DIALOG_ID;
	Dialog.prototype = Object.create(BaseDialog.prototype);
	Dialog.prototype.constructor = Dialog;
	Dialog.prototype.html = _html;
	Dialog.prototype.onShow = _onShow;
	Dialog.prototype.setup = _setup;
	Dialog.prototype.setParams = _setParams;

	return Dialog;

  /*
    FUNCTION DEFINITIONS
   */

	function _html() {
		var that = this;
		// OpenNebula.User.show({
		// 	data: {
		// 		id: config.user_id
		// 	},
		// 	success: (req, res) => {
		// 		console.log({ req, res })
		// 		res.USER.NETWORK_QUOTA.NETWORK
		// 	}
		// })


		return TemplateHTML({
			'dialogId': this.dialogId
		});
	}

	function _setup(context) {
		var that = this;

		$('#reserve_vdc_dialogForm #countAdress').mousemove(function () {
			$('#reserve_vdc_dialogForm #current').text($(this).val())
		});

		$('#reserve_vdc_dialogForm #reserve').click(function () {
			let count = $('#reserve_vdc_dialogForm #countAdress').val()
			if (!count) return
			Network.reserve_public_ip({ n: count, u: config.user_id }, (req, res) => {
				if (typeof req.response == 'number') {
					Notifier.notifyMessage(`Reserve ${count} address`)
				} else {
					Notifier.notifyError('Your number of addresses will be exceeded')
				}
			})

		})


		$('#reserve_vdc_dialogForm #release').click(function () {
			let count = $('#reserve_vdc_dialogForm #countAdress').val()
			if (!count) return
			Network.list({
				success: (req, res) => {
					for (let vnet of res) {
						if (vnet['VNET']['UID'] == config.user_id && vnet['VNET']['TEMPLATE']['TYPE'] == "PUBLIC") {
							if (Array.isArray(vnet['VNET']['AR_POOL']['AR'])) {
								if (vnet['VNET']['AR_POOL']['AR'].length - vnet['VNET']['USED_LEASES'] >= count) {
									for (let i in vnet['VNET']['AR_POOL']['AR']) {
										if (!vnet['VNET']['AR_POOL']['AR'][i]['ALLOCATED']) {
											Notifier.notifyMessage(`Release ${vnet['VNET']['NAME']}, AR ID - ${vnet['VNET']['AR_POOL']['AR'][i]['AR_ID']}`);
											Network.release_public_ip({ vn: vnet['VNET']['ID'], ar: vnet['VNET']['AR_POOL']['AR'][i]['AR_ID'] })
											count--
											if (!count) return
										}
									}
								}
							} else {
								if (Object.keys(vnet['VNET']['AR_POOL']['AR']) && vnet['VNET']['USED_LEASES'] == 0) {
									Notifier.notifyMessage(`Release ${vnet['VNET']['NAME']}, AR ID - ${vnet['VNET']['AR_POOL']['AR'][i]['AR_ID']}`);
									Network.release_public_ip({ vn: vnet['VNET']['ID'], ar: vnet['VNET']['AR_POOL']['AR'][i]['AR_ID'] })
									count--
									if (!count) return
								}
							}
						}
					}
					Notifier.notifyError(`You do not have ${count}free addresses`);
				}
			})
		})

		Tips.setup(context);
	}

	function _onShow(context) {
		this.setNames({ tabId: TAB_ID });

	}

  /**
   * [_setParams description]
   * @param {object} params
   *        - params.vnetId : Virtual Network id
   */
	function _setParams(params) {
		// this.vnetId = params.vnetId;
	}
});
