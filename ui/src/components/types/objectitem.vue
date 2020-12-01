<template>
	<span>
		<template v-if="typeof value == 'object'">
			<template v-if="opened || status.edit">
				<div v-for="[key, val] of entries(value)" :key="key" :style="getStyle(deepness)" class="objectItem">
					<div v-if="creatingPath == path+'/'+key && status.edit && status.action == 'update'" class="objectItem">
						<div class="objectBtns objectBtnsBias2btns">
							<div class="btns">
								<a-icon type="plus" class="objectBtn" @click="addKey(path, edit.key, edit.value)"/>
								<a-icon type="close" class="objectBtn" @click="changeActionPath(null, 'idle')"/>
							</div>
						</div>
						<a-input
							v-model="edit.key"
							ref="key"
							size="small"
							style="width: 100px"
							placeholder="key"
							@keyup.enter="goToValue"
						>
						</a-input>
						:
						<a-input
							v-model="edit.value"
							ref="value"
							size="small"
							style="width: 200px"
							placeholder="value"
							@keyup.enter="addKey(path, edit.key, edit.value)"
						>
						</a-input>
					</div>
					<template v-else-if="isEditingKey != key">
						<span class="itemKey" :class="{key: typeof val == 'object'}" @click="open(key)">
							{{key}}:
							{{typeOfBrackets(val, 0)}}
						</span>
						<div v-if="status.edit" class="objectBtns objectBtnsBias3btns showOnHoverItemKey">
							<div class="btns">
								<a-icon type="tool" class="objectBtn" @click="update(path, key, val)" />
								<a-icon type="plus" class="objectBtn" @click="create(path, key)" />
								<a-icon type="minus" class="objectBtn" @click="removeKey(path+'/'+key)" />
							</div>
						</div>
							<objectitem
								:value="val"
								:deepness="+deepness +1"
								:path="path + '/' + key"
								:opened='openedChilds.includes(key)'
								:status="status"
								:addKey="addKey"
								:removeKey="removeKey"
								:changeActionPath="changeActionPath"
								:creatingPath="creatingPath"
							/>
						<span class="key" @click="open(key)">
							{{typeOfBrackets(val, 1)}}
						</span>
					</template>
					<template v-else>
						{{key}}
					</template>

				</div>
				<div v-if="creatingPath == path && status.edit && status.action == 'create'" :style="getStyle(deepness)" class="objectItem">
					<div class="objectBtns objectBtnsBias2btns">
						<div class="btns">
							<a-icon type="plus" class="objectBtn" @click="addKey(path, edit.key, edit.value)"/>
							<a-icon type="close" class="objectBtn" @click="changeActionPath(null, 'idle')"/>
						</div>
					</div>
					<a-input
						v-model="edit.key"
						ref="key"
						size="small"
						style="width: 100px"
						placeholder="key"
						@keyup.enter="goToValue"
						>
					</a-input>
					:
					<a-input
						v-model="edit.value"
						ref="value"
						size="small"
						style="width: 200px"
						placeholder="value"
						@keyup.enter="addKey(path, edit.key, edit.value)"
					>
					</a-input>
				</div>
			</template>
			<template v-else>
				<template v-if="preview(value) == 'val'">
					{{value}}
				</template>
				<template v-else>
					...
				</template>
			</template>
		</template>
		<template v-else>
			{{value}}
		</template>
	</span>
</template>

<script>
export default {
	name: "objectitem",
	props: [
		'value',
		'deepness',
		'path',
		'opened',
		'addKey',
		'removeKey',
		'changeActionPath',
		'creatingPath',
		'status'
	],
	data(){
		return {
			openedChilds: [],
			isEditingKey: '',
			edit: {
				key: '',
				value: ''
			}
		}
	},
	methods: {
		isArray(obj){
			return Array.isArray(obj);
		},
    entries(obj) {
			if(typeof obj == 'string'){
				let obj = JSON.parse(obj ?? "");
			}
      return Object.entries(obj);
    },
		isJsonString(str){
			try{
				JSON.parse(str);
			} catch (e){
				return false;
			}
			return true;
		},
		typeOfBrackets(obj, close){
			const types = {
				'object': ["{", "}"],
				'array': ['[', ']'],
				'other': ''
			}
			if(typeof obj == 'object'){
				return types[this.isArray(obj)?"array":"object"][close];
			} else {
				return types.other
			}
		},
		preview(item){
			const type = typeof item;
			if(type != 'object'){
				return 'val';
			} else {
				return 'plug';
			}
		},
		open(key){
			const indexOfKey = this.openedChilds.indexOf(key)
			if(~indexOfKey){
				this.openedChilds.splice(indexOfKey, 1);
			} else {	
				this.openedChilds.push(key);
			}
			console.log(this.path);
		},
		getStyle(deepness){
			return {
				'padding-left': `${+Boolean(+deepness)*10}px`,
				'border-left': `${+Boolean(+deepness)*1}px solid rgba(0, 0, 0, 0.3)`
			}
		},
		goToValue(){
			this.$refs['value'].focus();
		},
		update(path, key, value){
			this.edit.key = key;
			this.edit.value = JSON.stringify(value);
			this.changeActionPath(path+'/'+key, 'update')
		},
		create(path, key){
			this.key = "";
			this.edit.value = "";
			this.changeActionPath(path+'/'+key, 'create')
		}
	}
}
</script>

<style>
.key {
	cursor: pointer;
}

.objectItem{
	position: relative;
}

.objectBtns{
	position: absolute;
	left: calc((24px * 1 + 5px) * -1);
	top: -3px;
	opacity: .6;
	padding-right: 17px;
	transition: opacity .2s ease;
}

.objectBtnsBias2btns{
	left: calc((24px * 2 + 5px) * -1);
}

.objectBtnsBias3btns{
	left: calc((24px * 3 + 5px) * -1);
}

.objectBtnsBias4btns{
	left: calc((24px * 4 + 5px) * -1);
}

.btns{
	background-color: #fff;
	box-shadow: 2px 2px 4px rgba(0,0,0,.2);
	border-radius: 10px;
	padding: 3px 5px;
	transition: transform .2s ease;
}

.btns:hover{
	transform: scale(1.1);
}
.showOnHoverItemKey{
	opacity: 0;
	pointer-events: none;
}
.itemKey:hover + .showOnHoverItemKey,
.showOnHoverItemKey:hover{
	pointer-events: auto;
	opacity: .6;
}

.objectBtn:not(:last-of-type){
	margin-right: 10px;
}
.objectBtn{
	cursor: pointer;
	transition:
		color .2s ease,
		transform .2s ease;
}
.objectBtn:hover{
	transform: scale(1.2);
	color: #5aa3bb;
}
.objectItem{
	position: relative;
}
.btnWrapper{
	position: absolute;
	top: 50%;
	left: -25px;
	transform: translateY(-50%);
	background-color: #fff;
	padding: 3px 5px;
	border-radius: 10px;
	opacity: .8;
	transition: opacity .2s ease;
	cursor: pointer;
}

.btnWrapper:hover{
	opacity: 1;
}
</style>