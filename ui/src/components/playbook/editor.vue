<template>
  <a-drawer
    :title="`${editable.id ? 'Edit' : 'Add'} Playbook`"
    :visible="visible"
    width="50%"
    @close="$emit('close')"
  >
    <a-form-model :model="editable" :rules="rules" ref="editorForm">
      <a-row :gutter="10">
        <a-col :span="12">
          <a-form-model-item label="Title" has-feedback prop="name">
            <a-input
              v-model="editable.name"
              placeholder="Playbook name"
            ></a-input>
          </a-form-model-item>
        </a-col>
        <a-col :span="6">
          <a-form-model-item label="User" has-feedback prop="uid">
            <a-select
              show-search
              placeholder="Select an user"
              :options="
                users.map((el) => {
                  return { value: el.id, label: el.name };
                })
              "
              option-filter-prop="children"
              :filter-option="filterOption"
              v-model="editable.uid"
            >
            </a-select>
          </a-form-model-item>
        </a-col>
        <a-col :span="6">
          <a-form-model-item label="Group" has-feedback prop="gid">
            <a-select
              show-search
              placeholder="Select a group"
              v-model="editable.gid"
              :options="
                groups.map((el) => {
                  return { value: el.id, label: el.name };
                })
              "
              option-filter-prop="children"
              :filter-option="filterOption"
            >
            </a-select>
          </a-form-model-item>
        </a-col>
      </a-row>
      <a-row :gutter="10">
        <a-col :span="16">
          <a-form-model-item label="Description" prop="description">
            <a-input v-model="editable.description" type="textarea"></a-input>
          </a-form-model-item>
        </a-col>
        <a-col :span="8">
          <a-form-model-item label="Supported OS">
            <template v-for="tag of editable.tags">
              <a-tag
                :key="tag"
                :closable="true"
                @close="() => handleTagClose(tag)"
                :color="randomColor()"
              >
                {{ tag }}
              </a-tag>
            </template>
            <a-input
              ref="input"
              type="text"
              size="small"
              :style="{ width: '78px' }"
              :value="tagInputValue"
              @change="handleTagInputChange"
              @blur="handleTagInputConfirm"
              @keyup.enter="handleTagInputConfirm"
              placeholder="New tag"
            />
          </a-form-model-item>
        </a-col>
      </a-row>
      <a-form-model-item label="Body" prop="body">
        <yaml-editor v-model="editable.body" />
      </a-form-model-item>
    </a-form-model>

    <div
      :style="{
        position: 'absolute',
        right: 0,
        bottom: 0,
        width: '100%',
        borderTop: '1px solid #e9e9e9',
        padding: '10px 16px',
        background: '#fff',
        textAlign: 'right',
        zIndex: 1,
      }"
    >
      <a-button :style="{ marginRight: '8px' }" @click="$emit('close')">
        Cancel
      </a-button>
      <a-button type="primary" @click="save"> Submit </a-button>
    </div>
  </a-drawer>
</template>

<script>
import { mapGetters } from "vuex";

import yamlEditor from "./yaml-editor";

export default {
  name: "playbook-editor",
  components: {
    yamlEditor,
  },
  props: {
    visible: {
      required: true,
      default: false,
    },
    editable: {
      required: true,
      type: Object,
    },
  },
  computed: {
    ...mapGetters(["credentials", "users", "groups"]),
  },
  data() {
    return {
      tagInputValue: "",
      rules: {
        name: [{ required: true, message: "Please input new Playbook name" }],
        uid: [{ required: true, message: "Select Owner User" }],
        gid: [{ required: true, message: "Select Owner Group" }],
        body: [{ required: true }],
      },
    };
  },
  methods: {
    save() {
      let vm = this;
      vm.$refs.editorForm.validate((valid) => {
        if (valid) {
          vm.$axios({
            method: "post",
            auth: vm.credentials,
            url: "/ansible",
            data: vm.editable,
          }).then((res) => {
            vm.$notification.success({
              message: "Successs",
              description: `Ansible Playbook(ID:${res.data.response.ANSIBLE.ID}) successfuly created`,
            });
            vm.$emit("save");
          });
        } else {
          return false;
        }
      });
    },

    filterOption(input, option) {
      return (
        option.componentOptions.children[0].text
          .toLowerCase()
          .indexOf(input.toLowerCase()) >= 0
      );
    },

    randomColor() {
      let letters = "0123456789ABCDEF";
      let color = "#";
      for (let i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
      }
      return color;
    },
    handleTagClose(removedTag) {
      const tags = this.editable.tags.filter((tag) => tag !== removedTag);
      this.$set(this.editable, "tags", tags);
    },
    handleTagInputChange(e) {
      this.tagInputValue = e.target.value;
    },
    handleTagInputConfirm() {
      const inputValue = this.tagInputValue;
      let tags = this.editable.tags;
      if (inputValue && tags.indexOf(inputValue) === -1) {
        tags = [...tags, inputValue];
      }

      this.$set(this.editable, "tags", tags);
      this.tagInputValue = "";
    },
  },
};
</script>