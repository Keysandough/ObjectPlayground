extends Node

@export var highlight_color := Color(1.0, 0.8, 0.2)
@export var highlight_strength := 2.0

var is_selected := false

var mesh: MeshInstance3D
var original_material: Material
var highlight_material: StandardMaterial3D


func _ready() -> void:
	mesh = get_parent().get_node_or_null("MeshInstance3D")

	if mesh == null:
		push_warning("SelectableComponent: No MeshInstance3D found.")
		return

	original_material = mesh.material_override

	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color.WHITE
	highlight_material.emission_enabled = true
	highlight_material.emission = highlight_color
	highlight_material.emission_energy_multiplier = highlight_strength


func select() -> void:
	if mesh == null:
		return

	is_selected = true
	mesh.material_override = highlight_material


func deselect() -> void:
	if mesh == null:
		return

	is_selected = false
	mesh.material_override = original_material