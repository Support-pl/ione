<template>
  <div>
		<objectItem
			:value="parse(value.body)"
			deepness=0
			:path="''"
			:opened="true"
			:addKey="addKey"
			:removeKey="removeKey"
			:changeActionPath="changeActionPath"
			:creatingPath="creatingPath"
			:status="{edit, action}"
		/>
		<div v-if="edit">
			<a-button icon="plus" shape="round" type="primary" size="small" @click="changeActionPath('', 'create')" style="margin-top: 5px"></a-button>
		</div>
  </div>
</template>

<script>
import objectItem from "./objectitem";
export default {
	name: "settingsOBJECT",
	data(){
		return {
			creatingPath: null,
			action: 'idle'
		}
	},
	components: {
		objectItem,
	},
  props: ["value", 'edit'],
  methods: {
		parse(JsonString){
			return JSON.parse(JsonString);
		},
		changeActionPath(path, action){
			this.creatingPath = path;
			this.action = action;
		},
		addKey(path, key, value){
			console.log(path, key, value);
			this.changeActionPath(null, "idle")
		},
		removeKey(path){
			let arr = path.split('/');
			arr = arr.filter( el => el.length>0);
			let object = this.parse(this.value.body);
			arr.forEach(name => {
				object = object[name]
				console.log(object);
			});
			object = undefined
		}
  },
};
</script>
