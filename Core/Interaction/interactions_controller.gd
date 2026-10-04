extends Node3D

@onready var camera: Camera3D = get_viewport().get_camera_3d()

var selected_object: Node3D

var is_dragging := false
var drag_started := false

var drag_plane: Plane
var drag_offset := Vector3.ZERO

var drag_start_mouse_position := Vector2.ZERO
const DRAG_THRESHOLD := 5.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_select_at_mouse(event.position)
			else:
				_stop_dragging()

	elif event is InputEventMouseMotion:
		if selected_object != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_handle_mouse_drag(event.position)


func _select_at_mouse(mouse_position: Vector2) -> void:
	var origin := camera.project_ray_origin(mouse_position)
	var direction := camera.project_ray_normal(mouse_position)

	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * 1000.0
	)

	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		_deselect_current()
		return

	var object: Node3D = result.collider
	var selectable := object.get_node_or_null("SelectableComponent")

	if selectable == null:
		_deselect_current()
		return

	_deselect_current()

	selected_object = object
	selectable.select()

	_prepare_drag(mouse_position)


func _prepare_drag(mouse_position: Vector2) -> void:
	drag_started = false
	is_dragging = false

	drag_start_mouse_position = mouse_position

	var object_position := selected_object.global_position

	# Plane facing the camera.
	# The object will move along the camera's X/Y screen space.
	var camera_forward := -camera.global_transform.basis.z.normalized()

	drag_plane = Plane(camera_forward, camera_forward.dot(object_position))

	var mouse_world_position := _get_mouse_position_on_drag_plane(mouse_position)

	if mouse_world_position != Vector3.INF:
		drag_offset = object_position - mouse_world_position


func _handle_mouse_drag(mouse_position: Vector2) -> void:
	if not drag_started:
		if mouse_position.distance_to(drag_start_mouse_position) < DRAG_THRESHOLD:
			return

		_start_dragging()

	if is_dragging:
		_drag_at_mouse(mouse_position)


func _start_dragging() -> void:
	if selected_object == null:
		return

	drag_started = true
	is_dragging = true

	var rigidbody := selected_object as RigidBody3D

	if rigidbody:
		rigidbody.linear_velocity = Vector3.ZERO
		rigidbody.angular_velocity = Vector3.ZERO
		rigidbody.freeze = true


func _drag_at_mouse(mouse_position: Vector2) -> void:
	if selected_object == null:
		return

	var mouse_world_position := _get_mouse_position_on_drag_plane(mouse_position)

	if mouse_world_position == Vector3.INF:
		return

	var target_position := mouse_world_position + drag_offset

	selected_object.global_position = target_position


func _stop_dragging() -> void:
	if not is_dragging:
		return

	is_dragging = false
	drag_started = false

	if selected_object == null:
		return

	var rigidbody := selected_object as RigidBody3D

	if rigidbody:
		rigidbody.linear_velocity = Vector3.ZERO
		rigidbody.angular_velocity = Vector3.ZERO
		rigidbody.freeze = false


func _get_mouse_position_on_drag_plane(mouse_position: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(mouse_position)
	var direction := camera.project_ray_normal(mouse_position)

	var hit = drag_plane.intersects_ray(origin, direction)

	if hit == null:
		return Vector3.INF

	return hit


func _deselect_current() -> void:
	_stop_dragging()

	if selected_object == null:
		return

	var selectable := selected_object.get_node_or_null("SelectableComponent")

	if selectable:
		selectable.deselect()

	selected_object = null
