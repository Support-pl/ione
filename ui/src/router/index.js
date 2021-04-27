import Vue from "vue";
import VueRouter from "vue-router";
import HelloWorld from "@/views/HelloWorld.vue";

import store from "@/store";

Vue.use(VueRouter);

const routes = [
  {
    path: "/",
    name: "Hello World",
    component: HelloWorld,
    meta: {
      guest: true,
    },
  },
  {
    path: "/login",
    name: "Login",
    component: () => import("@/views/Login.vue"),
    meta: {
      guest: true,
    },
  },
  {
    path: "/dashboard",
    name: "Dashboard",
    component: () => import("@/views/dashboard.vue"),
    children: [
      {
        path: "settings",
        component: () => import("@/views/dashboard/settings.vue"),
      },
      {
        path: "datastores",
        component: () => import("@/views/dashboard/datastores.vue"),
      },
      {
        path: "costs",
        component: () => import("@/views/dashboard/costs.vue"),
      },
      {
        path: "hosts",
        component: () => import("@/views/dashboard/hosts.vue"),
      },
      {
        path: "playbooks",
        component: () => import("@/views/dashboard/playbooks.vue"),
      },
      {
        path: "processes",
        component: () => import("@/views/dashboard/processes/index.vue"),
      },
      {
        path: "processes/:id",
        component: () => import("@/views/dashboard/processes/process.vue"),
      },
      {
        path: "vlan-manager",
        component: () => import("@/views/dashboard/vlan_manager/index.vue"),
      },
      {
        path: "hooks",
        component: () => import("@/views/dashboard/hooks/index.vue"),
      },
      {
        path: "hooks/:id",
        component: () => import("@/views/dashboard/hooks/hook.vue"),
      },
      {
        path: "logs",
        component: () => import("@/views/dashboard/logs.vue"),
      },
    ],
  },
];

const router = new VueRouter({
  routes,
});

router.beforeEach((to, from, next) => {
  if (to.matched.some((record) => record.meta.guest)) {
    next();
  } else if (store.state.user.loggedIn) {
    next();
  } else {
    next("/login");
  }
});

export default router;
