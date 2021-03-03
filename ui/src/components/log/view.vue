<template>
  <div class="logs-view" id="self-container" v-chat-scroll>
    <template v-for="(line, i) in lines">
      {{ line }}
      <br :key="i" />
    </template>
  </div>
</template>

<script>
import VueChatScroll from "vue-chat-scroll";
import Vue from "vue";

Vue.use(VueChatScroll);

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
  overflow: scroll;
  max-height: 640px;
}
</style>