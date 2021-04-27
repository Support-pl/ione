<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      <a-row>
        <a-col :span="6">
          ID: <b>{{ id }}</b>
        </a-col>
        <a-col :span="8">
          Type: <b>{{ vlan.type }}</b>
        </a-col>
        <a-col :span="4" :offset="6">
          <a-button type="primary" icon="reload" @click="sync"></a-button>
        </a-col>
      </a-row>
      <a-divider />
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