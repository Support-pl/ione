<template>
  <div class="datastore">
    <a-table
      :columns="datastoreColumns"
      :data-source="datastores"
      rowKey="ID"
      :pagination="false"
    >
      <span slot="disktype" slot-scope="type">
        <a-select :default-value="type" style="width: 200px">
          <a-select-option
            v-for="(select, key) in disktypes"
            :key="key"
            :value="select"
            >{{ select }}</a-select-option
          >
        </a-select>
      </span>

      <span slot="hypervisor" slot-scope="current">
        <a-input :value="current" style="width: 200px"></a-input>
      </span>

      <span slot="deploy" slot-scope="current">
        <a-switch :checked="current == 'TRUE'"></a-switch>
      </span>
    </a-table>
    <a-row type="flex" justify="end">
      <a-col style="padding: 15px 50px">
        <a-button-group>
          <a-button>Cancel</a-button>
          <a-button type="primary">Submit</a-button>
        </a-button-group>
      </a-col>
    </a-row>
  </div>
</template>

<script>
import { mapGetters } from "vuex";
const datastoreColumns = [
  {
    dataIndex: "ID",
    key: "ID",
    title: "ID",
  },
  {
    dataIndex: "NAME",
    key: "NAME",
    title: "NAME",
  },
  {
    dataIndex: "TEMPLATE.DRIVE_TYPE",
    key: "DISK_TYPE",
    title: "DISK TYPE",
    scopedSlots: { customRender: "disktype" },
  },
  {
    dataIndex: "TEMPLATE.HYPERVISOR",
    key: "HYPERVISOR",
    title: "HYPERVISOR",
    scopedSlots: { customRender: "hypervisor" },
  },
  {
    dataIndex: "TEMPLATE.DEPLOY",
    key: "DEPLOY",
    title: "DEPLOY",
    scopedSlots: { customRender: "deploy" },
  },
];

export default {
  name: "datastore",
  data() {
    return {
      datastoreColumns,
      ds_pool: {},
      settings: [],
      editingKey: "",
      cacheData: [],
    };
  },
  computed: {
    disktypes() {
      let types = (
        this.settings.find((el) => el.name == "DISK_TYPES") ?? { body: "" }
      ).body.split(",");
      return types;
    },
    datastores() {
      if (Object.keys(this.ds_pool).length !== 0)
        return this.ds_pool.DATASTORE_POOL.DATASTORE.filter(
          (el) => el.TYPE == 1
        );
      return [];
    },

    ...mapGetters(["credentials"]),
  },
  methods: {
    async sync() {
      this.settings = (
        await this.$axios({
          method: "get",
          url: "/settings",
          auth: this.credentials,
        })
      ).data.response;
      this.ds_pool = (
        await this.$axios({
          method: "post",
          url: "/one.ds.pool.to_hash!",
          auth: this.credentials,
          data: { params: [] },
        })
      ).data.response;
    },
  },
  mounted() {
    this.sync();
  },
};
</script>

<style>
</style>