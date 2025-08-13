class_name SimonManager extends Node

static var Main

var _groups:Array[String]

var _registeredGroups:Array[MethodGroups]
var _registeredObjects:Dictionary

var RegisteredObjects: 
	get:
		return _registeredObjects

class MethodGroups:
	var is_paused:bool = false
	var name:String
	var content:Array[RegisteredMethod]
	
	var currentDelta = 0.0
	var deltaInterval = 0.0
	
	func _init(n:String):
		content = []
		name = n

class RegisteredMethod:
	var object:Object
	var callable:Callable
	var groupName:String
	
	func _init(obj:Object, call:Callable, gN:String):
		object = obj
		callable = call
		gN = groupName

# Called when the node enters the scene tree for the first time.
func _ready():
	Main = self
	_groups = []

func pause_group(group_name:String):
	for group in _registeredGroups:
		if (group.name == group_name):
			group.is_paused = true
			
func unpause_group(group_name:String):
	for group in _registeredGroups:
		if (group.name == group_name):
			group.is_paused = false

func pause_all_but_group(group_name:String):
	for group in _registeredGroups:
		if (group.name != group_name):
			group.is_paused = true

func unpause_all_but_group(group_name:String):
	for group in _registeredGroups:
		if (group.name != group_name):
			group.is_paused = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for group in _registeredGroups:
		if (!group.is_paused):
			for entry in group.content:
				entry.callable.call(delta)

func registerClass(obj:Object,call:Callable,group_name:String):
	var target_class:MethodGroups = null
	for group in _registeredGroups:
		if (group.name == group_name):
			target_class = group
	
	if (!target_class):
		target_class = MethodGroups.new(group_name)
		_registeredGroups.append(target_class)
		
	for c in target_class.content:
		if (c.object == obj):
			return
		
	var new_register:RegisteredMethod = RegisteredMethod.new(obj,call,group_name)
	target_class.content.append(new_register)
	_registeredObjects[obj.name] = obj
	
func unregisterClass(obj:Object):
	var content_array_to_erase_from:Array
	var content_to_erase:RegisteredMethod
	
	for group in _registeredGroups:
		for c in group.content:
			if (obj == c.object):
				content_array_to_erase_from = group.content
				content_to_erase = c
	
	if (content_to_erase):
		content_array_to_erase_from.erase(content_to_erase)
		_registeredObjects.erase(obj.name)
