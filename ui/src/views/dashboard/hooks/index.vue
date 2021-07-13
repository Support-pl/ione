<template>
  <a-tabs>
    <a-tab-pane :key="tab" :tab="tab" v-for="tab in Object.keys(hooks_pool)">
      <hooks-tab :pool="hooks_pool[tab]" />
    </a-tab-pane>
  </a-tabs>
</template>

<script>
import { mapGetters } from "vuex";

import HooksTab from "@/components/hooks/tab.vue";

export default {
  computed: {
    ...mapGetters(["credentials"]),
  },
  components: {
    HooksTab,
  },
  data() {
    return {
      hooks_pool: {},
    };
  },
  mounted() {
    this.$axios({
      method: "post",
      url: "/one.hk.pool.to_hash!",
      auth: this.credentials,
    }).then((res) => {
      let pool = res.data.response.HOOK_POOL;
      if (Array.isArray(pool.HOOK)) {
        pool = pool.HOOK;
      } else {
        pool = [pool.HOOK];
      }

      for (let hook of pool) {
        let resource =
          hook.TYPE == "api"
            ? hook.TEMPLATE.CALL.split(".")[1].toUpperCase()
            : hook.TEMPLATE.RESOURCE;
        if (!this.hooks_pool[resource])
          this.$set(this.hooks_pool, resource, { api: [], state: [] });

        this.hooks_pool[resource][hook.TYPE].push(hook);
      }
    });
  },
};
</script>