<template>
  <a-layout>
    <a-layout-header class="header"><h1>IONe</h1></a-layout-header>
    <a-layout>
      <a-layout-sider>
        <a-menu
          mode="inline"
          v-model="route"
          :style="{ height: '100%', borderRight: 0 }"
        >
          <a-menu-item key="settings">
            <router-link :to="{ path: '/dashboard/settings' }">
              Settings
            </router-link>
          </a-menu-item>
          <a-menu-item key="costs"> Costs </a-menu-item>
          <a-menu-item key="hosts"> Hosts(Nodes) </a-menu-item>
          <a-menu-item key="datastores">
            <router-link :to="{ path: '/dashboard/datastores' }">
              Datastores
            </router-link>
          </a-menu-item>
        </a-menu>
      </a-layout-sider>
      <a-layout-content>
        <router-view />
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script>
export default {
  data() {
    return {
      route: [],
    };
  },
  mounted() {
    this.route = ["settings"];
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