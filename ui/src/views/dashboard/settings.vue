<template>
	<div class="view__container view__container--settings">
		<a-row class="view__buttons" type="flex" justify="start">
			<a-col :span="2">
				<a-button
					icon="plus"
					type="primary"
					@click="() => addSetting.visible = true"	
				>
					Add setting
				</a-button>
				<a-modal
					title="Add setting"
					:visible="addSetting.visible"
					:confirm-loading="addSetting.loading"
					@ok="sendNewSetting"
					@cancel="() => addSetting.visible = false"
				>
					<a-row class="add-setting__info-row">
						<a-col>Name:</a-col>
						<a-col>
							<a-input
								v-model="addSetting.data.name"
								placeholder="Enter new setting name"
							/>
						</a-col>
					</a-row>

					<a-row class="add-setting__info-row">
						<a-col>Description:</a-col>
						<a-col>
							<a-textarea
								v-model="addSetting.data.description"
								placeholder="Enter new setting description"
								:auto-size="{ minRows: 3, maxRows: 5 }"
							/>
						</a-col>
					</a-row>

					<a-row class="add-setting__info-row">
						<a-col>Body (value):</a-col>
						<a-col>
							<a-input
								v-model="addSetting.data.body"
								placeholder="Enter new setting body"
							/>
						</a-col>
					</a-row>
					
					<a-row class="add-setting__info-row" :gutter='[20, 0]'>
						<a-col :span="12">
							<a-row>
								<a-col>Type:</a-col>
								<a-col>
									<a-select v-model="addSetting.data.type" style="width: 100%">
										<a-select-option v-for="(fieldType, index) in possibleFieldTypes" :value="fieldType" :key="'fieldType' + index">
											{{fieldType}}
										</a-select-option>
									</a-select>
								</a-col>
							</a-row>
						</a-col>
						<a-col :span="12">
							<a-row>
								<a-col>Access level:</a-col>
								<a-col>
									<a-select v-model="addSetting.data.access_level" style="width: 100%">
										<a-select-option v-for="(level, index) in possibleAccesslevels" :value="index" :key="'level' + index">
											{{level}}
										</a-select-option>
									</a-select>
								</a-col>
							</a-row>
						</a-col>
					</a-row>
					<a-row>
						<a-col>
							<span>All fields are required.</span>
						</a-col>
					</a-row>
				</a-modal>
			</a-col>
		</a-row>
		<a-row type="flex" justify="space-around">
			<a-col :span="24">
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
						<a-tooltip :title="record.name">{{
							record.description ? record.description : record.name
						}}</a-tooltip>
					</span>
					<span slot="body" slot-scope="text, record">
						<a-input
							v-if="record.editable"
							style="margin: -5px 0"
							:value="text"
							@change="(e) => handleChange(e.target.value, record.name, 'body')"
							@keyup.enter="save(record.name)"
							@keyup.escape="cancel(record.name)"
						/>
						<component
							v-else-if="Object.keys(types).includes(record.type)"
							:is="types[record.type]"
							:value="record"
						/>
						<component
							v-else
							:is="types.raw"
							:value="record"
						/>
					</span>
					<span slot="actions" slot-scope="text, record">
						<a-space class="editable-row-operations">
							<template v-if="record.editable">
								<a-popconfirm
									title="Sure to save?"
									@confirm="() => save(record.name)"
								>
									<a>Save</a>
								</a-popconfirm>
								<a @click="() => cancel(record.name)">Cancel</a>
								
								<a-popconfirm
									@confirm="() => deleteField(record.name)"
								>
									<div slot="title" style="max-width: 160px">
										Type field name:
										<a-input stle="margin-top: 10px" v-model="deletingFieldNameSecurity"/>
									</div>
									<a color="red">DELETE</a>
								</a-popconfirm>
							</template>
							<span v-else>
								<a :disabled="editingKey !== ''" @click="() => edit(record.name)"
									>Edit</a
								>
							</span>
						</a-space>
					</span>
				</a-table>
			</a-col>
		</a-row>
	</div>
</template>

<script>
import { mapGetters } from "vuex";
import raw from "@/components/types/raw.vue";
import num from "@/components/types/num.vue";
import bool from "@/components/types/bool.vue";
import list from "@/components/types/list.vue";
import str from "@/components/types/raw.vue";
import object from "@/components/types/object.vue";
import bool from "@/components/types/bool.vue";

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

const possibleFieldTypes = ['int', 'float', 'str', 'object', 'list'];
const possibleAccesslevels = ['User', 'Admin'];

export default {
  name: "Settings",
  data() {
    return {
      settings: [],
      columns,
      editingKey: "",
      cacheData: [],
      types: {
				float: num,
				int: num,
        num,
        list,
        str,
        bool,
        object,
				bool,
				raw,
      },
      selfEdit: ["object"],
			
			addSetting: {
				visible: false,
				loading: false,
				data: {
					access_level: 1,
					body: "",
					description: "",
					name: "",
					type: "",
				}
			},

			possibleFieldTypes,
			possibleAccesslevels,

			deletingFieldNameSecurity: '',
    };
  },
  async mounted() {
    this.sync();
    this.addSettingInit();
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  methods: {
		addSettingInit(){
			this.addSetting.visible = false;
			this.addSetting.loading = false;
			this.addSetting.data = {
				access_level: 1,
				body: "",
				description: "",
				name: "",
				type: this.possibleFieldTypes[0],
			}
		},
    async sync() {
      this.settings = (
        await this.$axios({
          method: "get",
          url: "/settings",
          auth: this.credentials,
        })
      ).data.response;
      this.cacheData = this.settings.map((item) => ({ ...item }));
    },
    handleChange(value, key, column) {
      const newData = [...this.settings];
      const target = newData.filter((item) => key === item.name)[0];
      if (target) {
        target[column] = value;
        this.settings = newData;
      }
    },
    edit(key) {
      const newData = [...this.settings];
      const target = newData.filter((item) => key === item.name)[0];
      this.editingKey = key;
      if (target) {
        target.editable = true;
        this.settings = newData;
      }
    },
    save(key) {
      const newData = [...this.settings];
      const newCacheData = [...this.cacheData];
      const target = newData.filter((item) => key === item.name)[0];
      const targetCache = newCacheData.filter((item) => key === item.name)[0];
      if (target && targetCache) {
        delete target.editable;
				this.sendSetting({key, data: target})
				.then((res) => {
					if (res.data.response == 1) {
						this.$message.success("Success");
						this.settings = newData;
						Object.assign(targetCache, target);
						this.cacheData = newCacheData;
					} else {
						throw res;
					}
				})
				.catch((err) => {
          this.cancel(key);
					console.error(err);
					this.$message.error("Fail");
				});
			}
      this.editingKey = "";
    },
    cancel(key) {
      const newData = [...this.settings];
      const target = newData.filter((item) => key === item.name)[0];
      this.editingKey = "";
      if (target) {
        Object.assign(
          target,
          this.cacheData.filter((item) => key === item.name)[0]
        );
        delete target.editable;
        this.settings = newData;
      }
    },
		sendSetting({key, data}){
			return new Promise((resolve, reject) => {
				this.$axios({
          method: "post",
          url: `/settings${key ? "/" + key : ''}`,
          auth: this.credentials,
          data: data,
        })
          .then(resolve)
          .catch(reject);
			})
		},
		sendNewSetting(){
			for (const field in this.addSetting.data) {
				if(this.addSetting.data[field].length == 0){
					console.log(field);
					console.log(this.addSetting.data[field]);
					this.$message.error("All fields are required!");
					return;
				}
			}

			this.addSetting.loading = true;
			this.sendSetting({data: this.addSetting.data})
			.then(() => {
				this.addSettingInit();
				this.sync();
				this.$message.success("Success");
			})
			.catch(()=> {
				this.addSetting.loading = false;
				this.$message.error("Fail");
			})
		},
		deleteField(recordName){
			if(recordName !== this.deletingFieldNameSecurity || this.deletingFieldNameSecurity == 'removethefkngfield'){
				this.$message.error('wrong field name');
				return;
			}

			console.log(object);
			this.$axios({
				method: "delete",
				url: `/settings/${recordName}`,
				auth: this.credentials,
			})
				.then((res) => {
					if(res.data.response > 0){
						this.sync();
						this.$message.success("Success");
					} else {
						throw res
					}
				})
				.catch((err) => {
					console.error(err);
					this.$message.success("Failed");
				});
		}
  },
};
</script>


<style >
.view__container{
	padding: 10px 20px;
}

.view__buttons{
	margin-bottom: 10px;
}

.add-setting__info-row:not(:last-of-type){
	margin-bottom: 15px;
}
</style>