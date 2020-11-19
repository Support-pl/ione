<template>
	<a-list
		bordered
		:data-source="value.body.split(',')"
	>
		<a-list-item slot="renderItem" slot-scope="item">
			{{ item }}
		</a-list-item>
	</a-list>
</template>

<script>
export default {
	name: 'settingsLIST',
	props: ['value']
}
</script>

<style>

</style>