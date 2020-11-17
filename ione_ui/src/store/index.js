import Vue from "vue";
import Vuex from "vuex";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    user: {
      loggedIn: false,
    },
  },
  mutations: {
    login(state, user) {
      state.loggedIn = user;
    },
  },
  actions: {},
  modules: {},
});
