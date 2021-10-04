<template>
  <a-row type="flex" justify="space-around" style="margin: 8% 0">
    <a-col :span="12">
      <a-row type="flex" justify="space-around">
        <img src="/ione_logo.png" style="max-height: 8rem; max-width: 16rem" />
      </a-row>
      <a-row type="flex" justify="space-around" class="login-grid-item">
        <h1><b>Welcome to IONe UI</b></h1>
      </a-row>
      <a-row type="flex" justify="space-around" class="login-grid-item">
        <a-col :span="12">
          <a-input placeholder="Username" v-model="auth.username"></a-input>
        </a-col>
      </a-row>
      <a-row type="flex" justify="space-around" class="login-grid-item">
        <a-col :span="12">
          <a-input-password
            placeholder="Password or token"
            v-model="auth.password"
          ></a-input-password>
        </a-col>
      </a-row>
      <a-row
        type="flex"
        justify="space-around"
        class="login-grid-item"
        v-if="fails > 0"
      >
        <span class="endpoint-message"
          >Endpoint used for login: <b>{{ endpoint }}</b></span
        >
      </a-row>
      <a-row type="flex" justify="space-around" class="login-grid-item">
        <a-button type="primary" @click="performLogin">Log in</a-button>
      </a-row>
    </a-col>
  </a-row>
</template>

<script>
export default {
  data() {
    return {
      auth: {
        username: "oneadmin",
        password: "",
      },
      fails: 0,
      endpoint: VUE_APP_IONE_API_BASE_URL,
    };
  },
  methods: {
    performLogin() {
      this.$axios({
        method: "post",
        url: "one.u.to_hash!",
        data: { oid: -1 },
        auth: this.auth,
      })
        .then(async (res) => {
          let is_admin = (
            await this.$axios({
              method: "post",
              url: "one.u.is_admin",
              data: {
                oid: -1,
              },
              auth: this.auth,
            })
          ).data.response;
          if (is_admin) {
            this.$store.commit("login", {
              ...res.data.response.USER,
              loggedIn: true,
            });
            this.$store.commit("credentials", this.auth);
            this.$router.push("/dashboard/settings");
          } else {
            this.$message.error(`User "${this.auth.username}" is not admin`);
          }
        })
        .catch(() => {
          this.fails++;
          this.$notification.error({
            message: "Login Failed",
            description: "Check your credentials and endpoint",
          });
        });
    },
  },
};
</script>

<style scoped>
.login-grid-item + .login-grid-item {
  margin-top: 15px;
}

.endpoint-message {
  background: rgb(225, 133, 133);
  border: 1px solid red;
  border-radius: 10px;
  padding: 2px 5px;
}
</style>
