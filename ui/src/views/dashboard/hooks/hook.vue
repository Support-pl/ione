<template>
  <a-row
    type="flex"
    justify="space-around"
    style="margin-top: 1rem"
    v-if="record"
  >
    <a-col :span="23">
      <a-row>
        <a-col :span="6">
          <h1>
            {{ record.ID }}: <b>{{ record.NAME }}</b>
          </h1>
        </a-col>
        <a-col :span="4" v-if="record.TYPE">
          <a-tag color="green" style="font-size: large">{{
            record.TYPE.toUpperCase()
          }}</a-tag>
        </a-col>
      </a-row>
      <a-row v-if="record.TEMPLATE">
        <a-col :span="12">
          <table class="template-table">
            <tr
              v-for="[key, val] of Object.entries(record.TEMPLATE)"
              :key="key"
            >
              <td>{{ key }}</td>
              <td>{{ val }}</td>
            </tr>
          </table>
        </a-col>
      </a-row>
      <a-row v-if="record.HOOKLOG && record.HOOKLOG.HOOK_EXECUTION_RECORD">
        <a-col :span="16">
          <hook-log-table
            :exec_records="
              Array.isArray(record.HOOKLOG.HOOK_EXECUTION_RECORD)
                ? record.HOOKLOG.HOOK_EXECUTION_RECORD
                : [record.HOOKLOG.HOOK_EXECUTION_RECORD]
            "
          />
        </a-col>
      </a-row>
    </a-col>
  </a-row>
</template>


<script>
import { mapGetters } from "vuex";
import HookLogTable from "@/components/hooks/log_table.vue";

export default {
  components: { HookLogTable },
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
    }
    this.sync();
  },
  methods: {
    sync() {
      this.$axios({
        method: "post",
        url: "/one.hk.to_hash!",
        data: {
          oid: this.id,
        },
        auth: this.credentials,
      }).then((res) => {
        this.record = res.data.response.HOOK;
      });
    },
  },
};
</script>

<style scoped>
table.template-table,
td {
  border: 1px solid black;
  padding: 2px 5px;
}

table.template-table {
  border-collapse: collapse;
}

table.template-table tr:last-child td:first-child {
  border-bottom-left-radius: 10px;
}

table.template-table tr:last-child td:last-child {
  border-bottom-right-radius: 10px;
}
</style>