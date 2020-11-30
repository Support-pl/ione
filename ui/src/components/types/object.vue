<template>
  <div>
    <div v-for="[key, value] of pairs()" :key="key">
      {{ key }}: <objectItem :value="value" deepness=1 :path="key"/>
    </div>
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
    pairs() {
      return Object.entries(JSON.parse(this.value.body ?? ""));
    },
  },
};
</script>
