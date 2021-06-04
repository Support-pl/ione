<template>
  <div class="datastore">
    <a-table
      :columns="datastoreColumns"
      :data-source="hosts"
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

      <span slot="hypervisor" slot-scope="value, record">
        {{ record.VM_MAD }}
      </span>

      <span slot="deploy" slot-scope="text, record">
        <!-- <a-switch
          :checked="nodesDefault[record.VM_MAD] == record.ID"
          @change="deployHandler(checked) => updateAttribute(record.ID, 'DEPLOY', checked ? 'TRUE' : 'FALSE')"
				/> -->
        <a-switch
          :checked="nodesDefault[record.VM_MAD] == record.ID"
          @change="(checked) => deployHandler(checked, record)"
        />
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
    key: "VM_MAD",
    title: "Hypervisor",
    scopedSlots: { customRender: "hypervisor" },
  },
  {
    // key: "DEPLOY",
    title: "DEPLOY",
    scopedSlots: { customRender: "deploy" },
  },
];

export default {
  name: "datastore",
  data() {
    return {
      datastoreColumns,
      h_pool: {},
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
    hosts() {
      if (Object.keys(this.h_pool).length !== 0) {
        let pool = this.h_pool.HOST_POOL.HOST;
        if (!Array.isArray(pool)) {
          pool = [pool];
        }
        return pool.map((el) => {
          el.VM_MAD = el.VM_MAD.toUpperCase();
          return el;
        });
      }
      return [];
    },
    nodesDefaultSetting() {
      let result = this.settings.find((el) => el.name == "NODES_DEFAULT");
      return result;
    },
    nodesDefault() {
      return JSON.parse(this.nodesDefaultSetting.body);
    },
    ...mapGetters(["credentials"]),
  },
  methods: {
    async updateAttribute(id, key, val) {
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
        url: "/one.h.pool.to_hash!",
        auth: this.credentials,
        data: { params: [] },
      }).then((res) => (this.h_pool = res.data.response));
    },
    deployHandler(checked, record) {
      let requestBody = copyObject(this.nodesDefaultSetting);
      let settingBody = JSON.parse(requestBody.body);
      if (checked) {
        settingBody[record.VM_MAD] = record.ID;
      } else {
        delete settingBody[record.VM_MAD];
      }
      requestBody.body = JSON.stringify(settingBody);
      this.$axios({
        method: "post",
        url: `/settings/${requestBody.name}`,
        auth: this.credentials,
        data: requestBody,
      })
        .then((resp) => {
          if (resp.data.response) {
            this.$message.success("Success");
          } else {
            this.$message.error("Something went wrong");
          }
          this.sync();
        })
        .catch((err) => {
          console.error(err);
        });
    },
  },
  mounted() {
    this.sync();
  },
};

function copyObject(object) {
  const str = JSON.stringify(object);
  const obj = JSON.parse(str);
  return obj;
}
</script>

<style>
</style>