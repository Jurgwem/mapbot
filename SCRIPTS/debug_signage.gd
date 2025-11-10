extends Sprite3D

@export var target : Node

func _ready() -> void:
	if target != null:
		$subviewport/MarginContainer/Label.text = str(target.name)
