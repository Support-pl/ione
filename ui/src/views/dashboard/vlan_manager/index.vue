<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      <a-collapse :active-key="Object.keys(pool)">
        <a-collapse-panel
          disabled
          :key="type"
          :header="type"
          v-for="(group, type) in pool"
        >
          <a-table
            :columns="vlans_group_table_columns"
            :data-source="group"
            rowKey="id"
            :pagination="false"
          >
            <a-row slot="leased" slot-scope="text, record">
              <a-col :span="4">
                <h4>
                  {{ record.leased }} <b>/ {{ record.size }}</b>
                </h4>
              </a-col>
              <a-col :span="20">
                <a-progress
                  :percent="(100 * record.leased) / record.size"
                ></a-progress>
              </a-col>
            </a-row>
          </a-table>
        </a-collapse-panel>
      </a-collapse>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  data() {
    return {
      pool: [],
      vlans_group_table_columns: [
        {
          dataIndex: "id",
          key: "id",
          title: "ID",
        },
        {
          dataIndex: "start",
          key: "start",
          title: "Start",
        },
        {
          key: "leased",
          title: "Leased",
          scopedSlots: { customRender: "leased" },
        },
      ],
    };
  },
  mounted() {
    this.sync();
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  methods: {
    sync() {
      this.$axios({
        method: "get",
        url: "/vlan",
        auth: this.credentials,
      }).then((res) => {
        this.pool = res.data.response.reduce(function (r, a) {
          r[a.type] = r[a.type] || [];
          r[a.type].push(a);
          return r;
        }, {});
      });
    },
  },
};
</script>

<style>
.ant-collapse > .ant-collapse-item > .ant-collapse-header {
  color: rgba(0, 0, 0, 0.85) !important;
}
</style>
