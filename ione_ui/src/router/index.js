import Vue from "vue";
import VueRouter from "vue-router";
import HelloWorld from "@/views/HelloWorld.vue";

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
    meta: {
      requiresAuth: true,
    },
    children: [
      {
        path: "settings",
        component: () => import("@/views/dashboard/settings.vue"),
      },
      {
        path: "datastores",
        component: () => import("@/views/dashboard/datastores.vue"),
      },
    ],
  },
];

const router = new VueRouter({
  routes,
});

export default router;
