<template>
  <div class="xml-editor">
    <textarea ref="textarea" readonly />
  </div>
</template>

<script>
import CodeMirror from "codemirror";
import "codemirror/addon/lint/lint.css";
import "codemirror/lib/codemirror.css";
import "codemirror/theme/monokai.css";
import "codemirror/mode/xml/xml";
import "codemirror/addon/lint/lint";

export default {
  name: "xml-viewer",
  // eslint-disable-next-line vue/require-prop-types
  props: ["value"],
  data() {
    return {
      xmlViewer: false,
    };
  },
  watch: {
    value(value) {
      const editorValue = this.xmlViewer.getValue();
      if (value !== editorValue) {
        this.xmlViewer.setValue(this.value);
      }
    },
  },
  mounted() {
    this.xmlViewer = CodeMirror.fromTextArea(this.$refs.textarea, {
      lineNumbers: true, // display line number
      mode: "application/xml", // grammar model
      gutters: ["CodeMirror-lint-markers"], // Syntax checker
      theme: "monokai", // Editor theme
      lint: true, // Turn on grammar checking
    });

    this.xmlViewer.setValue(this.value);

    // I'm sorry for these two lines, really
    let editor = this.xmlViewer;
    setTimeout(() => editor.refresh(), 10);

    this.xmlViewer.on("change", (cm) => {
      this.$emit("changed", cm.getValue());
      this.$emit("input", cm.getValue());
    });
  },
  methods: {
    getValue() {
      return this.xmlViewer.getValue();
    },
  },
};
</script>

<style scoped>
.xml-editor {
  height: 100%;
  position: relative;
}
.xml-editor >>> .CodeMirror {
  height: auto;
  min-height: 300px;
}
.xml-editor >>> .CodeMirror-scroll {
  min-height: 300px;
}
.xml-editor >>> .cm-s-rubyblue span.cm-string {
  color: #f08047;
}
</style>