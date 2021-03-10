<template>
  <div>
    <div class="logs-loader-container" v-if="!synced">
      <a-button type="primary" @click="load"
        >Load {{ log.title }} Logs</a-button
      >
    </div>
    <log-view :lines="lines" v-else />
  </div>
</template>

<script>
import { mapGetters } from "vuex";
import LogView from "./view";

export default {
  name: "log-loader",
  components: {
    LogView,
  },
  props: {
    log: {
      required: true,
      type: Object,
    },
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  data() {
    return {
      synced: false,
      lines: [],
    };
  },
  methods: {
    load() {
      let vm = this;
      let ws = new WebSocket(
        `${process.env.VUE_APP_IONE_API_BASE_URL.replace(
          "https",
          "wss"
        )}/wss/ione/log/${this.log.key}?ws=true&auth=${btoa(
          this.credentials.username + ":" + this.credentials.password
        )}`
      );
      ws.onopen = function () {
        vm.synced = true;
      };
      ws.onmessage = function (m) {
        vm.lines.push(m.data);
      };
    },
  },
};
</script>

<style>
.logs-loader-container {
  text-align: center;
  margin-top: 10%;
}
</style>