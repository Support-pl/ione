<template>
  <div>
    <a-row
      v-if="this.record.vars && this.record.vars != '{}'"
      style="margin-bottom: 10px"
    >
      <h1>Vars:</h1>
      <span v-for="(val, key) in JSON.parse(this.record.vars)" :key="key"
        ><h3>{{ key }} = {{ val }}</h3></span
      >
    </a-row>
    <a-row>
      <h1>Runnable</h1>
      <br />
      <textarea id="runnable-view" readonly v-model="runnable"> </textarea>
    </a-row>
  </div>
</template>

<script>
import CodeMirror from "codemirror";
import "codemirror/lib/codemirror.css";
import "codemirror/mode/yaml/yaml";
import "codemirror/theme/monokai.css";

export default {
  name: "process-execution-info-widget",
  props: {
    record: {
      required: true,
      type: Object,
    },
  },
  computed: {
    runnable() {
      return this.record.runnable;
    },
  },
  mounted() {
    CodeMirror.fromTextArea(document.getElementById("runnable-view"), {
      lineNumbers: true,
      mode: "text/x-yaml", // grammar model
      theme: "monokai", // Editor theme
    });
  },
};
</script>
<style>
.CodeMirror {
  min-height: 640px;
}
</style>