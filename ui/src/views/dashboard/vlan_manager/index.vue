<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      {{ pool }}
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  data() {
    return {
      pool: [],
    };
  },
  mounted() {
    this.sync();
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  methods: {
    sync() {
      this.$axios({
        method: "get",
        url: "/vlan",
        auth: this.credentials,
      }).then((res) => {
        this.pool = res.data.response;
      });
    },
  },
};
</script>