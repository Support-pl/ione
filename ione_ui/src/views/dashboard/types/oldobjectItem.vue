<template>
	<div v-if="opened" style="padding-left: 15px">
		<template v-if="typeof value == 'object'">
			<div v-for="(branch, key) in value" :key="key">
				<span @click='open(key)'>{{openedChilds[key]?"-":"+"}}{{key}}:</span>
				<objectItem :value="branch" :step='step+1' :path='`/${key}`' :opened="openedChilds[key] || false"/>
			</div>
		</template>
		<template v-else>
			<span>
				{{value}}
			</span>
		</template>
	</div>
</template>

<script>
export default {
	name: "objectItem",
	props: {
		value: {
			default: []
		},
		step: {
			default: 1
		},
		path: {
			default: ''
		},
		opened: {
			default: false
		}
	},
	data() {
		return{
			openedChilds: []
		}
	},
	methods: {
		parse(str){
			return JSON.parse(str);
		},
		isObject(variable){
			return (typeof variable === "object" || typeof variable === 'function') && (variable !== null)
		},
		open(key){
			if(this.openedChilds[key]){
				this.openedChilds[key] = false
			} else 
				this.openedChilds[key] = true
		}
	}
}
</script>

<style>

</style>