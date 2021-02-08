import Vue from "vue";
import Vuex from "vuex";

import axios from "axios";

let config = require("@/config");

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    user: {
      loggedIn: false,
    },
    credentials: "",
    user_pool: [],
    group_pool: [],
  },
  mutations: {
    login(state, user) {
      state.user = user;
    },
    credentials(state, cred) {
      state.credentials = cred;
    },
    pool(state, [type, data]) {
      state[type + "_pool"] = data;
    },
  },
  getters: {
    credentials: (state) => state.credentials,
    users: (state) => state.user_pool,
    groups: (state) => state.group_pool,
  },
  actions: {
    async sync_user_pool({ state, commit }) {
      let pool = (
        await axios({
          method: "post",
          url: config.CLOUD_API_BASE_URL + "/one.u.pool.to_hash!",
          auth: state.credentials,
          data: {},
        })
      ).data;
      if (pool.response) {
        commit("pool", [
          "user",
          pool.response.USER_POOL.USER.map((el) => {
            return { id: el.ID, name: el.NAME };
          }),
        ]);
      }
    },
    async sync_group_pool({ state, commit }) {
      let pool = (
        await axios({
          method: "post",
          url: config.CLOUD_API_BASE_URL + "/one.g.pool.to_hash!",
          auth: state.credentials,
          data: {},
        })
      ).data;
      if (pool.response) {
        commit("pool", [
          "group",
          pool.response.GROUP_POOL.GROUP.map((el) => {
            return { id: el.ID, name: el.NAME };
          }),
        ]);
      }
    },
  },
  modules: {},
});
