<template>
  <a-row>
    <a-col :span="24">
      <a-row>
        <a-table
          :columns="columns"
          :data-source="data"
          :show-header="false"
          :pagination="false"
          row-key="name"
        >
          <span slot="name" slot-scope="text, record">
            <a-input
              v-model="record.name"
              @change="(e) => change_key(record.name, e.target.value)"
            ></a-input>
          </span>
          <span slot="body" slot-scope="text, record">
            <a-input
              v-model="record.body"
              @change="(e) => change_val(record.name, e.target.value)"
            ></a-input>
          </span>
          <span slot="actions" slot-scope="text, record">
            <a-button
              type="link"
              icon="close"
              @click="remove_key(record.name)"
            ></a-button>
          </span>
        </a-table>
      </a-row>
      <a-row type="flex" justify="center">
        <a-button type="primary" icon="plus" @click="add_key">Add key</a-button>
      </a-row>
    </a-col>
  </a-row>
</template>

<script>
export default {
  name: "object-editor",
  props: {
    value: {
      required: true,
      type: String,
    },
  },
  computed: {
    data: {
      get() {
        let pool = [];
        for (let [k, v] of Object.entries(JSON.parse(this.value))) {
          pool.push({ name: k, body: v });
        }
        return pool;
      },
      set(val) {
        this.$emit(
          "change",
          JSON.stringify(
            val.reduce((r, el) => {
              r[el.name] = el.body;
              return r;
            }, {})
          )
        );
      },
    },
  },
  data() {
    return {
      columns: [
        {
          dataIndex: "name",
          key: "name",
          scopedSlots: { customRender: "name" },
        },
        {
          dataIndex: "body",
          key: "body",
          scopedSlots: { customRender: "body" },
        },
        {
          dataIndex: "actions",
          key: "actions",
          scopedSlots: { customRender: "actions" },
        },
      ],
    };
  },
  methods: {
    add_key() {
      let data = this.data;
      data.push({ name: "DEFAULT_KEY", body: "" });
      this.data = data;
    },
    remove_key(key) {
      let data = this.data;
      data.splice(
        data.findIndex((v) => v.name === key),
        1
      );
      this.data = data;
    },
    change_key(key, new_key) {
      let data = this.data;
      let val = data[key];
      this.remove_key(key);
      data.push({ name: new_key, body: val });
      this.data = data;
    },
    change_val(key, val) {
      let data = this.data;
      data[key] = val;
      this.data = data;
    },
  },
};
</script>