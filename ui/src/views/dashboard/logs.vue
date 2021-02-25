<template>
  <a-tabs default-active-key="rpc">
    <a-tab-pane :key="tab.key" :tab="tab.title" v-for="tab in tabs">
      <log-loader :log="tab" />
    </a-tab-pane>
  </a-tabs>
</template>

<script>
import LogLoader from "@/components/log/loader";

export default {
  components: { LogLoader },
  data() {
    return {
      tabs: [
        {
          key: "rpc",
          title: "RPC",
        },
        {
          key: "ione",
          title: "IONe",
        },
        {
          key: "debug",
          title: "Debug",
        },
        {
          key: "suspend",
          title: "Suspend",
        },
        {
          key: "snapshot",
          title: "Snapshot",
        },
      ],
    };
  },
};
</script>