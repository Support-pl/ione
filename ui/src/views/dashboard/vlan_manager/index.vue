<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      <a-row type="flex" justify="space-between">
        <a-col :span="6">
          <a-button type="primary" icon="reload" @click="sync"></a-button>
        </a-col>
        <a-col :span="6">
          <a-button type="primary" @click="create_drawer_visible = true"
            >Create VLAN Range</a-button
          >
        </a-col>
      </a-row>

      <a-row
        type="flex"
        justify="center"
        v-if="Object.keys(pool).length === 0"
        style="margin-top: 10%"
      >
        <a-col :span="8">
          <h3>No VLAN Pools registered yet</h3>
        </a-col>
      </a-row>
      <a-collapse
        :active-key="Object.keys(pool)"
        style="margin-top: 10px"
        v-else
      >
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
            :customRow="row_wrapper"
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
            <a-space slot="actions" slot-scope="text, record">
              <a-popconfirm
                title="Sure to delete?"
                @confirm="(e) => handleDelete(record.id)"
              >
                <a-button type="danger" icon="delete"></a-button>
              </a-popconfirm>
                @click="handleNavigate(record.id)"
              ></a-button>
            </a-space>
          </a-table>
        </a-collapse-panel>
      </a-collapse>
    </a-col>

    <VLANPoolCreate
      :visible="create_drawer_visible"
      @save="handleCreate"
      @close="create_drawer_visible = false"
    />
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

import VLANPoolCreate from "@/components/vlan_manager/create";

export default {
  components: { VLANPoolCreate },
  data() {
    return {
      pool: [],
      create_drawer_visible: false,
      vlans_group_table_columns: [
        {
          dataIndex: "id",
          key: "id",
          title: "ID",
          width: "10%",
        },
        {
          dataIndex: "start",
          key: "start",
          title: "Start",
          width: "10%",
        },
        {
          key: "leased",
          title: "Leased",
          scopedSlots: { customRender: "leased" },
        },
        {
          key: "actions",
          title: "Actions",
          scopedSlots: { customRender: "actions" },
          width: "20%",
        },
      ],
      row_wrapper: (record) => {
        return {
          on: {
            click: () => {
              this.handleNavigate(record.id);
            },
          },
        };
      },
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
    handleCreate(vlan) {
      this.$axios({
        method: "post",
        url: "/vlan",
        auth: this.credentials,
        data: vlan,
      })
        .then((res) => {
          if (res.data.error) {
            this.$notification.error({
              message: "Error creating VLAN Range",
              description: res.data.error,
            });
          } else {
            this.$notification.success({ message: "New VLAN Range created" });
            this.create_drawer_visible = false;
            this.sync();
          }
        })
        .catch(() => {
          this.$notification.error({
            message: "Server Exception, check logs",
          });
        });
    },
    handleDelete(id) {
      this.$axios({
        method: "delete",
        url: `/vlan/${id}/delete`,
        auth: this.credentials,
      }).then((res) => {
        if (res.data.error) {
          this.$notification.error({
            message: "Error deleting VLAN Range",
            description: res.data.error,
          });
        } else {
          this.$notification.success({ message: `VLAN Range #${id} deleted` });
          this.sync();
        }
      });
    },
    handleNavigate(id) {
      this.$router.push({
        path: "/dashboard/vlan-manager/vlan/",
        query: { id },
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
