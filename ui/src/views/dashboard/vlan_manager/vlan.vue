<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      {{ vlan }}
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  data() {
    return {
      id: undefined,
      vlan: {},
    };
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  mounted() {
    console.log(this.$route);
    if (this.$route.query.id) {
      this.id = this.$route.query.id;
      this.sync();
    } else {
      this.$router.go(-1);
    }
  },
  methods: {
    sync() {
      this.$axios({
        method: "get",
        url: `/vlan/${this.id}`,
        auth: this.credentials,
      }).then((res) => {
        this.vlan = res.data;
      });
    },
  },
};
</script>