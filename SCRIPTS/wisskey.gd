extends Node3D

@export var camera : Camera3D
@export var zoomFactor : int = 1
@export var maxSpeed : float = 16
@export var accel : float = 100
@export var friction : float = 0.8
@export var cameraSmoothing : float = 5.0
@export var cameraRotationSteps : int = 45
@export var FirstPersonRotationSpeed : float = 3

var zoom : float = 0
var camRotation : int = 0
var isFirstPerson : bool = false
var ySpeed : float = 0
var xSpeed : float = 0

var cameraResetHeight : int = 16
var nullVector3 : Vector3 = Vector3(0, 0, 0)
var hasLerpedCameraTransition : bool = false;

func _ready() -> void:
	zoom = cameraResetHeight
	
func _input(event: InputEvent) -> void:
		if event.is_action_pressed("reset"):
			zoom = cameraResetHeight
			camRotation = 0
			global_position = nullVector3
			hasLerpedCameraTransition = false;
			isFirstPerson = false
		
		if event.is_action_pressed("zoomIn"):
			zoom -= zoomFactor
			
		if event.is_action_pressed("zoomOut"):
			zoom += zoomFactor
			
		if event.is_action_pressed("ToggleCamera"):
			isFirstPerson = !isFirstPerson	
			hasLerpedCameraTransition = false;
			zoom = cameraResetHeight
			
		if event.is_action_pressed("RotateClockwise"):
			camRotation += cameraRotationSteps
			
		if event.is_action_pressed("RotateCounterClockwise"):
			camRotation -= cameraRotationSteps
		
func _physics_process(delta: float) -> void:
	#SLOWDOWN
	if xSpeed != 0:
		xSpeed *= friction
			
	if ySpeed != 0:
		ySpeed *= friction
		
	#INPUTS
	if hasLerpedCameraTransition or !isFirstPerson:
		#We have to wait for the camera to transition before letting the user move
		if Input.is_action_pressed("down"):
			if ySpeed < maxSpeed:
				ySpeed += accel * delta
				
		if Input.is_action_pressed("up"):
			if ySpeed > -maxSpeed:
				ySpeed -= accel * delta
				
		if Input.is_action_pressed("right"):
			if !isFirstPerson:
				if xSpeed < maxSpeed:
					xSpeed += accel * delta
			else:
				rotate_y(-FirstPersonRotationSpeed * delta);
				
		if Input.is_action_pressed("left"):
			if !isFirstPerson:
				if xSpeed > -maxSpeed:
					xSpeed -= accel * delta
			else:
				rotate_y(FirstPersonRotationSpeed * delta);
			
	#MOVEMENT FIX FOR ROTATING CAMERA
	var move_vector : Vector3 = Vector3(xSpeed, 0, ySpeed)
	var camera_yaw : float = deg_to_rad(camRotation)
	var rotated_move_vector : Vector3
	if isFirstPerson:
		rotated_move_vector = move_vector.rotated(Vector3.UP, camera.rotation.y)
	else:
		rotated_move_vector = move_vector.rotated(Vector3.UP, camera_yaw)
	global_position += rotated_move_vector * delta
	
	#UPDATE CAMERA
	if !isFirstPerson:
		#TOP-DOWN CAM LERPING
		var target_pos : Vector3
		var newCamRoation : Vector3
		target_pos.x = global_position.x
		target_pos.z = global_position.z
		target_pos.y = zoom
		
		camera.global_position = camera.global_position.lerp(target_pos, cameraSmoothing * delta)
		
		newCamRoation = camera.rotation.lerp(Vector3(deg_to_rad(-90), 0, 0), cameraSmoothing * delta)
		newCamRoation.y = lerp_angle(camera.rotation.y, deg_to_rad(camRotation % 360), cameraSmoothing * delta)
		camera.rotation = newCamRoation
	else:
		#FIRST PERSON CAM LERPING
		print(camera.position.distance_squared_to(position + Vector3(0, 4, 0)));
		if camera.position.distance_squared_to(position + Vector3(0, 4, 0)) <= 0.0001:
			hasLerpedCameraTransition = true;
			
		if hasLerpedCameraTransition:
			camera.position = position + Vector3(0, 4, 0)
		else:
			camera.position = camera.position.lerp(position + Vector3(0, 4, 0), cameraSmoothing * delta)
		
		var newCamRoation : Vector3
		newCamRoation.x = lerp_angle(camera.rotation.x, rotation.x, cameraSmoothing * delta)
		newCamRoation.y = lerp_angle(camera.rotation.y, rotation.y + deg_to_rad(90), cameraSmoothing * delta)	
		newCamRoation.z = lerp_angle(camera.rotation.z, rotation.z, cameraSmoothing * delta)
		
		camera.rotation = newCamRoation
		
	#LOOK AT STUFF
	if !isFirstPerson:
		var mousePos2D : Vector2 = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mousePos2D)
		var ray_direction = camera.project_ray_normal(mousePos2D)
		var ground_plane = Plane(Vector3.UP, global_transform.origin.y)
		
		var intersection_3d = ground_plane.intersects_ray(ray_origin, ray_direction)
		
		if intersection_3d != null:
			var look_at_point = Vector3(intersection_3d.x, global_transform.origin.y, intersection_3d.z)
			look_at(look_at_point, Vector3.UP)
			rotate_y(deg_to_rad(-90.0))
