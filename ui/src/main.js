import Vue from "vue";
import App from "@/App.vue";
import store from "@/store";
import router from "@/router";
import axios from "axios";

let config = requrie("@/config");

Vue.prototype.$axios = axios.create({
  baseURL: `${config.CLOUD_API_BASE_URL}`,
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
