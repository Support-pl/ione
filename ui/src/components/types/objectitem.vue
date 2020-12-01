<template>
	<span>
		<template v-if="typeof value == 'object'">
			<template v-if="opened">
				<div v-for="[key, val] of entries(value)" :key="key" :style="{'padding-left': `${+Boolean(+deepness)*10}px`}">
					<span class="key" @click="open(key)">
						{{key}}:
						{{typeOfBrackets(val, 0)}}
					</span>
						<objectitem :value="val" :deepness="+deepness +1" :path="path + '/' + key" :opened='openedChilds.includes(key)' :edit="edit"/>
					<span class="key" @click="open(key)">
						{{typeOfBrackets(val, 1)}}
					</span>
				</div>
			</template>
			<template v-else>
				<template v-if="preview(value) == 'val'">
					{{value}}
				</template>
				<template v-else>
					...
				</template>
			</template>
		</template>
		<template v-else>
			{{value}}
		</template>
	</span>
</template>

<script>
export default {
	name: "objectitem",
	props: [
		'value',
		'deepness',
		'path',
		'opened',
		'edit'
	],
	data(){
		return {
			openedChilds: []
		}
	},
	methods: {
		isArray(obj){
			return Array.isArray(obj);
		},
    entries(obj) {
			if(typeof obj == 'string'){
				let obj = JSON.parse(obj ?? "");
			}
      return Object.entries(obj);
    },
		isJsonString(str){
			try{
				JSON.parse(str);
			} catch (e){
				return false;
			}
			return true;
		},
		typeOfBrackets(obj, close){
			const types = {
				'object': ["{", "}"],
				'array': ['[', ']'],
				'other': ''
			}
			if(typeof obj == 'object'){
				return types[this.isArray(obj)?"array":"object"][close];
			} else {
				return types.other
			}
		},
		preview(item){
			const type = typeof item;
			if(type != 'object'){
				return 'val';
			} else {
				return 'plug';
			}
		},
		open(key){
			const indexOfKey = this.openedChilds.indexOf(key)
			if(~indexOfKey){
				this.openedChilds.splice(indexOfKey, 1);
			} else {	
				this.openedChilds.push(key);
			}
			console.log(this.path);
		}
	}
}
</script>

<style>
.key {
	cursor: pointer;
}
</style>