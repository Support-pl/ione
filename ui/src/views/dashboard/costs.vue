<template>
	<div class="costs__wrapper">
		<template v-if="!loading">
			<template v-for="(setting, index) in settings">
				<a-input v-if="!setting.value" v-model="settings[index].body" :key="setting.name" size="large" style="margin-bottom: 15px" @change="addChanged(setting.name)">
					<div
						slot="addonBefore"
						style="width: 100px"
					>
						{{setting.name | fieldName}}
					</div>
				</a-input>
				<template v-else>
					<a-input v-for="(v,k) in setting.value" v-model="settings[index].value[k]" :key="k" size="large" style="margin-bottom: 15px" @change="addChanged(setting.name)">
						<div
							slot="addonBefore"
							style="width: 100px"
						>
							{{k | fieldName}}
						</div>

					</a-input>
				</template>
			</template>
			<a-row type="flex" justify="end">
				<a-col >
					<a-button-group>
						<a-button type="danger" @click="cancelChanges">Cancel</a-button>
						<a-button @click="acceptChanges">Accept</a-button>
					</a-button-group>
				</a-col>
			</a-row>
		</template>
	</div>
</template>

<script>
// the position of the elements in this array determines the position of the elements on the page
const showSettings = [
	'CURRENCY_MAIN', 'PUBLIC_IP_COST', 'DISK_COSTS', 'CAPACITY_COST'
]
import { mapGetters } from "vuex";
export default {
	name: 'cost',
	data(){
		return {
			settings: {},
			cacheData: {},
			loading: true,
			showSettings,
			changed: []
		}
	},
  computed: {
		...mapGetters(["credentials"])
  },
	methods: {
    async sync() {
      this.settings = (
        await this.$axios({
          method: "get",
          url: "/settings",
          auth: this.credentials,
        })
			).data.response
				.filter( element => this.showSettings.includes(element.name))
				.sort( (a, b) => this.showSettings.indexOf(a.name) - this.showSettings.indexOf(b.name) )
				.map(item => {
					if(this.isJson(item.body)){
						item.value = JSON.parse(item.body)
					}
					return item;
				});
			this.cacheData = JSON.parse(JSON.stringify(this.settings));
			this.loading = false;
		},
		getIndexByName(name){
			return this.settings.findIndex(el => el.name == name);
		},
		isJson(str){
			try {
        JSON.parse(str);
			} catch (e) {
					return false;
			}
			return true;
		},
		cancelChanges(){
			this.changed = [];
			this.sync();	
		},
		addChanged(name){
			const ind = this.changed.indexOf(name);
			if(
				this.settings.find(el => el.name == name).body
				!==
				this.cacheData.find(el => el.name == name).body
				||
				JSON.stringify(this.settings.find(el => el.name == name).value)
				!==
				JSON.stringify(this.cacheData.find(el => el.name == name).value)
			){
				if(ind == -1){
					this.changed.push(name);
				}
			} else {
				this.changed.splice(ind, 1);
			}
		},
		acceptChanges(){
			const promises = [];
			for (const name of this.changed) {
				const field = this.settings.find(el => el.name == name);
				if(field.value){
					field.body = JSON.stringify(field.value);
					delete field.value;
				}
				promises.push(
					this.$axios({
          method: "post",
          url: `/settings/${name}`,
          auth: this.credentials,
          data: field,
        })
				)
			}
			Promise.all(promises)
				.then( respones => {
					if(respones.every(resp => resp.data.response == 1)){
						this.$message.success("Success");
					} else {
						this.$message.warn("Now all was success...");
						console.warn(respones);
					}
					this.changed = [];
					this.sync();
				})
				.catch(err => {
					console.error(err);
					this.$message.error("Error");
				})
		}
	},
	mounted(){
		this.sync();
	},
	filters: {
		fieldName(value) {
			if (!value) return ''
			value = value.toString()
			return value.charAt(0).toUpperCase() + value.slice(1).toLowerCase().replace(/_/g, ' ');
		}
	}
}
</script>

<style>
.costs__wrapper{
	padding: 10px 20px;
}
</style>