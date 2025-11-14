extends Node

@onready var debugMap : Resource = preload("res://MAPS/map_test.tscn")
@onready var GroundFloorMap : Resource = preload("res://MAPS/ground_floor.tscn")

var currentInstancedMap : NavigationRegion3D

func _ready() -> void:
	currentInstancedMap = GroundFloorMap.instantiate()
	get_tree().current_scene.add_child(currentInstancedMap)
	print("autoload done.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("windowOptions"):
		var current_mode = DisplayServer.window_get_mode()
		var is_borderless = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
		
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size.call_deferred(Vector2i(1280, 720))
			get_window().move_to_center.call_deferred()

		elif current_mode == DisplayServer.WINDOW_MODE_WINDOWED and not is_borderless:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen_size = DisplayServer.screen_get_size()
			DisplayServer.window_set_size(screen_size)
			DisplayServer.window_set_position(Vector2i(0, 0)) 
		
		elif current_mode == DisplayServer.WINDOW_MODE_WINDOWED and is_borderless:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			
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
				currentInstancedMap = debugMap.instantiate()
				get_tree().current_scene.add_child(currentInstancedMap)
			
			if event.is_action_pressed("loadBasement"):
				clearMap()
				
			if event.is_action_pressed("loadGroundFloor"):
				clearMap()
				currentInstancedMap = GroundFloorMap.instantiate()
				get_tree().current_scene.add_child(currentInstancedMap)
				
			if event.is_action_pressed("loadFirstFloor"):
				clearMap()
				
			if event.is_action_pressed("loadSecondFloor"):
				clearMap()
			
	elif event.is_action_pressed("loadIntermission"):
		#Check if intermission setup is loaded
		if get_tree().current_scene.name != "intermission":
			get_tree().change_scene_to_file("res://SCENES/intermission.tscn")
			
		
			
			
func toggleMappingUI(value) -> void:
	if currentInstancedMap != null:
		var borders = currentInstancedMap.get_node("borders")
		var signs = currentInstancedMap.get_node("signs")
		
		if value:
			signs.visible = false;
			borders.visible = false;
		else:
			signs.visible = true;
			borders.visible = true;

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
