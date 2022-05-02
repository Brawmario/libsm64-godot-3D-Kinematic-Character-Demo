extends Spatial


const FPS_30_DELTA = 1.0/30.0

export var sm64_handler: Resource
export var sm64_static_surface_resource: Resource

onready var mario = $Mario
onready var reference_cube: MeshInstance = $RefereceCube
onready var grid_map: GridMap = $GridMap
onready var rom_picker: FileDialog = $FileDialog


var time_since_last_tick := 0.0
var moving_platform_ids := []
var moving_platforms := {}


func _ready() -> void:
	rom_picker.popup_centered()
	yield(rom_picker, "file_selected")
	sm64_handler.rom_filename = rom_picker.current_path

	sm64_handler.global_init()

	load_static_sufaces()

	load_moving_platform($Elevator1)
	load_moving_platform($Elevator2)

	mario.create()


func _physics_process(delta: float) -> void:
	time_since_last_tick += delta
	if time_since_last_tick < FPS_30_DELTA:
		return
	time_since_last_tick -= FPS_30_DELTA

	for id in moving_platform_ids:
		move_platform_in_lib(id)


func load_static_sufaces() -> void:
	var faces := PoolVector3Array()

	var cells: Array = $GridMap.get_used_cells()

	for cell in cells:
		var pos := grid_map.map_to_world(cell.x, cell.y, cell.z)
		var mesh_faces: PoolVector3Array = reference_cube.get_mesh().get_faces()
		for i in range(mesh_faces.size()):
			mesh_faces[i] += pos
		faces.append_array(mesh_faces)

	var surface_properties_array := _create_surface_properties_array(sm64_static_surface_resource, faces.size() / 3)

	sm64_handler.static_surfaces_load(faces, surface_properties_array)


func load_moving_platform(platform: KinematicBody) -> void:
	var platform_mesh_faces := reference_cube.get_mesh().get_faces()
	var surface_properties_array := _create_surface_properties_array(sm64_static_surface_resource, platform_mesh_faces.size() / 3)

	var id = sm64_handler.surface_object_create(platform_mesh_faces, surface_properties_array, platform.global_transform.origin, platform.rotation_degrees)
	if id >= 0:
		moving_platform_ids.append(id)
		moving_platforms[id] = platform


func move_platform_in_lib(id: int) -> void:
	var platform: KinematicBody = moving_platforms[id]
	sm64_handler.surface_object_move(id, platform.global_transform.origin, platform.rotation_degrees)


func _create_surface_properties_array(surface_properties: Resource, array_size: int) -> Array:
	var surface_properties_array := []
	surface_properties_array.resize(array_size)
	for i in range(array_size):
		surface_properties_array[i] = surface_properties
	return surface_properties_array
