<template>
  <div @click="timerUpdate" class="frame" style="min-height: 100%">
    <a-layout style="min-height: 100%">
      <a-layout-header class="header"><h1>IONe</h1></a-layout-header>
      <a-layout>
        <a-layout-sider>
          <a-menu
            mode="inline"
            v-model="route"
            :style="{ height: '100%', borderRight: 0 }"
          >
            <a-menu-item v-for="item in asideBtns" :key="item.name">
              <router-link
                :to="{
                  path: item.route
                    ? `/dashboard/${item.route}`
                    : `/dashboard/${item.name}`,
                }"
              >
                {{ item.name | capitalize }}
              </router-link>
            </a-menu-item>
          </a-menu>
        </a-layout-sider>
        <a-layout-content>
          <router-view />
        </a-layout-content>
      </a-layout>
    </a-layout>
  </div>
</template>

<script>
const asideBtns = [
  {
    name: "settings",
  },
  {
    name: "costs",
  },
  {
    name: "Hosts (Nodes)",
    route: "hosts",
  },
  {
    name: "datastores",
  },
  {
    name: "Ansible Playbooks",
    route: "playbooks",
  },
  {
    name: "Ansible Processes",
    route: "processes",
  },
  {
    name: "logs",
  },
];
export default {
  data() {
    return {
      route: [],
      asideBtns,
      timeoutTimer: -1,
    };
  },
  mounted() {
    this.route = ["settings"];
    this.setTimer();
  },
  filters: {
    capitalize(value) {
      if (!value) return "";
      value = value.toString();
      return value.charAt(0).toUpperCase() + value.slice(1);
    },
  },
  methods: {
    setTimer() {
      const timeout = 30; // minutes
      const self = this;
      this.timeoutTimer = setTimeout(() => {
        self.$message.warning("Session expired. Return to login page...");
        setTimeout(() => {
          location.reload();
        }, 3000); //3 secs to read message
      }, timeout * 60000);
    },
    timerUpdate() {
      clearTimeout(this.timeoutTimer);
      this.setTimer();
    },
  },
};
</script>

<style scoped>
.header {
  background-color: rgb(122, 210, 240);
}

.header h1 {
  color: white;
  font-weight: 500;
}
</style>