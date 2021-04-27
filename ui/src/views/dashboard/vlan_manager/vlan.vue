<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      <a-row>
        <a-col :span="6">
          ID: <b>{{ id }}</b>
        </a-col>
        <a-col :span="8">
          Type: <b>{{ vlan.type }}</b>
        </a-col>
        <a-col :span="4" :offset="6">
          <a-button type="primary" icon="reload" @click="sync"></a-button>
        </a-col>
      </a-row>
      <a-divider />
      <a-row :gutter="10" type="flex" justify="space-around">
        <a-col :span="lease_active ? 24 : 12" style="margin-top: 15px">
          <template v-if="lease_active">
            <a-row :gutter="10">
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
          </template>
          <a-button type="primary" icon="plus" @click="startLease" v-else
            >Lease VLAN(Create Network)</a-button
          >
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
      users: [],
      groups: [],
    };
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  mounted() {
    console.log(this.$route);
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
      });
    },
  },
};
</script>