<template>
  <div class="datastore">
    <a-table
      :columns="datastoreColumns"
      :data-source="datastores"
      rowKey="ID"
      :pagination="false"
    >
      <span slot="disktype" slot-scope="text, record">
        <a-select
          :default-value="record.TEMPLATE.DRIVE_TYPE"
          style="width: 200px"
          @change="(type) => updateAttribute(record.ID, 'DRIVE_TYPE', type)"
        >
          <a-select-option
            v-for="(select, key) in disktypes"
            :key="key"
            :value="select"
            >{{ select }}</a-select-option
          >
        </a-select>
      </span>

      <span slot="hypervisor" slot-scope="text, record">
        <a-tooltip title="Press Enter to save change">
          <a-input
            v-model="record.TEMPLATE.HYPERVISOR"
            style="width: 200px"
            @pressEnter="
              updateAttribute(
                record.ID,
                'HYPERVISOR',
                record.TEMPLATE.HYPERVISOR
              )
            "
            @change="
              record.TEMPLATE.HYPERVISOR = record.TEMPLATE.HYPERVISOR.toUpperCase()
            "
          ></a-input>
        </a-tooltip>
      </span>

      <span slot="deploy" slot-scope="text, record">
        <a-switch
          :checked="record.TEMPLATE.DEPLOY == 'TRUE'"
          @change="
            (checked) =>
              updateAttribute(record.ID, 'DEPLOY', checked ? 'TRUE' : 'FALSE')
          "
        ></a-switch>
      </span>
    </a-table>
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
    key: "DISK_TYPE",
    title: "Drive Type",
    scopedSlots: { customRender: "disktype" },
  },
  {
    key: "HYPERVISOR",
    title: "Hypervisor",
    scopedSlots: { customRender: "hypervisor" },
  },
  {
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
    async updateAttribute(id, key, val) {
      console.log(key, val);
      await this.$axios({
        method: "post",
        url: "/one.ds.update",
        auth: this.credentials,
        data: {
          oid: id,
          params: [`${key}="${val}"`, true],
        },
      });
      this.sync();
    },
    sync() {
      this.$axios({
        method: "get",
        url: "/settings",
        auth: this.credentials,
      }).then((res) => (this.settings = res.data.response));
      this.$axios({
        method: "post",
        url: "/one.ds.pool.to_hash!",
        auth: this.credentials,
        data: { params: [] },
      }).then((res) => (this.ds_pool = res.data.response));
    },
  },
  mounted() {
    this.sync();
  },
};
</script>

<style>
</style>