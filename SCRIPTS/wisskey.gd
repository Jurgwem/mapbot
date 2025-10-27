extends Node3D

@export var camera : Camera3D
@export var zoomFactor : int = 1
@export var maxSpeed : float = 16
@export var accel : float = 2
@export var drag : float = 0.8
@export var cameraSmoothing : float = 5.0

var zoom : float = 0;
var ySpeed : float = 0
var xSpeed : float = 0

var cameraResetHeight : int = 16
var nullVector3 : Vector3 = Vector3(0, 0, 0);

func _ready() -> void:
	zoom = cameraResetHeight
	print("test")
	
func _input(event: InputEvent) -> void:
		if event.is_action_pressed("reset"):
			zoom = cameraResetHeight
			global_position = nullVector3
		
		if event.is_action_pressed("zoomIn"):
			zoom -= zoomFactor
			
		if event.is_action_pressed("zoomOut"):
			zoom += zoomFactor
		
func _physics_process(delta: float) -> void:
	#SLOWDOWN
	if xSpeed != 0:
		xSpeed *= drag
			
	if ySpeed != 0:
		ySpeed *= drag
		
	#INPUTS
	if Input.is_action_pressed("down"):
		if ySpeed < maxSpeed:
			ySpeed += accel
			
	if Input.is_action_pressed("up"):
		if ySpeed > -maxSpeed:
			ySpeed -= accel
			
	if Input.is_action_pressed("right"):
		if xSpeed < maxSpeed:
			xSpeed += accel
			
	if Input.is_action_pressed("left"):
		if xSpeed > -maxSpeed:
			xSpeed -= accel
	
	#UPDATE POS
	position += Vector3(xSpeed * delta, 0, ySpeed * delta)
	
	#UPDATE CAMERA
	var target_pos : Vector3
	target_pos.x = global_position.x
	target_pos.z = global_position.z
	target_pos.y = zoom
	
	camera.global_position = camera.global_position.lerp(target_pos, cameraSmoothing * delta)
	
	#LOOK AT STUFF
	var mousePos2D : Vector2 = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mousePos2D)
	var ray_direction = camera.project_ray_normal(mousePos2D)
	var ground_plane = Plane(Vector3.UP, global_transform.origin.y)
	
	var intersection_3d = ground_plane.intersects_ray(ray_origin, ray_direction)
	
	if intersection_3d != null:
		var look_at_point = Vector3(intersection_3d.x, global_transform.origin.y, intersection_3d.z)
		look_at(look_at_point, Vector3.UP)
		rotate_y(deg_to_rad(-90.0))
