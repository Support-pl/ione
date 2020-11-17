import Vue from "vue";
import App from "@/App.vue";
import store from "@/store";
import router from "@/router";
import axios from "axios";

Vue.prototype.$axios = axios.create({
  baseURL: "http://185.66.69.108:8009",
});

Vue.config.productionTip = false;

import Antd from "ant-design-vue";
Vue.use(Antd);
import "ant-design-vue/dist/antd.css";

new Vue({
  store,
  router,
  render: (h) => h(App),
}).$mount("#app");
