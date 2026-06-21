extends Camera3D

@onready var target = get_node("../sedan")
@onready var ball = get_node("../Ball")
var offset = Vector3(0, 4, -8)
var angular_offset = deg_to_rad(90)
var max_camera_predict = deg_to_rad(135)

var position_smoothing = 6.0
var rotation_smoothing = 4.0

var fov_base = 75.0
var distance_speed_factor = 0 #процент отъезда камеры
var fov_speed_factor = 0.10 #fov increase in %
var max_speed_reference = 120.0

func _physics_process(delta: float) -> void:
	var target_rotation = Basis(target.global_transform.basis.get_rotation_quaternion())
	
	var speed = ball.linear_velocity.length() if ball else 0.0
	var speed_ratio = clamp(speed/max_speed_reference, 0.0, 1.0)
	
	var dynamic_offset = offset * (1.0 + speed_ratio * distance_speed_factor)
	var desired_position = target.global_transform.origin + target_rotation * dynamic_offset
	
	var pos_t = 1.0 - exp(-position_smoothing * delta)
	global_transform.origin = global_transform.origin.lerp(desired_position,pos_t)
	
	var look_dir = target.global_transform.origin - global_transform.origin
	if look_dir.length() > 0.01:
		var look_basis = Basis.looking_at(look_dir, Vector3.UP)
		var rot_t = exp(-max_camera_predict * -rotation_smoothing * delta)
		global_transform.basis = global_transform.basis.slerp(look_basis, rot_t)
		
	fov = lerp(fov, fov_base + speed_ratio * fov_speed_factor * fov_base, pos_t)
