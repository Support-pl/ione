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
          <a-menu-item v-for="item in asideBtns" :key="item.name">
            <router-link :to="{ path: item.route ? item.route : `/dashboard/${item.name}` }">
              {{item.name | capitalize}}
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
const asideBtns = [
	{
		name: "settings",
	},
	{
		name: "costs",
	},
	{
		name: "hosts (Nodes)",
		route: "hosts",
	},
	{
		name: "datastores",
	},
]
export default {
  data() {
    return {
			route: [],
			asideBtns
    };
  },
  mounted() {
    this.route = ["settings"];
	},
	filters: {
		capitalize(value) {
			if (!value) return ''
			value = value.toString()
			return value.charAt(0).toUpperCase() + value.slice(1)
		}
	}
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