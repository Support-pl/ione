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
					<a-input
						v-if="record.editable"
						style="margin: -5px 0"
						:value="text"
						@change="e => handleChange(e.target.value, record.name, 'body')"
						@keyup.enter="save(record.name)"
						@keyup.escape="cancel(record.name)"
					/>
          <num v-else-if="record.type == 'num'" :value="record" />
          <list v-else-if="record.type == 'list'" :value="record" />
          <obj v-else-if="record.type == 'object'" :value="record" />
          <raw v-else :value="record" />
        </span>
				<span slot="actions" slot-scope="text, record">
					<div class="editable-row-operations">
						<span v-if="record.editable">
							<a @click="() => save(record.name)">Save</a>
							<a-popconfirm title="Sure to cancel?" @confirm="() => cancel(record.name)">
								<a>Cancel</a>
							</a-popconfirm>
						</span>
						<span v-else>
							<a :disabled="editingKey !== ''" @click="() => edit(record.name)">Edit</a>
						</span>
					</div>
				</span>
      </a-table>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";
import num from "./types/num.vue";
import list from "./types/list.vue";
import raw from "./types/raw.vue";
import obj from "./types/object.vue";


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
	name: "Settings",
	components: {
		num,
		list,
		raw,
		obj
	},
  data() {
    return {
      settings: [],
      columns,
			editingKey: '',
			cacheData: [],
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
      this.cacheData = this.settings.map(item => ({ ...item }));
		},
		handleChange(value, key, column) {
      const newData = [...this.settings];
      const target = newData.filter(item => key === item.name)[0];
      if (target) {
        target[column] = value;
        this.settings = newData;
      }
    },
    edit(key) {
			const newData = [...this.settings];
      const target = newData.filter(item => key === item.name)[0];
      this.editingKey = key;
      if (target) {
        target.editable = true;
        this.settings = newData;
      }
    },
    save(key) {
      const newData = [...this.settings];
      const newCacheData = [...this.cacheData];
      const target = newData.filter(item => key === item.name)[0];
      const targetCache = newCacheData.filter(item => key === item.name)[0];
      if (target && targetCache) {
				delete target.editable;
        this.$axios({
          method: "post",
          url: `/settings/${key}`,
					auth: this.credentials,
					data: target
				})
				.then(res => {
					if(res.data.response == 1){
						this.$message.success('Успешно')
					} else {
						this.$message.error('Ошибка')
						this.cancel(key);
						return;
					}
					this.settings = newData;
					Object.assign(targetCache, target);
					this.cacheData = newCacheData;
				})
				.catch(err => {
					console.error(err)
					this.$message.error('Ошибка')
					this.cancel(key);
				})
      }
      this.editingKey = '';
    },
    cancel(key) {
      const newData = [...this.settings];
      const target = newData.filter(item => key === item.name)[0];
      this.editingKey = '';
      if (target) {
        Object.assign(target, this.cacheData.filter(item => key === item.name)[0]);
        delete target.editable;
        this.settings = newData;
      }
		},
		log(){
			console.log(...arguments);
		}
  },
};
</script>