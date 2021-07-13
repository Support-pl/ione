<template>
  <a-drawer
    title="Add VLANs range"
    :visible="visible"
    width="60%"
    @close="$emit('close')"
  >
    <a-form-model
      :model="vlan_pool"
      :label-col="{ span: 6 }"
      :wrapper-col="{ span: 18 }"
      :rules="rules"
      ref="createForm"
    >
      <a-form-model-item label="Type(VN MAD)" has-feedback>
        <a-select
          v-model="vlan_pool.type"
          placeholder="Please select network type"
        >
          <a-select-option :key="type" :value="type" v-for="type in vn_mads">
            {{ type }}
          </a-select-option>
        </a-select>
      </a-form-model-item>

      <a-form-model-item label="Start ID" has-feedback>
        <a-row :gutter="10">
          <a-col :span="18">
            <a-slider v-model="vlan_pool.start" :min="0" :max="4095" />
          </a-col>
          <a-col :span="6">
            <a-input-number
              v-model="vlan_pool.start"
              :min="0"
              :max="4095"
              style="marginleft: 16px"
            />
          </a-col>
        </a-row>
      </a-form-model-item>

      <a-form-model-item label="Size" has-feedback>
        <a-row :gutter="10">
          <a-col :span="18">
            <a-slider v-model="vlan_pool.size" :min="0" :max="4096" />
          </a-col>
          <a-col :span="6">
            <a-input-number
              v-model="vlan_pool.size"
              :min="0"
              :max="4096"
              style="marginleft: 16px"
            />
          </a-col>
        </a-row>
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
      <a-button type="primary" @click="save"> Create </a-button>
    </div>
  </a-drawer>
</template>

<script>
const vn_mads = ["802.1Q", "dummy", "bridge", "vcenter"];

export default {
  name: "vlan-pool-create",
  props: {
    visible: {
      required: true,
      type: Boolean,
    },
  },
  computed: {
    max_size() {
      return 4096 - this.vlan_pool.start;
    },
  },
  watch: {
    vlan_pool: {
      handler() {
        if (this.vlan_pool.size + this.vlan_pool.start > 4096)
          this.vlan_pool.size = 4096 - this.vlan_pool.start;
      },
      deep: true,
    },
  },
  data() {
    return {
      vlan_pool: {
        type: undefined,
        start: 0,
        size: 4096,
      },

      rules: {
        type: [{ required: true, message: "We can't go without it!" }],
      },
      vn_mads,
    };
  },
  methods: {
    save() {
      this.$emit("save", this.vlan_pool);
    },
  },
};
</script>
