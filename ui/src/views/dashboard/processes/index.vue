<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      <a-row>
        <a-col :span="6">
          <a-button type="primary" icon="plus" @click="start"
            >Start Process</a-button
          >
        </a-col>
        <a-col :span="2">
          <a-button type="primary" icon="redo" @click="sync"></a-button>
        </a-col>
      </a-row>
      <a-row style="margin-top: 15px">
        <a-col :span="24">
          <a-table :columns="columns" :data-source="pool" row-key="proc_id">
            <span slot="id" slot-scope="text, record">
              {{ record.id }}
            </span>
            <span slot="owner" slot-scope="text, record">
              {{ record.uname ? record.uname : `UID: ${record.id}` }}
            </span>
            <span slot="datetime" slot-scope="datetime">
              {{
                datetime >= 0 ? new Date(datetime * 1000).toGMTString() : "none"
              }}
            </span>
            <span slot="status" slot-scope="status">
              <a-tag :color="status_color(status)">{{ status }}</a-tag>
            </span>
            <!-- <span slot="action" slot-scope="text, record">
              <a-space>
                <a-button
                  type="link"
                  icon="edit"
                  @click="edit(record)"
                ></a-button>
                <a-button
                  type="link"
                  icon="unlock"
                  @click="edit_access(record)"
                ></a-button>
                <a-button
                  type="danger"
                  icon="delete"
                  @click="remove(record.id)"
                ></a-button>
              </a-space>
            </span> -->
          </a-table>
        </a-col>
      </a-row>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

const colors = {
  FAILED: "red",
  SUCCESS: "green",
};

export default {
  data() {
    return {
      pool: [],
      columns: [
        {
          dataindex: "id",
          key: "id",
          title: "ID",
          scopedSlots: { customRender: "id" },
        },
        {
          dataIndex: "playbook_name",
          key: "playbook_name",
          title: "Playbook",
        },
        {
          dataIndex: "uname",
          key: "uname",
          title: "Owner",
          scopedSlots: { customRender: "owner" },
        },
        {
          dataIndex: "create_time",
          key: "create_time",
          title: "Start time",
          scopedSlots: { customRender: "datetime" },
        },
        {
          dataIndex: "end_time",
          key: "end_time",
          title: "End time",
          scopedSlots: { customRender: "datetime" },
        },
        {
          dataIndex: "status",
          key: "status",
          title: "Status",
          scopedSlots: { customRender: "status" },
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
    status_color(status) {
      return colors[status];
    },
    sync() {
      this.$axios({
        method: "get",
        url: "/ansible_process",
        auth: this.credentials,
      }).then((res) => {
        this.pool = res.data.response;
      });
    },
    start() {},
  },
};
</script>