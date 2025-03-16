extends Node

func _ready():
	var cube = get_node("Cube")
	if cube:
		var mesh = BoxMesh.new()
		cube.mesh = mesh
