<template>
  <div>
    <div style="padding-left: 15px" v-for="[key, value] of pairs()" :key="key">
      {{ key }}: {{ value }}
    </div>
  </div>
</template>

<script>
export default {
  name: "settingsOBJECT",
  props: ["value"],
  methods: {
    pairs() {
      return Object.entries(JSON.parse(this.value.body ?? ""));
    },
  },
};
</script>
