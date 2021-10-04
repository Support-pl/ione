import Vue from "vue";
import App from "@/App.vue";
import store from "@/store";
import router from "@/router";
import axios from "axios";

console.log(`Using '${VUE_APP_IONE_API_BASE_URL}' as base URL`);
Vue.prototype.$axios = axios.create({
  baseURL: `${VUE_APP_IONE_API_BASE_URL}`,
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
