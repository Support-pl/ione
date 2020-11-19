import Vue from "vue";
import Vuex from "vuex";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    user: {
      loggedIn: false,
    },
    credentials: "",
  },
  mutations: {
    login(state, user) {
      state.user = user;
    },
    credentials(state, cred) {
      state.credentials = cred;
    },
  },
  getters: {
    credentials: (state) => state.credentials,
  },
  actions: {},
  modules: {},
});
