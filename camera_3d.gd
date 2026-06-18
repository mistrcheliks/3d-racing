extends Camera3D

@export var player: Node3D
@export var offset: Vector3 = Vector3(0, 3, 8)
@export var position_smooth: float = 8.0
@export var rotation_smooth: float = 6.0

var target: Node3D

func _ready() -> void:
	if not player:
		push_error("Camera: player export is not set in the Inspector!")
		return
	# wait for player's _ready() to finish before reading camera_target
	await player.ready
	target = player.camera_target

func _physics_process(delta: float) -> void:
	if not target:
		return

	var desired_pos: Vector3 = target.global_transform.basis * offset + target.global_position
	global_position = global_position.lerp(desired_pos, position_smooth * delta)

	var look_transform := global_transform.looking_at(target.global_position, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(look_transform.basis, rotation_smooth * delta)
