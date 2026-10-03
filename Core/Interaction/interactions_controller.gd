extends Node3D

@onready var camera: Camera3D = get_viewport().get_camera_3d()

var selected_object: Node3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_at_mouse(event.position)


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


func _deselect_current() -> void:
	if selected_object == null:
		return

	var selectable := selected_object.get_node_or_null("SelectableComponent")

	if selectable:
		selectable.deselect()

	selected_object = null
