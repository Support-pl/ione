<template>
  <a-row type="flex" justify="space-around">
    <a-col :span="12">
      <a-row type="flex" justify="space-around">
        <h1>Hello, World! via IONe Web API</h1>
      </a-row>
      <a-row type="flex" justify="space-around">
        <a-button type="primary" @click="$router.push('/dashboard')"
          >Go to UI</a-button
        >
      </a-row>
    </a-col>
  </a-row>
</template>