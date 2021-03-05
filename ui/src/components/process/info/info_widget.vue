<template>
  <a-row>
    <a-col>
      <a-row>
        <a-col :span="6">
          <a-row>
            <b>Owner:</b>
            {{ record.uname ? record.uname : `UID: ${record.id}` }}
          </a-row>
        </a-col>
      </a-row>
      <a-row :gutter="10" style="margin-top: 5px">
        <a-col :span="6" class="date-block">
          <b>Start time: </b>
          {{
            record.create_time >= 0
              ? new Date(record.create_time * 1000).toGMTString()
              : "none"
          }}
        </a-col>
        <a-col :span="6" class="date-block">
          <b>End time: </b>
          {{
            record.end_time >= 0
              ? new Date(record.end_time * 1000).toGMTString()
              : "none"
          }}
        </a-col>
      </a-row>
      <a-row :gutter="10" style="margin-top: 15px">
        <a-col :span="12">
          <a-table :columns="columns" :data-source="codes" row-key="ip">
          </a-table>
        </a-col>
      </a-row>
    </a-col>
  </a-row>
</template>


<script>
export default {
  name: "process-info-widget",
  props: {
    record: {
      required: true,
      type: Object,
    },
  },
  computed: {
    codes() {
      let data = [];
      let codes = JSON.parse(this.record.codes);
      for (let [k, v] of Object.entries(codes)) {
        data.push({ ip: k, ...v });
      }
      return data;
    },
  },
  data() {
    return {
      columns: [
        {
          dataIndex: "ip",
          key: "ip",
          title: "Host",
        },
        {
          dataIndex: "ok",
          key: "ok",
          title: "Ok",
        },
        {
          dataIndex: "changed",
          key: "changed",
          title: "Changed",
        },
        {
          dataIndex: "unreachable",
          key: "unreachable",
          title: "Unreachable",
        },
        {
          dataIndex: "failed",
          key: "failed",
          title: "Failed",
        },
      ],
    };
  },
};
</script>

<style scoped>
.date-block {
  border: 1px solid black;
  border-radius: 5px;
  margin-left: 10px;
  text-align: center;
}
</style>