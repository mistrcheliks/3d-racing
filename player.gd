extends Node3D

@onready var ball = $Ball
@onready var car_mesh = $sedan
@onready var ground_ray = $sedan/GroundRay

var sphere_offset = Vector3(0, -1, 0)

var current_ground_normal = Vector3.UP
var ground_normal_landing_speed = 15.0   # fast
var ground_normal_airborne_speed = 8.0   # slower flattening

var acceleration = 600
var steering = 10.0      # максимальный угол поворота в градусах
var turn_speed = 10
var turn_stop_limit = 0.15

var speed_input = 0
var rotate_input = 0

# ---------- Lateral friction & drift ----------
var lateral_friction = 100.0          # how strongly sideways sliding is resisted
var drift_speed_threshold = 12.0     # minimum forward speed to start drifting
var drift_steer_threshold = 0.3      # how hard you need to steer (0..1) to drift
var drift_friction_factor = 0.15     # lateral friction multiplier when drifting (0.0 = no friction, 1.0 = full grip)

func _ready():
	ground_ray.add_exception(ball)


func get_rotate_input() -> float:
	return rotate_input
	
func _process(_delta):
	if not ground_ray.is_colliding():
		speed_input = 0
		rotate_input = 0
		return

	speed_input = 0
	speed_input += Input.get_action_strength("throttle")
	speed_input -= Input.get_action_strength("brake")
	speed_input *= acceleration

	rotate_input = 0
	rotate_input += Input.get_action_strength("steer_left")
	rotate_input -= Input.get_action_strength("steer_right")
	rotate_input *= deg_to_rad(steering)

func _physics_process(delta):
	# --- 1. Position ---
	car_mesh.global_transform.origin = ball.global_transform.origin + sphere_offset

	# --- 2. Slope alignment ---
	var ground_normal = Vector3.UP
	if ground_ray.is_colliding():
		ground_normal = ground_ray.get_collision_normal()

	var current_forward = -car_mesh.global_transform.basis.z.normalized()
	if current_forward.length() < 0.01:
		current_forward = Vector3.FORWARD

	var projected_forward = (current_forward - ground_normal * current_forward.dot(ground_normal)).normalized()
	if projected_forward.length() < 0.001:
		projected_forward = (Vector3.FORWARD - ground_normal * Vector3.FORWARD.dot(ground_normal)).normalized()

	var new_right = projected_forward.cross(ground_normal).normalized()
	var slope_basis = Basis(new_right, ground_normal, -projected_forward)

	# --- 3. Steering rotation (only when moving) ---
	if ball.linear_velocity.length() > turn_stop_limit and abs(rotate_input) > 0.001:
		var yaw_quat = Quaternion(ground_normal, rotate_input)
		var current_quat = slope_basis.get_rotation_quaternion()
		var target_quat = current_quat * yaw_quat
		var final_quat = current_quat.slerp(target_quat, turn_speed * delta)
		slope_basis = Basis(final_quat).scaled(car_mesh.global_transform.basis.get_scale())

	car_mesh.global_transform.basis = slope_basis

	# --- 4. Push the ball forward ---
	ball.apply_central_force(car_mesh.global_transform.basis.z * speed_input)

	# --- 5. Lateral friction (only on the ground) ---
	if ground_ray.is_colliding():
		var forward_dir = car_mesh.global_transform.basis.z   # car's forward
		var velocity = ball.linear_velocity

		var forward_speed = velocity.dot(forward_dir)
		var lateral_vel = velocity - forward_dir * forward_speed

		var friction = lateral_friction
		var current_speed = velocity.length()

		# For drift, compare raw steer input (before deg_to_rad)
		var raw_steer = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
		if current_speed > drift_speed_threshold and abs(raw_steer) > drift_steer_threshold:
			friction *= drift_friction_factor

		ball.apply_central_force(-lateral_vel * friction)
