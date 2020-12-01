<template>
  <div>
		<objectItem :value="parse(value.body)" deepness=0 :path="''" :opened="true"/>
  </div>
</template>

<script>
import objectItem from "./objectitem";
export default {
	name: "settingsOBJECT",
	components: {
		objectItem,
	},
  props: ["value"],
  methods: {
		parse(JsonString){
			return JSON.parse(JsonString);
		},
  },
};
</script>
