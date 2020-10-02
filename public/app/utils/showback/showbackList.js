define(function (require) {
	var rootList = createLayoutFromData();
	// Высчитывает количество дней в месяце
	function days_month(year, month) {
		return 32 - new Date(year, month - 1, 32).getDate();
	}

	function createLayoutFromData() {
		var list = {};
		var nowYear = new Date().getFullYear()
		for (let year = 2019; year <= nowYear; year++) {
			list[year] = {}
			for (let month = 1; month <= 12; month++) {
				list[year][month] = {
					MonthTotal: {
						cost: 0,
						cpu: 0,
						disk: 0,
						memory: 0,
						work_time: 0,
						pub_ip: 0
					},
					VMsMonthTotal: {}
				}
				let allDays = days_month(year, month)
				for (let day = 1; day <= allDays; day++) {
					list[year][month][day] = {
						DayTotal: {
							cost: 0,
							cpu: 0,
							disk: 0,
							memory: 0,
							work_time: 0,
							pub_ip: 0
						}
					}
				}
			}
		}
		return list
	}

	function objectSum(a, b) {
		var c = {};
		for (let i in a) {
			a[i] += b[i]
		}
	}

	function setShowbackVM(VmId, VmShowbackData) {
		var dateSplit = VmShowbackData.date.split("/");
		var day = dateSplit[0];
		var month = dateSplit[1];
		var year = dateSplit[2];

		rootList[year][month][day][VmId] = {
			cost: VmShowbackData.TOTAL,
			cpu: VmShowbackData.CPU == undefined ? 0 : VmShowbackData.CPU,
			disk: VmShowbackData.DISK == undefined ? 0 : VmShowbackData.DISK,
			memory: VmShowbackData.MEMORY == undefined ? 0 : VmShowbackData.MEMORY,
			work_time: VmShowbackData.work_time == undefined ? 0 : VmShowbackData.work_time,
			pub_ip: 0
		}
		if (rootList[year][month]['VMsMonthTotal'][VmId]) {
			objectSum(rootList[year][month]['VMsMonthTotal'][VmId], rootList[year][month][day][VmId])
		} else {
			rootList[year][month]['VMsMonthTotal'][VmId] = rootList[year][month][day][VmId]
		}
		objectSum(rootList[year][month]['MonthTotal'], rootList[year][month][day][VmId])
		objectSum(rootList[year][month][day]['DayTotal'], rootList[year][month][day][VmId])
	}


	var showbackList = {
		// <------ Обработка данных шоубека из запроса -----> //
		'create_list_months': function (lists) {
			console.log(lists);
			for (var i in lists) {
				// Уберает пустые поля -----> if (lists[i].TOTAL > 0){
				for (var j in lists[i].showback) {
					setShowbackVM(lists[i].id, lists[i].showback[j])
				}
				// }
			}
			console.log("LIST ROOT ----->", rootList);
			return rootList;
		},
		list: rootList
	};

	return showbackList;
});