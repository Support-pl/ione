<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23">
      <a-row :gutter="10">
        <a-col :span="4">
          <h1
            :style="{
              backgroundColor: record.status == 'SUCCESS' ? 'green' : 'red',
              padding: '2px 5px',
              textAlign: 'center',
              color: 'white',
              borderRadius: '5px',
            }"
          >
            <b>{{ record.playbook_name }}</b> {{ record.status }}
          </h1>
        </a-col>
        <a-col :span="6">
          <span>{{ record.install_id }}</span>
        </a-col>
        <a-col :span="4">
          <a-button type="primary" icon="redo" @click="sync">Refresh</a-button>
        </a-col>
      </a-row>
      <br />
      <a-row>
        <a-tabs>
          <a-tab-pane key="info" tab="Info"
            ><process-info-widget :record="record" />
          </a-tab-pane>
          <a-tab-pane key="exec" tab="Execution Data"
            ><process-execution-info-widget :record="record"
          /></a-tab-pane>
          <a-tab-pane key="log" tab="Log"
            ><log-view :lines="record.log.split('\n')"
          /></a-tab-pane>
        </a-tabs>
      </a-row>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

import ProcessInfoWidget from "@/components/process/info/info_widget.vue";
import ProcessExecutionInfoWidget from "@/components/process/info/execution_info_widget.vue";
import LogView from "@/components/log/view";

export default {
  components: { ProcessInfoWidget, ProcessExecutionInfoWidget, LogView },
  data() {
    return {
      id: undefined,
      record: {},
    };
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  mounted() {
    this.id = this.$route.params.id;
    if (this.$route.query.record) {
      this.record = this.$route.query.record;
    } else {
      this.sync();
    }
  },
  methods: {
    sync() {
      this.$axios({
        method: "get",
        url: "/ansible_process/" + this.id,
        auth: this.credentials,
      }).then((res) => {
        this.record = res.data.response;
      });
    },
  },
};
</script>