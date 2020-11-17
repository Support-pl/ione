<template>
  <a-row type="flex" justify="space-around" style="margin: 10% 0">
    <a-col :span="12">
      <a-row type="flex" justify="space-around" class="login-grid-item">
        <h1><b>Welcome to IONe UI</b></h1>
      </a-row>
      <a-row type="flex" justify="space-around" class="login-grid-item">
        <a-col :span="12">
          <a-input placeholder="Username" v-model="username"></a-input>
        </a-col>
      </a-row>
      <a-row type="flex" justify="space-around" class="login-grid-item">
        <a-col :span="12">
          <a-input-password
            placeholder="Password or token"
            v-model="password"
          ></a-input-password>
        </a-col>
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
      username: "oneadmin",
      password: "",
    };
  },
  methods: {
    performLogin() {
      console.log(this.username, this.password);
    },
  },
};
</script>

<style scoped>
.login-grid-item + .login-grid-item {
  margin-top: 15px;
}
</style>