extends Node3D

@onready var yaw_pivot: Node3D = $YawPivot
@onready var pitch_pivot: Node3D = $YawPivot/PitchPivot
@onready var camera: Camera3D = $YawPivot/PitchPivot/Camera3D
@onready var target_zoom :float = camera.position.z


@export var rotation_speed := 0.01
@export var pitch_speed := 0.01

@export var zoom_speed := 0.5
@export var zoom_smoothness := 10
@export var min_zoom_distance := 3.0
@export var max_zoom_distance := 15.0

var target_pivot := Vector3.ZERO
@export var pivot_smoothness := 5.0


var rotating := false



func _process(delta: float) -> void:

	# Zoom lerp
	camera.position.z = lerp(camera.position.z, target_zoom, zoom_smoothness * delta)
	
	# Pivot lerp
	position = position.lerp(target_pivot, pivot_smoothness * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom -= zoom_speed
			
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom += zoom_speed

		# Middle Mouse and Raycast
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			#print ("Middle mouse button pressed")

			var mouse_position = event.position
			var ray_origin = camera.project_ray_origin(mouse_position)
			var ray_direction = camera.project_ray_normal(mouse_position)

			var ray_end = ray_origin + ray_direction * 1000.0

			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			var result = get_world_3d().direct_space_state.intersect_ray(query)
			#print("Raycast result: ", result)

			if not result.is_empty():
				var collider = result["collider"]
				print("Hit collider: ", collider)
				target_pivot = collider.global_position



		target_zoom = clamp(target_zoom, min_zoom_distance, max_zoom_distance)
	if event is InputEventMouseMotion and rotating:
		yaw_pivot.rotate_y(-event.relative.x * rotation_speed)
		pitch_pivot.rotate_x(-event.relative.y * pitch_speed)

	
