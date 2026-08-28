extends Node3D

## Counts what `JungleRiverCourse` actually asks the GPU for.
##
## The brief's performance requirement is a hard one — medium and lower-end
## Android — and it is stated in units a course author cannot check by reading
## constants: unique meshes, draw calls, instances, triangles. This walks the
## built course and reports them, so "roughly ten draw calls for the whole
## jungle" is a measurement rather than a claim.
##
##     godot --headless --path . res://tools/probe_river_cost.tscn \
##       --fixed-fps 60 --disable-render-loop --quit-after 5
##
## A scene rather than a `--script` SceneTree, for the reason `probe_course.gd`
## records: `--headless --script` compiles before the autoloads exist.

const COURSE: GDScript = preload("res://scripts/course/jungle_river_course.gd")


func _ready() -> void:
	var course: Course = COURSE.new()
	add_child(course)
	course.build()

	# The finish dressing hangs off `FinishZone`, not `build`, so a course
	# measured without one is missing a whole feature's worth of geometry.
	var finish := FinishZone.create(course)
	course.add_child(finish)

	var meshes := {}
	var totals := {
		"multimesh_nodes": 0, "multimesh_instances": 0, "multimesh_tris": 0,
		"mesh_nodes": 0, "mesh_tris": 0, "colliders": 0,
	}
	_walk(course, meshes, totals)

	print("--- JungleRiverCourse cost ---")
	print("unique meshes ............ %d" % meshes.size())
	print("MultiMesh draw calls ..... %d" % totals["multimesh_nodes"])
	print("MultiMesh instances ...... %d" % totals["multimesh_instances"])
	print("MultiMesh triangles ...... %d" % totals["multimesh_tris"])
	print("plain MeshInstance draws . %d" % totals["mesh_nodes"])
	print("plain MeshInstance tris .. %d" % totals["mesh_tris"])
	print("total draw calls ......... %d" % (totals["multimesh_nodes"] + totals["mesh_nodes"]))
	print("total triangles .......... %d" % (totals["multimesh_tris"] + totals["mesh_tris"]))
	print("collision shapes ......... %d" % totals["colliders"])
	get_tree().quit()


func _walk(node: Node, meshes: Dictionary, totals: Dictionary) -> void:
	if node is MultiMeshInstance3D:
		var multi := (node as MultiMeshInstance3D).multimesh
		if multi != null and multi.mesh != null:
			meshes[multi.mesh.get_rid()] = true
			var per := _triangles(multi.mesh)
			totals["multimesh_nodes"] += 1
			totals["multimesh_instances"] += multi.instance_count
			totals["multimesh_tris"] += per * multi.instance_count
	elif node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			meshes[mesh.get_rid()] = true
			totals["mesh_nodes"] += 1
			totals["mesh_tris"] += _triangles(mesh)
	elif node is CollisionShape3D:
		totals["colliders"] += 1

	for child in node.get_children():
		_walk(child, meshes, totals)


## Triangles in a mesh, summed over its surfaces. Indexed surfaces report their
## index count; unindexed ones report vertices.
func _triangles(mesh: Mesh) -> int:
	var count := 0
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		if arrays.is_empty():
			continue
		# `ARRAY_INDEX` is null on an unindexed surface, and `SurfaceTool` commits
		# unindexed meshes unless asked to index — so this must be read untyped.
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		if indices != null and (indices as PackedInt32Array).size() > 0:
			count += (indices as PackedInt32Array).size() / 3
			continue
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]

		count += vertices.size() / 3
	return count
