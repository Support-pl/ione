<template>
  <div style="padding-left: 15px">
    {{ getKey(value) }}: {{ value[getKey(value)] }}
  </div>
</template>

<script>
export default {
  name: "objectItem",
  props: ["value"],
  methods: {
    getKey(from) {
      return Object.keys(from)[0];
    },
  },
};
</script>

<style>
</style>