<template>
  <a-row
    type="flex"
    justify="space-around"
    style="margin-top: 1rem"
    :gutter="10"
  >
    <a-col :span="12" v-if="pool['api'].length > 0">
      <a-table
        :columns="columns_api"
        :data-source="pool['api']"
        rowKey="ID"
        :customRow="row_wrapper"
      >
        <span slot="method" slot-scope="text, record">
          {{ record.TEMPLATE.CALL.split(".")[2] }}
        </span>
      </a-table>
    </a-col>
    <a-col :span="12" v-if="pool['state'].length > 0">
      <a-table
        :columns="columns_state"
        :data-source="pool['state']"
        rowKey="ID"
        :customRow="row_wrapper"
      >
        <span slot="on" slot-scope="text, record">
          {{ record.TEMPLATE.STATE }}
          {{
            record.TEMPLATE.LCM_STATE ? `- ${record.TEMPLATE.LCM_STATE}` : ""
          }}
        </span>
      </a-table>
    </a-col>
  </a-row>
</template>

<script>
export default {
  name: "hooks-tab",
  props: {
    pool: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      columns_api: [
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
          key: "method",
          title: "Method",
          scopedSlots: { customRender: "method" },
        },
      ],

      columns_state: [
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
          key: "on",
          title: "On",
          scopedSlots: { customRender: "on" },
        },
      ],

      row_wrapper: (record) => {
        return {
          on: {
            click: () => {
              this.$router.push({
                path: `hooks/${record.ID}`,
                query: { record: record },
              });
            },
          },
        };
      },
    };
  },
};
</script>