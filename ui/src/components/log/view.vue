<template>
  <div class="logs-view">
    <template v-for="(line, i) in lines">
      {{ line }}
      <br :key="i" />
    </template>
  </div>
</template>

<script>
export default {
  name: "logs-view",
  props: {
    lines: {
      required: true,
      type: Array,
    },
  },
};
</script>

<style>
.logs-view {
  margin: 10px 20px;
  border-radius: 15px;
  background: #6f6f6f;
  color: #f2f2f2;
  padding: 20px;
}
</style>