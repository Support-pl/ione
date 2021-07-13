<template>
  <div>
    <a-switch :checked="value.body === 'TRUE'" :disabled="true"></a-switch>
  </div>
</template>

<script>
export default {
  name: "settingsBOOL",
  props: ["value"],
};
</script>