extends Node3D

@export var target_path: NodePath
@export var smooth_speed: float = 5.0
var target: Node3D

func _ready():
	target = get_node(target_path)
	if target:
		# Мгновенно перемещаем пивот к машине при старте,
		# чтобы не было падения из нулевых координат
		global_position = target.global_position

func _physics_process(delta):
	if not target:
		return
		
	# Плавно следуем за машиной
	global_position = global_position.lerp(target.global_position, smooth_speed * delta)
