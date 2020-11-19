<template>
  <div class="openable">
    <template v-if="!opened">
      <a-icon type="caret-down" @click="open()" />
      {{ value.body }}
    </template>
    <template v-else>
      <a-icon type="caret-up" @click="close()" />
      <item
        v-for="(element, key) in parse(value.body)"
        :key="key"
        :value="{ [key]: element }"
      />
    </template>
  </div>
</template>

<script>
import item from "./objectItem.vue";
export default {
  name: "settingsOBJECT",
  data() {
    return {
      opened: false,
    };
  },
  components: {
    item,
  },
  props: ["value"],
  methods: {
    parse(str) {
      return JSON.parse(str);
    },
    open() {
      this.opened = true;
    },
    close() {
      this.opened = false;
    },
  },
};
</script>

<style>
</style>