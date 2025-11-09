extends Node

@onready var debugMap : Resource = preload("res://MAPS/map_test.tscn")

func _ready() -> void:
	print("autoload done.")

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("loadBasement") ||
		event.is_action_pressed("loadGroundFloor") ||
		event.is_action_pressed("loadFirstFloor") ||
		event.is_action_pressed("loadSecondFloor") ||
		event.is_action_pressed("loadDebug")):
		
		#Check if map setup is loaded
		if get_tree().current_scene.name != "world":
			get_tree().change_scene_to_file("res://SCENES/map.tscn")
		else:
			if event.is_action_pressed("loadDebug"):
				clearMap()
				var debugMapInstance : NavigationRegion3D = debugMap.instantiate()
				get_tree().current_scene.add_child(debugMapInstance)
			
			if event.is_action_pressed("loadBasement"):
				clearMap()
				
			if event.is_action_pressed("loadGroundFloor"):
				clearMap()
				
			if event.is_action_pressed("loadFirstFloor"):
				clearMap()
				
			if event.is_action_pressed("loadSecondFloor"):
				clearMap()
			
	elif event.is_action_pressed("loadIntermission"):
		#Check if intermission setup is loaded
		if get_tree().current_scene.name != "intermission":
			get_tree().change_scene_to_file("res://SCENES/intermission.tscn")
			
		
func clearMap() -> void:
	var root : Node = get_tree().current_scene
	
	if not is_instance_valid(root):
		return
	
	for node in root.get_children():
		if node is CharacterBody3D:
			node.clear_path_line()
		if node is NavigationRegion3D:
			root.remove_child(node)
			node.queue_free()
