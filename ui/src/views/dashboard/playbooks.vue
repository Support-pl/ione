<template>
  <a-row
    type="flex"
    justify="space-around"
    style="margin-top: 1rem; max-width: 720px"
  >
    <a-col :span="23">
      <a-row>
        <a-col :span="6">
          <a-button type="primary" icon="plus" @click="create"
            >Add Playbook</a-button
          >
          <playbook-editor
            :editable="editable"
            :visible="edit_visible"
            @save="
              sync();
              handleEditorClose();
            "
            @close="handleEditorClose"
          />
        </a-col>
        <a-col :span="2">
          <a-button type="primary" icon="redo" @click="sync"></a-button>
        </a-col>
      </a-row>
      <a-row style="margin-top: 15px">
        <a-col :span="24">
          <a-table :columns="columns" :data-source="pool" row-key="id">
            <span slot="action" slot-scope="text, record">
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
            </span>
          </a-table>
        </a-col>
      </a-row>

      <a-modal
        :visible="access_editor_visible"
        title="Edit permissions"
        okText="Submit"
        @ok="save_access"
        @cancel="handleAccessEditorClose"
      >
        <a-row type="flex" justify="space-between">
          <a-col :span="9">
            <a-row><span>---</span></a-row>
            <a-row><span>Owner</span></a-row>
            <a-row><span>Group</span></a-row>
            <a-row><span>Others</span></a-row>
          </a-col>
          <a-col :span="5">
            <a-row> <span>Use</span> </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[0]"
                @change="(e) => updateChecked(e, 0)"
              />
            </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[1]"
                @change="(e) => updateChecked(e, 1)"
              />
            </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[2]"
                @change="(e) => updateChecked(e, 2)"
              />
            </a-row>
          </a-col>
          <a-col :span="5">
            <a-row> <span>Manage</span> </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[3]"
                @change="(e) => updateChecked(e, 3)"
              />
            </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[4]"
                @change="(e) => updateChecked(e, 4)"
              />
            </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[5]"
                @change="(e) => updateChecked(e, 5)"
              />
            </a-row>
          </a-col>
          <a-col :span="5">
            <a-row> <span>Admin</span> </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[6]"
                @change="(e) => updateChecked(e, 6)"
              />
            </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[7]"
                @change="(e) => updateChecked(e, 7)"
              />
            </a-row>
            <a-row>
              <a-checkbox
                :checked="permissions[8]"
                @change="(e) => updateChecked(e, 8)"
              />
            </a-row>
          </a-col>
        </a-row>
      </a-modal>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

import PlaybookEditor from "@/components/playbook/editor.vue";

export default {
  components: {
    PlaybookEditor,
  },
  data() {
    return {
      editable: {},
      edit_visible: false,

      pool: [],

      access_editable: {},
      access_editor_visible: false,

      columns: [
        {
          dataIndex: "id",
          key: "id",
          title: "ID",
        },
        {
          dataIndex: "name",
          key: "name",
          title: "Name",
        },
        {
          dataIndex: "uname",
          key: "uname",
          title: "Owner",
        },
        {
          dataIndex: "gname",
          key: "gname",
          title: "Group",
        },
        {
          title: "Actions",
          key: "action",
          scopedSlots: { customRender: "action" },
        },
      ],
    };
  },
  computed: {
    permissions() {
      if (!this.access_editable.permissions) return [];
      return this.access_editable.permissions
        .split("")
        .map((e) => (e == "1" ? true : false));
    },
    ...mapGetters(["credentials"]),
  },
  methods: {
    sync() {
      this.$axios({
        method: "get",
        url: "/ansible",
        auth: this.credentials,
      }).then((res) => (this.pool = res.data.response));
    },
    create() {
      this.editable = {
        body:
          " - hosts: <%group%> # Don't delete or edit this line. Playbook won't be saved or executed without it\n",
        extra_data: {
          PERMISSIONS: "111000000",
        },
      };
      this.edit_visible = true;
    },
    edit(record) {
      this.editable = record;
      this.edit_visible = true;
    },
    remove(id) {
      this.$axios({
        method: "delete",
        url: "/ansible/" + id,
        auth: this.credentials,
      }).then(() => {
        this.$notification.success({
          message: `Ansible Playbook(ID: ${id}) successfuly deleted`,
        });
        this.sync();
      });
    },
    handleEditorClose() {
      this.edit_visible = false;
      this.editable = {};
    },

    save_access() {
      this.$axios({
        method: "post",
        url: `/ansible/${this.access_editable.id}/action`,
        auth: this.credentials,
        data: {
          action: {
            perform: "update",
            params: {
              extra_data: { PERMISSIONS: this.access_editable.permissions },
            },
          },
        },
      }).then(() => {
        this.$notification.success({
          message: "Success",
          description: "Permissions updated successfuly",
        });
        this.handleAccessEditorClose();
        this.sync();
      });
    },
    edit_access(record) {
      this.access_editable = {
        id: record.id,
        permissions: record.extra_data.PERMISSIONS,
      };
      this.access_editor_visible = true;
    },
    updateChecked(e, num) {
      let p = this.permissions;
      p[num] = e.target.checked;
      this.$set(
        this.access_editable,
        "permissions",
        p.map((e) => (e ? "1" : "0")).join("")
      );
    },
    handleAccessEditorClose() {
      this.access_editor_visible = false;
      this.access_editable = {};
    },
  },
  mounted() {
    this.$store.dispatch("sync_user_pool");
    this.$store.dispatch("sync_group_pool");
    this.sync();
  },
};
</script>