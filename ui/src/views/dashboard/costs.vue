<template>
  <a-row type="flex" justify="space-around" style="margin-top: 1rem">
    <a-col :span="23" v-if="!loading">
      <a-row>
        <a-col>
          <a-collapse>
            <a-collapse-panel key="capacity" header="Capacity costs">
              <a-row>
                CPU
                <a-input v-model="cpu.cost">
                  <a-select slot="addonAfter" v-model="cpu.unit">
                    <a-select-option
                      :value="unit"
                      v-for="unit in Object.keys(t_units)"
                      :key="unit"
                    >
                      Core / {{ unit }}
                    </a-select-option>
                  </a-select>
                </a-input>
              </a-row>
              <a-row>
                RAM
                <a-input v-model="ram.cost">
                  <div slot="addonAfter">
                    <a-select v-model="ram.s_unit">
                      <a-select-option key="mb" value="mb">MB</a-select-option>
                      <a-select-option key="gb" value="gb">GB</a-select-option>
                    </a-select>
                    /
                    <a-select v-model="ram.t_unit">
                      <a-select-option
                        :value="unit"
                        v-for="unit in Object.keys(t_units)"
                        :key="unit"
                      >
                        {{ unit }}
                      </a-select-option>
                    </a-select>
                  </div>
                </a-input>
              </a-row>
            </a-collapse-panel>
          </a-collapse>
        </a-col>
      </a-row>
    </a-col>
  </a-row>
</template>

<script>
import { mapGetters } from "vuex";

const t_units = {
  sec: { div: 1 },
  min: { div: 60 },
  hour: { div: 3600 },
  day: { div: 86400 },
};
const s_units = {
  mb: { div: 1 },
  gb: { div: 1000 },
};

export default {
  name: "cost",
  data() {
    return {
      settings: {},
      loading: true,

      disks_costs: {},

      cpu: {},
      ram: {},

      t_units,
      s_units,
    };
  },
  computed: {
    ...mapGetters(["credentials"]),
  },
  watch: {
    cpu: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val) return;
        this.cpu.cost = this.convertByTimeTo(val.orig, val.unit);
      },
    },
    ram: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val) return;
        this.ram.cost = this.convertBySizeTo(
          this.convertByTimeTo(val.orig, val.t_unit),
          val.s_unit
        );
      },
    },
  },
  methods: {
    async sync() {
      let settings_array = (
        await this.$axios({
          method: "get",
          url: "/settings",
          auth: this.credentials,
        })
      ).data.response
        .filter((element) => element.name.includes("_COST"))
        .map((item) => {
          if (
            this.isJson(item.body) &&
            (~item.body.indexOf("[") || ~item.body.indexOf("{"))
          ) {
            item.value = JSON.parse(item.body);
          }
          return item;
        });
      this.settings = {};
      for (let rec of settings_array) {
        this.settings[rec.name] = rec;
      }

      this.cpu = {
        orig: this.settings.CAPACITY_COST.value.CPU_COST,
        cost: this.settings.CAPACITY_COST.value.CPU_COST,
        unit: "sec",
      };

      this.ram = {
        orig: this.settings.CAPACITY_COST.value.MEMORY_COST,
        cost: this.settings.CAPACITY_COST.value.MEMORY_COST,
        s_unit: "gb",
        t_unit: "sec",
      };

      this.loading = false;
    },

    isJson(str) {
      try {
        JSON.parse(str);
      } catch (e) {
        return false;
      }
      return true;
    },
    convertByTimeTo(val, to) {
      // val - value for seconds, to - unit to convert to
      return val * t_units[to].div;
    },
    convertByTimeFrom(val, from) {
      // val - value for seconds, from - unit to convert from
      return val / t_units[from].div;
    },
    convertBySizeTo(val, to) {
      return val / s_units[to].div;
    },
    convertBySizeFrom(val, from) {
      return val * s_units[from].div;
    },
  },
  mounted() {
    this.sync();
  },
  filters: {
    fieldName(value) {
      if (!value) return "";
      return value.toString().replace(/_/g, " ");
    },
  },
};
</script>