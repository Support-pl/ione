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
            <a-collapse-panel disabled key="capacity" header="Capacity costs">
              <a-row
                class="cost-panel-extra"
                slot="extra"
                :gutter="10"
                v-if="changed.includes('cpu') || changed.includes('ram')"
              >
                <a-col :span="12"
                  ><a-button
                    @click="(e) => e.preventDefault() || reset(['cpu', 'ram'])"
                    >Reset</a-button
                  ></a-col
                >
                <a-col :span="12"
                  ><a-button type="primary" @click="save(['capacity'])"
                    >Save</a-button
                  ></a-col
                >
              </a-row>
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
              disabled
              key="drives"
              header="Drives costs"
              v-if="Object.keys(drive).length > 0"
            >
              <a-row class="cost-panel-extra" slot="extra" :gutter="10">
                <a-col :span="12" v-if="drive.changed"
                  ><a-button
                    @click="(e) => e.preventDefault() || reset(['drive'])"
                    >Reset</a-button
                  ></a-col
                >
                <a-col :span="12" v-if="drive.changed"
                  ><a-button type="primary" @click="save(['drive'])"
                    >Save</a-button
                  ></a-col
                >
              </a-row>

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
              <a-row v-if="DiskTypesWithNoCost.length > 0">
                <span class="warning">
                  <a-icon type="warning" />
                  WARNING:
                </span>
                You don't have prices for following disk types:
                <template v-for="(type, index) in DiskTypesWithNoCost">
                  <span
                    :key="type"
                    class="diskTypeToClick"
                    @click="() => $set(drive.types, type, { base: 0, cost: 0 })"
                  >
                    {{ type }}
                  </span>
                  {{ index == DiskTypesWithNoCost.length - 1 ? "." : ", " }}
                </template>
              </a-row>
            </a-collapse-panel>
            <a-collapse-panel disabled key="public_ip" header="Public IP Cost">
              <a-row
                class="cost-panel-extra"
                slot="extra"
                :gutter="10"
                v-if="changed.includes('ip')"
              >
                <a-col :span="12"
                  ><a-button @click="(e) => e.preventDefault() || reset(['ip'])"
                    >Reset</a-button
                  ></a-col
                >
                <a-col :span="12"
                  ><a-button type="primary" @click="save(['ip'])"
                    >Save</a-button
                  ></a-col
                >
              </a-row>
              <a-row>
                <a-col :span="20">
                  <a-input v-model="ip.base">
                    <span slot="addonAfter"> 1 Address / month </span>
                  </a-input>
                </a-col>
              </a-row>
            </a-collapse-panel>
            <a-collapse-panel disabled key="snapshot" header="Snapshot Cost">
              <a-row
                class="cost-panel-extra"
                slot="extra"
                :gutter="10"
                v-if="changed.includes('snap')"
              >
                <a-col :span="12"
                  ><a-button
                    @click="(e) => e.preventDefault() || reset(['snap'])"
                    >Reset</a-button
                  ></a-col
                >
                <a-col :span="12"
                  ><a-button type="primary" @click="save(['snap'])"
                    >Save</a-button
                  ></a-col
                >
              </a-row>
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
            <a-collapse-panel disabled key="traffic" header="Traffic Cost">
              <a-row
                class="cost-panel-extra"
                slot="extra"
                :gutter="10"
                v-if="changed.includes('traff')"
              >
                <a-col :span="12"
                  ><a-button
                    @click="(e) => e.preventDefault() || reset(['traff'])"
                    >Reset</a-button
                  ></a-col
                >
                <a-col :span="12"
                  ><a-button type="primary" @click="save(['traff'])"
                    >Save</a-button
                  ></a-col
                >
              </a-row>
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
    DiskTypesWithNoCost() {
      return this.DISK_TYPES.filter((el) => !this.DISK_COSTS_KEYS.includes(el));
    },
    changed() {
      return ["cpu", "ram", "ip", "snap", "traff"].filter(
        (obj) => this[obj].base != this[obj].orig
      );
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
            if (this.drive.types[type].base != this.drive.types[type].orig)
              this.drive.changed = true;
          }
        }
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
        if (!val || !val.s_unit) return;
        if (val.prev_s_unit != val.s_unit) {
          this.traff.cost = this.convertBySizeTo(val.base, val.s_unit);
          this.traff.prev_s_unit = val.s_unit;
        } else this.traff.base = this.convertBySizeFrom(val.cost, val.s_unit);
      },
    },
  },
  methods: {
    async sync() {
      await this.syncSettings();

      this.reset(["cpu", "ram", "drive", "ip", "snap", "traff"]);

      this.loading = false;
    },
    async syncSettings() {
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
          try {
            item.value = JSON.parse(item.body);
            // eslint-disable-next-line no-empty
          } catch {}
          return item;
        });
      this.settings = {};
      for (let rec of settings_array) {
        this.settings[rec.name] = rec;
      }
    },
    reset(objects) {
      let reseters = {
        cpu: () => {
          return {
            base: this.settings.CAPACITY_COST.value.CPU_COST,
            orig: this.settings.CAPACITY_COST.value.CPU_COST,
            cost: this.settings.CAPACITY_COST.value.CPU_COST,
            unit: "sec",
            prev_unit: "sec",
          };
        },
        ram: () => {
          return {
            base: parseFloat(this.settings.CAPACITY_COST.value.MEMORY_COST),
            orig: parseFloat(this.settings.CAPACITY_COST.value.MEMORY_COST),
            cost: this.settings.CAPACITY_COST.value.MEMORY_COST,
            s_unit: "gb",
            prev_s_unit: "gb",
            t_unit: "sec",
            prev_t_unit: "sec",
          };
        },
        drive: () => {
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
          return drive;
        },
        ip: () => {
          return {
            base: parseFloat(this.settings.PUBLIC_IP_COST.body),
            orig: parseFloat(this.settings.PUBLIC_IP_COST.body),
          };
        },
        snap: () => {
          return {
            base: parseFloat(this.settings.SNAPSHOT_COST.body),
            orig: parseFloat(this.settings.SNAPSHOT_COST.body),
            cost: parseFloat(this.settings.SNAPSHOT_COST.body),
            unit: "sec",
            prev_unit: "sec",
          };
        },
        traff: () => {
          return {
            base: parseFloat(this.settings.TRAFFIC_COST.body),
            orig: parseFloat(this.settings.TRAFFIC_COST.body),
            cost: parseFloat(this.settings.TRAFFIC_COST.body),
            s_unit: "gb",
            prev_s_unit: "gb",
          };
        },
      };
      for (let obj of objects) {
        this[obj] = reseters[obj]();
      }
    },
    async save(objects) {
      let modifiers = {
        capacity: () => {
          return {
            r: ["cpu", "ram"],
            d: {
              CAPACITY_COST: {
                body: JSON.stringify({
                  CPU_COST: this.cpu.base,
                  MEMORY_COST: this.ram.base,
                }),
              },
            },
          };
        },
        drive: () => {
          let res = {};
          for (let [type, data] of Object.entries(this.drive.types)) {
            res[type] = data.base;
          }
          return {
            r: ["drive"],
            d: {
              DISK_COSTS: {
                body: JSON.stringify(res),
              },
            },
          };
        },
        ip: () => {
          return {
            r: ["ip"],
            d: {
              PUBLIC_IP_COST: {
                body: this.ip.base,
              },
            },
          };
        },
        snap: () => {
          return {
            r: ["snap"],
            d: {
              SNAPSHOT_COST: {
                body: JSON.stringify(this.snap.base),
              },
            },
          };
        },
        traff: () => {
          return {
            r: ["traff"],
            d: {
              TRAFFIC_COST: {
                body: JSON.stringify(this.traff.base),
              },
            },
          };
        },
      };
      let changes = {};
      let resets = [];
      for (let obj of objects) {
        let r = modifiers[obj]();
        changes = { ...changes, ...r.d };
        resets = [...resets, ...r.r];
      }
      let promises = [];
      for (let [key, body] of Object.entries(changes)) {
        promises.push(
          this.$axios({
            method: "post",
            url: `/settings/${key}`,
            auth: this.credentials,
            data: body,
          })
        );
      }
      await Promise.all(promises);
      await this.syncSettings();
      this.reset(resets);
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
.cost-panel-extra button.ant-btn {
  height: 24px;
  width: 72px;
}
.ant-collapse > .ant-collapse-item > .ant-collapse-header {
  color: rgba(0, 0, 0, 0.85) !important;
}
</style>