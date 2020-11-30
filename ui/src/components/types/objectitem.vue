<template>
	<span>{{value}}</span>
</template>

<script>
export default {
	name: "ObjectItem",
	props: [
		'value',
		'deepness',
		'path'
	]
}
</script>

<style>

</style>