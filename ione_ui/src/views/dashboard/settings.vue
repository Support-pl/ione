<template>
  <a-row type="flex" justify="space-around">
    <a-col :span="22">
      <a-table
        :columns="columns"
        :data-source="settings"
        rowKey="name"
        :scroll="{ x: true }"
      >
        <span slot="access_level" slot-scope="access_level">
          <a-tag :color="access_level == 0 ? 'red' : 'blue'">{{
            access_level == 0 ? "User" : "Admin"
          }}</a-tag>
        </span>
        <span slot="description" slot-scope="text, record">
          <a-tooltip :title="record.name">{{ record.description }}</a-tooltip>
        </span>
        <span slot="body" slot-scope="text, record">
          <span v-if="record.type == 'num'" style="color: purple">{{
            record.body
          }}</span>
          <a-list
            v-else-if="record.type == 'list'"
            bordered
            :data-source="record.body.split(',')"
          >
            <a-list-item slot="renderItem" slot-scope="item">
              {{ item }}
            </a-list-item>
          </a-list>
          <span v-else>{{ record.body }}</span>
        </span>
      </a-table>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

const columns = [
  {
    dataIndex: "access_level",
    key: "access_level",
    title: "Access",
    scopedSlots: { customRender: "access_level" },
  },
  {
    dataIndex: "description",
    key: "description",
    title: "Description",
    scopedSlots: { customRender: "description" },
  },
  {
    dataIndex: "body",
    key: "body",
    slots: { title: "body" },
    scopedSlots: { customRender: "body" },
  },
  {
    dataIndex: "actions",
    key: "actions",
    title: "Actions",
    scopedSlots: { customRender: "actions" },
  },
];

export default {
  data() {
    return {
      settings: [],
      columns,
    };
  },
  async mounted() {
    this.sync();
  },
  computed: {
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
    },
  },
};
</script>