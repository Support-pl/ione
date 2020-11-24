<template>
  <a-row type="flex" justify="space-around" style="margin-top: 150px">
    <a-col :span="12">
      <a-row type="flex" justify="space-around">
        <img src="/ione_logo.png" style="max-height: 8rem; max-width: 16rem" />
      </a-row>
      <a-row type="flex" justify="space-around">
        <h3>Hello, World! via IONe Web API</h3>
      </a-row>
      <a-row type="flex" justify="space-around">
        <a-button type="primary" @click="$router.push('/login')"
          >Go to UI</a-button
        >
      </a-row>
    </a-col>
  </a-row>
</template>