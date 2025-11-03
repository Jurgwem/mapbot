extends CharacterBody3D

@export var camera : Camera3D

@export var zoomFactor : int = 1
@export var maxSpeed : float = 16
@export var accel : float = 50
@export var sprint : float = 200
@export var friction : float = 0.8
@export var cameraSmoothing : float = 5.0
@export var cameraRotationSteps : int = 45
@export var FirstPersonRotationSpeed : float = 3
@export var PathLineThickness : float = 0.5
@export var PathLineColor : Color = Color(1, 0, 0)
@export var PathUpdateCooldown : float = 0.03

@onready var path_line_node : MeshInstance3D = $PathLine

var zoom : float = 0
var currentAcceleration : float = 0
var camRotation : int = 0
var isFirstPerson : bool = false
var isOrthogonalProjection : bool = false
var ySpeed : float = 0
var xSpeed : float = 0
var cameraResetHeight : int = 16
var nullVector3 : Vector3 = Vector3.ZERO
var hasLerpedCameraTransition : bool = false;
var line_material : StandardMaterial3D
var current_path_target : Variant = null
var path_update_timer : float = 0.0

func _ready() -> void:
	zoom = cameraResetHeight
	currentAcceleration = accel
	
	path_line_node.top_level = true
	
	if path_line_node.mesh == null:
		path_line_node.mesh = ArrayMesh.new()
	
	# LINE RENDERER / MAT
	line_material = StandardMaterial3D.new()
	line_material.albedo_color = PathLineColor
	line_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	line_material.vertex_color_use_as_albedo = true
	line_material.cull_mode = StandardMaterial3D.CULL_DISABLED
	
func _input(event: InputEvent) -> void:
		if event.is_action_pressed("reset"):
			zoom = cameraResetHeight
			camRotation = 0
			global_position = nullVector3
			hasLerpedCameraTransition = false;
			isFirstPerson = false
			current_path_target = null
			clear_path_line()
		
		if event.is_action_pressed("zoomIn"):
			zoom -= zoomFactor
			
		if event.is_action_pressed("zoomOut"):
			zoom += zoomFactor
			
		if event.is_action_pressed("ToggleCamera"):
			isFirstPerson = !isFirstPerson	
			hasLerpedCameraTransition = false;
			zoom = cameraResetHeight
			isOrthogonalProjection = false
			updateCameraProjection()
			
		if event.is_action_pressed("toggleCamProjection"):
			if !isFirstPerson:
				isOrthogonalProjection = !isOrthogonalProjection
				updateCameraProjection()
			
		if event.is_action_pressed("RotateClockwise"):
			camRotation += cameraRotationSteps
			
		if event.is_action_pressed("RotateCounterClockwise"):
			camRotation -= cameraRotationSteps
			
		if event.is_action_pressed("sprint"):
			currentAcceleration = sprint
		
		if event.is_action_released("sprint"):
			currentAcceleration = accel
			
		if event.is_action_pressed("LMB") and !isFirstPerson:
			var mousePos2D : Vector2 = get_viewport().get_mouse_position()
			var ray_origin = camera.project_ray_origin(mousePos2D)
			var ray_direction = camera.project_ray_normal(mousePos2D)
			
			var ground_plane = Plane(Vector3.UP, 0.0)
			var intersection_3d = ground_plane.intersects_ray(ray_origin, ray_direction)
			
			if intersection_3d != null:
				current_path_target = intersection_3d
				path_update_timer = 0.0 
				update_realtime_path()
			
		if event.is_action_pressed("RMB"):
			current_path_target = null
			clear_path_line()

func updateCameraProjection() -> void:
	if isOrthogonalProjection:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		
func _physics_process(delta: float) -> void:
	$"../camera/Control/FPS".text = str(Engine.get_frames_per_second())
	
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
				ySpeed += currentAcceleration * delta
				
		if Input.is_action_pressed("up"):
			if ySpeed > -maxSpeed:
				ySpeed -= currentAcceleration * delta
				
		if Input.is_action_pressed("right"):
			if !isFirstPerson:
				if xSpeed < maxSpeed:
					xSpeed += currentAcceleration * delta
			else:
				rotate_y(-FirstPersonRotationSpeed * delta);
				
		if Input.is_action_pressed("left"):
			if !isFirstPerson:
				if xSpeed > -maxSpeed:
					xSpeed -= currentAcceleration * delta
			else:
				rotate_y(FirstPersonRotationSpeed * delta);
			
	#MOVEMENT FIX FOR ROTATING CAMERA
	var move_vector : Vector3 = Vector3(xSpeed, 0.0, ySpeed) # G4: Floats verwenden
	var camera_yaw : float = deg_to_rad(camRotation)
	var rotated_move_vector : Vector3
	
	if isFirstPerson:
		rotated_move_vector = move_vector.rotated(Vector3.UP, camera.rotation.y)
	else:
		rotated_move_vector = move_vector.rotated(Vector3.UP, camera_yaw)
	velocity = rotated_move_vector
	move_and_slide()
	
	#UPDATE CAMERA
	if !isFirstPerson:
		#TOP-DOWN CAM LERPING
		var target_pos : Vector3
		var newCamRoation : Vector3
		target_pos.x = global_position.x
		target_pos.z = global_position.z
		target_pos.y = zoom
		
		#ORTHOGONAL CAMERA SIZE LERP
		camera.size = lerp(camera.size, zoom * 0.9, cameraSmoothing * delta)
		
		camera.global_position = camera.global_position.lerp(target_pos, cameraSmoothing * delta)
		
		newCamRoation = camera.rotation.lerp(Vector3(deg_to_rad(-90), 0, 0), cameraSmoothing * delta)
		newCamRoation.y = lerp_angle(camera.rotation.y, deg_to_rad(camRotation % 360), cameraSmoothing * delta)
		camera.rotation = newCamRoation
	else:
		#FIRST PERSON CAM LERPING
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
			
	#CONTINIOUS PATH UPDATES
	if path_update_timer > 0.0:
		path_update_timer -= delta

	update_realtime_path()
	
#ACTUAL UPDATE PATH METHOD
func update_realtime_path() -> void:
	if current_path_target == null:
		return

	if path_update_timer <= 0.0:
		path_update_timer = PathUpdateCooldown
		find_and_draw_path(global_position, current_path_target)
			
# GET POINTS FROM PATH
func find_and_draw_path(start_point : Vector3, end_point : Vector3) -> void:
	var map_rid: RID = get_world_3d().navigation_map
	var path_points : PackedVector3Array = NavigationServer3D.map_get_path(map_rid, start_point, end_point, true)
	path_points[0] = global_position;
	draw_path_line(path_points)

# DRAW PATH-LINE
func draw_path_line(path_points : PackedVector3Array) -> void:
	if path_line_node.mesh == null:
		path_line_node.mesh = ArrayMesh.new()
		
	var mesh : ArrayMesh = path_line_node.mesh
	mesh.clear_surfaces()

	if path_points.size() < 2:
		return 

	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	
	var line_color = PathLineColor
	var lift_height = Vector3(0.0, 0.1, 0.0)
	var half_thickness = PathLineThickness / 2.0

	for i in range(path_points.size()):
		var current_point = path_points[i] + lift_height
		
		var perp_vec : Vector3
		
		if i == 0:
			var dir_out = (path_points[i+1] + lift_height - current_point).normalized()
			perp_vec = dir_out.cross(Vector3.UP).normalized() * half_thickness
			
		elif i == path_points.size() - 1:
			var dir_in = (current_point - (path_points[i-1] + lift_height)).normalized()
			perp_vec = dir_in.cross(Vector3.UP).normalized() * half_thickness
			
		else:
			var dir_in = (current_point - (path_points[i-1] + lift_height)).normalized()
			var dir_out = (path_points[i+1] + lift_height - current_point).normalized()

			var perp_in = dir_in.cross(Vector3.UP).normalized()
			var perp_out = dir_out.cross(Vector3.UP).normalized()

			var miter_dir = (perp_in + perp_out).normalized()
			var miter_length_factor = miter_dir.dot(perp_out)

			#FAILSAFE FOR 180° TURN
			if abs(miter_length_factor) < 0.01:
				perp_vec = perp_in * half_thickness
			else:
				var miter_length = half_thickness / miter_length_factor
				miter_length = min(miter_length, half_thickness * 5.0)
				
				perp_vec = miter_dir * miter_length

		#ADD BOTH VERTICES
		var v_left = current_point - perp_vec
		var v_right = current_point + perp_vec

		vertices.append(v_left)
		vertices.append(v_right)
		colors.append(line_color)
		colors.append(line_color)

	#CREATE GEO
	var surface_arrays : Array = []
	surface_arrays.resize(ArrayMesh.ARRAY_MAX)
	surface_arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	surface_arrays[ArrayMesh.ARRAY_COLOR] = colors

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, surface_arrays)
	mesh.surface_set_material(0, line_material)

#DEL PATH
func clear_path_line() -> void:
	if path_line_node.mesh != null:
		path_line_node.mesh.clear_surfaces()
