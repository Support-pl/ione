<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      <a-row>
        <a-col :span="4">
          <a-button type="primary" icon="reload" @click="sync"></a-button>
        </a-col>
        <a-col :span="4">
          ID: <b>{{ id }}</b>
        </a-col>
        <a-col :span="4">
          Type: <b>{{ vlan.type }}</b>
        </a-col>
        <a-col :span="12">
          <a-row>
            <a-col :span="4">
              <h4>
                {{ vlan.leased }} <b>/ {{ vlan.size }}</b>
              </h4>
            </a-col>
            <a-col :span="20">
              <a-progress
                :showInfo="false"
                :percent="(100 * vlan.leased) / vlan.size"
              ></a-progress>
            </a-col>
          </a-row>
        </a-col>
      </a-row>
      <a-divider />
      <a-row :gutter="10" type="flex" justify="space-around">
        <a-col :span="lease_active ? 24 : 12" style="margin-top: 15px">
          <a-row v-if="lease_active" :gutter="10">
            <a-col :span="5">
              <a-select
                placeholder="Owner"
                style="width: 100%"
                :showSearch="true"
                v-model="lease_tmpl[1]"
              >
                <a-select-option
                  :key="user.ID"
                  :value="parseInt(user.ID)"
                  v-for="user in users"
                  >{{ user.ID }}: {{ user.NAME }}</a-select-option
                >
              </a-select>
            </a-col>
            <a-col :span="5">
              <a-select
                placeholder="Group"
                style="width: 100%"
                :showSearch="true"
                v-model="lease_tmpl[2]"
              >
                <a-select-option
                  :key="group.ID"
                  :value="parseInt(group.ID)"
                  v-for="group in groups"
                  >{{ group.ID }}: {{ group.NAME }}</a-select-option
                >
              </a-select>
            </a-col>
            <a-col :span="8">
              <a-input
                placeholder="VNet Name"
                v-model="lease_tmpl[0]"
              ></a-input>
            </a-col>
            <a-col :span="6">
              <a-row :gutter="5">
                <a-button type="link" icon="save" @click="createLease"
                  >Create</a-button
                >
                <a-button type="link" icon="close" @click="cancelLease"
                  >Cancel</a-button
                >
              </a-row>
            </a-col>
          </a-row>
          <a-button type="primary" icon="plus" @click="startLease" v-else
            >Lease VLAN(Create Network)</a-button
          >
        </a-col>
        <a-col :span="reserve_active ? 24 : 12" style="margin-top: 15px">
          <a-row v-if="reserve_active" :gutter="10">
            <a-col :span="5">
              <a-select
                placeholder="Virtual Network"
                style="width: 100%"
                :showSearch="true"
                v-model="reserve_tmpl.vn"
                v-show="!reserve_tmpl.reserve"
              >
                <a-select-option
                  :key="vn.ID"
                  :value="parseInt(vn.ID)"
                  v-for="vn in vns"
                  >{{ vn.ID }}: {{ vn.NAME }}</a-select-option
                >
              </a-select>
            </a-col>
            <a-col :span="5">
              <a-button
                type="primary"
                @click="reserve_tmpl.reserve = !reserve_tmpl.reserve"
                >{{
                  reserve_tmpl.reserve ? "Bind to VNet" : "Reserve VLAN"
                }}</a-button
              >
            </a-col>
            <a-col :span="8">
              <a-input-number
                placeholder="VLAN ID"
                v-model="reserve_tmpl.vlan"
              ></a-input-number>
            </a-col>
            <a-col :span="6">
              <a-row :gutter="5">
                <a-button type="link" icon="save" @click="createReserve"
                  >Reserve</a-button
                >
                <a-button type="link" icon="close" @click="cancelReserve"
                  >Cancel</a-button
                >
              </a-row>
            </a-col>
          </a-row>
          <a-button type="primary" icon="border" @click="startReserve" v-else
            >Reserve VLAN(or bind to Network)</a-button
          >
        </a-col>
      </a-row>
      <a-row style="margin-top: 20px">
        <a-col :span="24">
          <a-table :columns="columns" :data-source="vlan.leases">
            <span slot="leased" slot-scope="text, record">
              <template v-if="record.vn !== null">
                Leased to {{ record.vn_name }}({{ record.vn }})
              </template>
              <template v-else> Hold </template>
            </span>
            <span slot="actions" slot-scope="text, record">
              <a-button
                type="danger"
                icon="delete"
                v-if="!record.vn"
                @click="release(record.id)"
                >Release</a-button
              >
            </span>
          </a-table>
        </a-col>
      </a-row>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

export default {
  data() {
    return {
      id: undefined,
      vlan: {},
      lease_active: false,
      lease_tmpl: [],

      reserve_active: false,
      reserve_tmpl: {},

      users: [],
      groups: [],
      vns: [],

      columns: [
        {
          dataIndex: "key",
          key: "key",
          title: "ID",
          width: "10%",
        },
        {
          dataIndex: "id",
          key: "id",
          title: "VLAN ID",
          width: "20%",
        },
        {
          key: "vn",
          title: "VNet",
          scopedSlots: { customRender: "leased" },
        },
        {
          key: "actions",
          title: "Actions",
          scopedSlots: { customRender: "actions" },
          width: "20%",
        },
      ],
    };
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  mounted() {
    if (this.$route.query.id) {
      this.id = this.$route.query.id;
      this.sync();
    } else {
      this.$router.go(-1);
    }
  },
  methods: {
    sync() {
      this.$axios({
        method: "get",
        url: `/vlan/${this.id}`,
        auth: this.credentials,
      }).then((res) => {
        this.vlan = res.data.response;
      });
    },
    startLease() {
      this.$axios({
        method: "post",
        url: "/one.u.pool.to_hash!",
        auth: this.credentials,
      }).then((res) => {
        let users = res.data.response.USER_POOL.USER;
        if (Array.isArray(users)) this.users = users;
        else this.users = [users];
      });
      this.$axios({
        method: "post",
        url: "/one.g.pool.to_hash!",
        auth: this.credentials,
      }).then((res) => {
        let groups = res.data.response.GROUP_POOL.GROUP;
        if (Array.isArray(groups)) this.groups = groups;
        else this.groups = [groups];
      });
      this.lease_tmpl = [];
      this.lease_active = true;
    },
    createLease() {
      console.log(this.lease_tmpl);
      this.$axios({
        method: "post",
        url: `/vlan/${this.id}/lease`,
        auth: this.credentials,
        data: {
          params: this.lease_tmpl,
        },
      }).then((res) => {
        if (res.data.error) {
          this.$notification.error({
            message: "Error creating VN/Lease",
            description: res.data.error,
          });
        } else {
          this.$notification.success({
            message: `New VN with ID ${res.data.response} successfuly created`,
          });

          this.cancelLease();
          this.sync();
        }
      });
    },
    cancelLease() {
      this.lease_tmpl = [];
      this.lease_active = false;
    },
    startReserve() {
      this.$axios({
        method: "post",
        url: "/one.vn.pool.to_hash!",
        auth: this.credentials,
      }).then((res) => {
        this.vns = res.data.response.VNET_POOL.VNET;
      });
      this.reserve_tmpl = { reserve: true };
      this.reserve_active = true;
    },
    createReserve() {
      let params = [this.reserve_tmpl.vlan];
      if (!this.reserve_tmpl.reserve) params.push(this.reserve_tmpl.vn);
      console.log(params);
      this.$axios({
        method: "post",
        url: `/vlan/${this.id}/reserve`,
        auth: this.credentials,
        data: {
          params: params,
        },
      }).then((res) => {
        if (res.data.error) {
          this.$notification.error({
            message: "Error creating Lease",
            description: res.data.error,
          });
        } else {
          this.$notification.success({
            message: `New Lease successfuly created`,
          });

          this.cancelReserve();
          this.sync();
        }
      });
    },
    cancelReserve() {
      this.reserve_tmpl = {};
      this.reserve_active = false;
    },
    release(id) {
      this.$axios({
        method: "delete",
        url: `/vlan/${this.id}/lease/${id}`,
        auth: this.credentials,
      }).then((res) => {
        if (res.data.error) {
          this.$notification.error({
            message: `Error releasing VLAN(${id})`,
            description: res.data.error,
          });
        } else {
          this.$notification.success({
            message: `VLAN(${id}) successfuly released`,
          });

          this.sync();
        }
      });
    },
  },
};
</script>