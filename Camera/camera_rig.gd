extends Node3D

@onready var yaw_pivot: Node3D = $YawPivot
@onready var pitch_pivot: Node3D = $YawPivot/PitchPivot
@onready var camera: Camera3D = $YawPivot/PitchPivot/Camera3D
@onready var target_zoom: float = camera.position.z

@export var rotation_speed := 0.01
@export var pitch_speed := 0.01

@export var zoom_speed := 0.5
@export var zoom_smoothness := 10.0
@export var min_zoom_distance := 3.0
@export var max_zoom_distance := 15.0

@export var pivot_smoothness := 5.0
@export var drag_threshold := 5.0

var rotating := false

var middle_mouse_down := false
var middle_mouse_dragging := false
var middle_mouse_start_position := Vector2.ZERO
var previous_pan_point := Vector3.ZERO

var target_pivot := Vector3.ZERO


func _process(delta: float) -> void:
	# Zoom
	camera.position.z = lerp(
		camera.position.z,
		target_zoom,
		zoom_smoothness * delta
	)

	# Pivot
	position = position.lerp(
		target_pivot,
		pivot_smoothness * delta
	)


func get_pan_point(mouse_position: Vector2) -> Vector3:
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)

	var plane_normal := camera.global_transform.basis.z.normalized()
	var plane := Plane(
		plane_normal,
		target_pivot.dot(plane_normal)
	)

	var intersection: Variant = plane.intersects_ray(
		ray_origin,
		ray_direction
	)

	if intersection == null:
		return target_pivot

	return intersection


func _unhandled_input(event: InputEvent) -> void:

	# Mouse buttons
	if event is InputEventMouseButton:

		# Right mouse rotation
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed


		# Zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom -= zoom_speed

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom += zoom_speed

		target_zoom = clamp(
			target_zoom,
			min_zoom_distance,
			max_zoom_distance
		)


		# Middle mouse
		if event.button_index == MOUSE_BUTTON_MIDDLE:

			if event.pressed:
				# Start MMB interaction
				middle_mouse_down = true
				middle_mouse_dragging = false
				middle_mouse_start_position = event.position
				previous_pan_point = get_pan_point(event.position)

			else:
				# MMB released
				middle_mouse_down = false

				# If we didn't drag, this was a click.
				if not middle_mouse_dragging:
					var mouse_position: Vector2 = event.position

					var ray_origin := camera.project_ray_origin(mouse_position)
					var ray_direction := camera.project_ray_normal(mouse_position)
					var ray_end := ray_origin + ray_direction * 1000.0

					var query := PhysicsRayQueryParameters3D.create(
						ray_origin,
						ray_end
					)

					var result := get_world_3d().direct_space_state.intersect_ray(query)

					if not result.is_empty():
						var collider = result["collider"]

						if collider is Node3D:
							target_pivot = collider.global_position


	# Mouse movement
	if event is InputEventMouseMotion:

		# Right mouse camera rotation
		if rotating:
			yaw_pivot.rotate_y(
				-event.relative.x * rotation_speed
			)

			pitch_pivot.rotate_x(
				-event.relative.y * pitch_speed
			)


		# Middle mouse camera pan
		if middle_mouse_down:

			# Determine whether this is an actual drag.
			if not middle_mouse_dragging:
				if middle_mouse_start_position.distance_to(event.position) >= drag_threshold:
					middle_mouse_dragging = true

			if middle_mouse_dragging:
				var current_pan_point := get_pan_point(event.position)

				var movement := previous_pan_point - current_pan_point

				target_pivot += movement

				previous_pan_point = current_pan_point