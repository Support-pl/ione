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
            @close="handleEditorClose"
          />
        </a-col>
      </a-row>
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
    };
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  methods: {
    sync() {
      this.$axios({
        method: "get",
        url: "/ansible",
        auth: this.credentials,
      }).then((res) => (this.pool = res.data.ANSIBLE_POOL.ANSIBLE));
    },
    create() {
      console.log("create clicked");
      this.editable = {
        body:
          " - hosts: <%group%> # Don't delete or edit this line. Playbook won't be saved or executed without it\n",
      };
      this.edit_visible = true;
    },
    handleEditorClose() {
      this.edit_visible = false;
      this.editable = {};
    },
  },
  mounted() {
    this.$store.dispatch("sync_user_pool");
    this.$store.dispatch("sync_group_pool");
    this.sync();
  },
};
</script>