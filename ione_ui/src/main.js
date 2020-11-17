import Vue from "vue";
import App from "@/App.vue";
import store from "@/store";
import router from "@/router";

Vue.config.productionTip = false;

import Antd from "ant-design-vue";
Vue.use(Antd);
import "ant-design-vue/dist/antd.css";

new Vue({
  store,
  router,
  render: (h) => h(App),
}).$mount("#app");
