extends Sprite3D

@export var roomTitle : String

var camera : Camera3D = null

func _ready() -> void:
	var root : Node = get_tree().current_scene
	
	if roomTitle != "":
		$SubViewport/MarginContainer/Label.text = roomTitle
	
	for node in root.get_children():
		if node is Camera3D:
			camera = node
			break

func _physics_process(_delta: float) -> void:
	if camera != null:
		if rotation.y != camera.rotation.y:
			rotation.y = camera.rotation.y
