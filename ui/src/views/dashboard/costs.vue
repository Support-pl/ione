<template>
  <a-row
    type="flex"
    justify="space-around"
    style="margin-top: 1rem; max-width: 720px"
  >
    <a-col :span="23" v-if="!loading">
      <a-row>
        <a-col>
          <a-collapse
            :active-key="[
              'capacity',
              'drives',
              'public_ip',
              'snapshot',
              'traffic',
            ]"
          >
            <a-collapse-panel key="capacity" header="Capacity costs">
              <a-row style="margin-bottom: 10px">
                <a-col :span="2"> CPU </a-col>
                <a-col :span="20">
                  <a-input v-model="cpu.cost">
                    <a-select slot="addonAfter" v-model="cpu.unit">
                      <a-select-option
                        :value="unit"
                        v-for="unit in Object.keys(t_units)"
                        :key="unit"
                      >
                        1 Core / {{ unit }}
                      </a-select-option>
                    </a-select>
                  </a-input>
                </a-col>
              </a-row>
              <a-row>
                <a-col :span="2"> RAM </a-col>
                <a-col :span="20">
                  <a-input v-model="ram.cost">
                    <div slot="addonAfter">
                      <a-select v-model="ram.s_unit">
                        <a-select-option key="mb" value="mb"
                          >MB</a-select-option
                        >
                        <a-select-option key="gb" value="gb"
                          >GB</a-select-option
                        >
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
                </a-col>
              </a-row>
            </a-collapse-panel>
            <a-collapse-panel
              key="drives"
              header="Drives costs"
              v-if="Object.keys(drive).length > 0"
            >
              <a-tooltip
                slot="extra"
                v-if="DiskTyepsWithNoCost.length > 0"
                placement="topRight"
              >
                <template slot="title">
                  Some disk types don't have prices set
                </template>
                <a-icon type="warning" style="color: #ff7600" />
              </a-tooltip>
              <a-row
                v-for="[type, data] in Object.entries(drive.types)"
                :key="type"
                :gutter="10"
                style="margin-bottom: 10px"
              >
                <a-col :span="2"
                  ><a-row type="flex" align="middle">{{ type }} </a-row></a-col
                >
                <a-col :span="20">
                  <a-input v-model="data.cost">
                    <div slot="addonAfter">
                      <a-select v-model="drive.s_unit">
                        <a-select-option key="mb" value="mb"
                          >MB</a-select-option
                        >
                        <a-select-option key="gb" value="gb"
                          >GB</a-select-option
                        >
                      </a-select>
                      /
                      <a-select v-model="drive.t_unit">
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
                </a-col>
                <a-col :span="2">
                  <a-button
                    type="danger"
                    icon="delete"
                    @click="() => $delete(drive.types, type)"
                  />
                </a-col>
              </a-row>
              <a-row :gutter="10">
                <a-col :span="8"
                  ><a-row type="flex" align="middle"
                    >Enter New Drive Type
                  </a-row></a-col
                >
                <a-col :span="14">
                  <a-input v-model="new_drive_type"> </a-input>
                </a-col>
                <a-col :span="2">
                  <a-button
                    type="primary"
                    icon="save"
                    @click="
                      () =>
                        $set(drive.types, new_drive_type, { base: 0, cost: 0 })
                    "
                  />
                </a-col>
              </a-row>
              <a-row v-if="DiskTyepsWithNoCost.length > 0">
                <span class="warning">
                  <a-icon type="warning" />
                  WARNING:
                </span>
                You don't have prices to following disk types:
                <template v-for="(type, index) in DiskTyepsWithNoCost">
                  <span
                    :key="type"
                    class="diskTypeToClick"
                    @click="() => $set(drive.types, type, { base: 0, cost: 0 })"
                  >
                    {{ type }}
                  </span>
                  {{ index == DiskTyepsWithNoCost.length - 1 ? "." : ", " }}
                </template>
              </a-row>
            </a-collapse-panel>
            <a-collapse-panel key="public_ip" header="Public IP Cost">
              <a-row>
                <a-col :span="20">
                  <a-input v-model="ip.cost">
                    <a-select slot="addonAfter" v-model="ip.unit">
                      <a-select-option
                        :value="unit"
                        v-for="unit in Object.keys(t_units)"
                        :key="unit"
                      >
                        1 Address / {{ unit }}
                      </a-select-option>
                    </a-select>
                  </a-input>
                </a-col>
              </a-row>
            </a-collapse-panel>
            <a-collapse-panel key="snapshot" header="Snapshot Cost">
              <a-row>
                <a-col :span="20">
                  <a-input v-model="snap.cost">
                    <a-select slot="addonAfter" v-model="snap.unit">
                      <a-select-option
                        :value="unit"
                        v-for="unit in Object.keys(t_units)"
                        :key="unit"
                      >
                        1 Snapshot / {{ unit }}
                      </a-select-option>
                    </a-select>
                  </a-input>
                </a-col>
              </a-row>
            </a-collapse-panel>
            <a-collapse-panel key="traffic" header="Traffic Cost">
              <a-row>
                <a-col :span="20">
                  <a-input v-model="traff.cost">
                    <div slot="addonAfter">
                      <a-select v-model="traff.s_unit">
                        <a-select-option key="kb" value="kb"
                          >kB</a-select-option
                        >
                        <a-select-option key="mb" value="mb"
                          >MB</a-select-option
                        >
                        <a-select-option key="gb" value="gb"
                          >GB</a-select-option
                        >
                      </a-select>
                      /
                      <a-select v-model="traff.t_unit">
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
                </a-col>
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

export default {
  name: "cost",
  data() {
    return {
      t_units: {
        sec: { div: 1 },
        min: { div: 60 },
        hour: { div: 3600 },
        day: { div: 86400 },
      },
      s_units: {
        kb: { div: 0.000001 },
        mb: { div: 0.001 },
        gb: { div: 1 },
      },

      fullSettings: {},
      settings: {},
      loading: true,

      cpu: {},
      ram: {},
      drive: {},
      new_drive_type: "",
      ip: {},
      snap: {},
      traff: {},
    };
  },
  computed: {
    ...mapGetters(["credentials"]),
    DISK_TYPES() {
      return this.fullSettings
        .find((el) => el.name == "DISK_TYPES")
        .body.split(",");
    },
    DISK_COSTS_KEYS() {
      return Object.keys(this.drive.types);
    },
    DiskTyepsWithNoCost() {
      return this.DISK_TYPES.filter((el) => !this.DISK_COSTS_KEYS.includes(el));
    },
  },
  watch: {
    cpu: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val || !val.unit) return;
        if (val.prev_unit != val.unit) {
          this.cpu.cost = this.convertByTimeTo(val.base, val.unit);
          this.cpu.prev_unit = val.unit;
        } else this.cpu.base = this.convertByTimeFrom(val.cost, val.unit);
      },
    },
    ram: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val || !val.t_unit || !val.s_unit) return;
        if (val.prev_s_unit != val.s_unit || val.prev_t_unit != val.t_unit) {
          this.ram.cost = this.convertBySizeTo(
            this.convertByTimeTo(val.base, val.t_unit),
            val.s_unit
          );
          this.ram.prev_s_unit = val.s_unit;
          this.ram.prev_t_unit = val.t_unit;
        } else
          this.ram.base = this.convertBySizeFrom(
            this.convertByTimeFrom(val.cost, val.t_unit),
            val.s_unit
          );
      },
    },
    drive: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val || !val.t_unit || !val.s_unit) return;
        if (val.prev_s_unit != val.s_unit || val.prev_t_unit != val.t_unit) {
          for (let type of Object.keys(val.types)) {
            this.drive.types[type].cost = this.convertBySizeTo(
              this.convertByTimeTo(this.drive.types[type].base, val.t_unit),
              val.s_unit
            );
          }
          this.drive.prev_s_unit = val.s_unit;
          this.drive.prev_t_unit = val.t_unit;
        } else {
          for (let type of Object.keys(val.types)) {
            this.drive.types[type].base = this.convertBySizeFrom(
              this.convertByTimeFrom(this.drive.types[type].cost, val.t_unit),
              val.s_unit
            );
          }
        }
      },
    },
    ip: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val || !val.unit) return;
        if (val.prev_unit != val.unit) {
          this.ip.cost = this.convertByTimeTo(val.base, val.unit);
          this.ip.prev_unit = val.unit;
        } else this.ip.base = this.convertByTimeFrom(val.cost, val.unit);
      },
    },
    snap: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val || !val.unit) return;
        if (val.prev_unit != val.unit) {
          this.snap.cost = this.convertByTimeTo(val.base, val.unit);
          this.snap.prev_unit = val.unit;
        } else this.snap.base = this.convertByTimeFrom(val.cost, val.unit);
      },
    },
    traff: {
      deep: true,
      immediate: true,
      handler(val) {
        if (!val || !val.t_unit || !val.s_unit) return;
        if (val.prev_s_unit != val.s_unit || val.prev_t_unit != val.t_unit) {
          this.traff.cost = this.convertBySizeTo(
            this.convertByTimeTo(val.base, val.t_unit),
            val.s_unit
          );
          this.traff.prev_s_unit = val.s_unit;
          this.traff.prev_t_unit = val.t_unit;
        } else
          this.traff.base = this.convertBySizeFrom(
            this.convertByTimeFrom(val.cost, val.t_unit),
            val.s_unit
          );
      },
    },
  },
  methods: {
    async sync() {
      this.fullSettings = (
        await this.$axios({
          method: "get",
          url: "/settings",
          auth: this.credentials,
        })
      ).data.response;
      let settings_array = this.fullSettings
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
        base: this.settings.CAPACITY_COST.value.CPU_COST,
        orig: this.settings.CAPACITY_COST.value.CPU_COST,
        cost: this.settings.CAPACITY_COST.value.CPU_COST,
        unit: "sec",
        prev_unit: "sec",
      };

      this.ram = {
        base: parseFloat(this.settings.CAPACITY_COST.value.MEMORY_COST),
        orig: parseFloat(this.settings.CAPACITY_COST.value.MEMORY_COST),
        cost: this.settings.CAPACITY_COST.value.MEMORY_COST,
        s_unit: "gb",
        prev_s_unit: "gb",
        t_unit: "sec",
        prev_t_unit: "sec",
      };

      let drive = {
        s_unit: "gb",
        prev_s_unit: "gb",
        t_unit: "sec",
        prev_t_unit: "sec",
        types: this.settings.DISK_COSTS.value,
      };
      for (let [type, orig] of Object.entries(drive.types)) {
        drive.types[type] = {
          base: parseFloat(orig),
          orig: parseFloat(orig),
          cost: orig,
        };
      }
      this.drive = drive;

      this.ip = {
        base: parseFloat(this.settings.PUBLIC_IP_COST.body),
        orig: parseFloat(this.settings.PUBLIC_IP_COST.body),
        cost: parseFloat(this.settings.PUBLIC_IP_COST.body),
        unit: "sec",
        prev_unit: "sec",
      };

      this.snap = {
        base: parseFloat(this.settings.SNAPSHOT_COST.body),
        orig: parseFloat(this.settings.SNAPSHOT_COST.body),
        cost: parseFloat(this.settings.SNAPSHOT_COST.body),
        unit: "sec",
        prev_unit: "sec",
      };

      this.traff = {
        base: parseFloat(this.settings.TRAFFIC_COST.body),
        orig: parseFloat(this.settings.TRAFFIC_COST.body),
        cost: parseFloat(this.settings.TRAFFIC_COST.body),
        s_unit: "kb",
        prev_s_unit: "kb",
        t_unit: "sec",
        prev_t_unit: "sec",
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
      return val * this.t_units[to].div;
    },
    convertByTimeFrom(val, from) {
      // val - value for seconds, from - unit to convert from
      return val / this.t_units[from].div;
    },
    convertBySizeTo(val, to) {
      return val * this.s_units[to].div;
    },
    convertBySizeFrom(val, from) {
      return val / this.s_units[from].div;
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

<style>
.warning {
  color: #ff7600;
}
.warning i {
  font-size: 1.2rem;
}
.diskTypeToClick {
  color: #8649ff;
  cursor: pointer;
}
.diskTypeToClick:hover {
  text-decoration: underline;
}
</style>