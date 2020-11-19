<template>
  <div class="datastore">
    <a-table
      :columns="datastoreColumns"
      :data-source="filt(dsItems)"
      rowKey="ID"
      :pagination="false"
    >
      <span slot="disktype" slot-scope="type">
        <a-select :default-value="type" style="width: 200px">
          <a-select-option
            v-for="(select, key) in disktypes.body.split(', ')"
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
          <a-button>cancel</a-button>
          <a-button type="primary">submit</a-button>
        </a-button-group>
      </a-col>
    </a-row>
  </div>
</template>

<script>
import { mapGetters } from "vuex";
import dsItems from "./datastore/ds";
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
      dsItems,
      datastoreColumns,
      settings: [],
      editingKey: "",
      cacheData: [],
    };
  },
  computed: {
    disktypes() {
      let types = this.settings.find((el) => el.name == "DISK_TYPES");
      return types;
    },

    ...mapGetters(["credentials"]),
  },
  methods: {
    filt(data) {
      return data.DATASTORE_POOL.DATASTORE.filter((el) => el.TYPE == 1);
    },
    async sync() {
      this.settings = (
        await this.$axios({
          method: "get",
          url: "/settings",
          auth: this.credentials,
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