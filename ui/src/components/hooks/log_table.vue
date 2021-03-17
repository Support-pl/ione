<template>
  <a-table
    :data-source="exec_records.slice().reverse()"
    rowKey="EXECUTION_ID"
    :columns="columns"
    :expandRowByClick="true"
  >
    <span slot="timestamp" slot-scope="timestamp">
      {{ new Date(timestamp * 1000).toGMTString() }}
    </span>
    <span slot="result" slot-scope="text, record">
      <a-tag v-if="record.EXECUTION_RESULT.CODE == '0'" color="green"
        >SUCCESS</a-tag
      >
      <a-tag v-else color="red">ERROR</a-tag>
    </span>
    <span slot="retry" slot-scope="text, record">
      {{ record.EXECUTION_RESULT.RETRY ? record.EXECUTION_RESULT.RETRY : "NO" }}
    </span>
    <p slot="expandedRowRender" slot-scope="record" style="margin: 0">
      <a-tabs>
        <a-tab-pane key="output" tab="Output">
          <a-collapse
            :defaultActiveKey="
              record.EXECUTION_RESULT.CODE == '0' ? 'out' : 'err'
            "
          >
            <a-collapse-panel key="out" header="STDOUT">
              <pre>{{ atob(record.EXECUTION_RESULT.STDOUT) }}</pre>
            </a-collapse-panel>
            <a-collapse-panel key="err" header="STDERR">
              <pre>{{ atob(record.EXECUTION_RESULT.STDERR) }}</pre>
            </a-collapse-panel>
          </a-collapse>
        </a-tab-pane>
        <a-tab-pane key="arguments" tab="Arguments">
          <a-row :gutter="10">
            <a-col :span="8">
              <a-button
                type="primary"
                @click="copy('Arguments(Base64)', record.ARGUMENTS)"
                >Copy Arguments as Base64</a-button
              >
            </a-col>
            <a-col :span="8">
              <a-button
                type="primary"
                @click="copy('Arguments(XML)', atob(record.ARGUMENTS))"
                >Copy Arguments XML</a-button
              >
            </a-col>
            <a-col :span="8">
              <a-button
                type="primary"
                @click="copy('Command', record.EXECUTION_RESULT.COMMAND)"
                >Copy Command</a-button
              >
            </a-col>
          </a-row>
          <a-row style="margin-top: 15px; width: 80%">
            <xml-viewer :value="atob(record.ARGUMENTS)" />
          </a-row>
        </a-tab-pane>
      </a-tabs>
    </p>
  </a-table>
</template>

<script>
import xmlViewer from "./xml_viewer.vue";

export default {
  name: "hook-log-table",
  components: { xmlViewer },
  props: {
    exec_records: {
      required: true,
      type: Array,
    },
  },
  data() {
    return {
      columns: [
        {
          dataIndex: "EXECUTION_ID",
          key: "EXECUTION_ID",
          title: "Execution ID",
        },
        {
          dataIndex: "TIMESTAMP",
          key: "TIMESTAMP",
          title: "Timestamp",
          scopedSlots: { customRender: "timestamp" },
        },
        {
          key: "result",
          title: "Result",
          scopedSlots: { customRender: "result" },
        },
        {
          key: "retry",
          title: "Retry",
          scopedSlots: { customRender: "retry" },
        },
      ],
    };
  },
  methods: {
    atob(s) {
      try {
        return atob(s);
      } catch {
        return "";
      }
    },
    copy(wha, string) {
      var tempInput = document.createElement("input");
      tempInput.value = string;
      document.body.appendChild(tempInput);
      tempInput.select();
      document.execCommand("copy");
      document.body.removeChild(tempInput);

      this.$message.success(`${wha} successfuly copied to Clipboard`);
    },
  },
};
</script>