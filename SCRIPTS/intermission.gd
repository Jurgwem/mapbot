extends Node3D

var rotateSpeed : float = 32
var muteToggle : bool = false;
var textIndex : int = 0
var texts = [
			["", "INTERMISSION", "TECHNICAL", "WAHLE IST"], 
			["", "INTERMISSION", "DIFFICULTIES", "IST SCHULD"]
			]

func _ready() -> void:
	$HUD/TOP_CONTAINER/TOP.text = ""
	$HUD/BOTTOM_CONTAINER2/BOTTOM.text = ""

func _physics_process(delta: float) -> void:
	$wisskey_proto.rotate_y(-rotateSpeed * delta / 10)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		muteToggle = !muteToggle
		updateAudio()
		
	if event.is_action_pressed("zoomIn"):
		textIndex = (textIndex + 1) % texts[0].size()
		updateText()
		
	if event.is_action_pressed("zoomOut"):
		textIndex = (textIndex - 1) % texts[0].size()
		updateText()
		
func updateText() -> void:
	$HUD/TOP_CONTAINER/TOP.text = texts[0][textIndex]
	$HUD/BOTTOM_CONTAINER2/BOTTOM.text = texts[1][textIndex]
		
func updateAudio() -> void:
	if muteToggle:
		$funkyPlayer.stop()
	else:
		$funkyPlayer.play()
