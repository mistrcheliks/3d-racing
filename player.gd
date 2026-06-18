extends Node3D

@onready var ball = $Ball
@onready var car_mesh = $sedan
@onready var ground_ray = $GroundRay

# ЭТА ПЕРЕМЕННАЯ НУЖНА ДЛЯ КАМЕРЫ.
# Она дублирует скорость физического шара, чтобы камера могла её прочитать.
var linear_velocity: Vector3 = Vector3.ZERO

var sphere_offset = Vector3(0,-1,0)
var acceleration = 100
var steering = 15.0
var turn_speed = 3
var turn_stop_limit = 0.75

var speed_input = 0
var rotate_input = 0

func _ready():
	ground_ray.add_exception(ball)
	
func _physics_process(_delta):
	car_mesh.transform.origin = ball.transform.origin + sphere_offset
	ball.apply_central_force(car_mesh.global_transform.basis.z * speed_input)

func _process(delta):
	if not ground_ray.is_colliding():
		return
	
	speed_input = 0
	speed_input += Input.get_action_strength("throttle")
	speed_input -= Input.get_action_strength("brake")
	speed_input *= acceleration
	
	rotate_input = 0
	rotate_input -= Input.get_action_strength("steer_left")
	rotate_input += Input.get_action_strength("steer_right")
	rotate_input *= rad_to_deg(steering)
	
	if ball.linear_velocity.length() > turn_stop_limit:
		var current_quat = car_mesh.global_transform.basis.get_rotation_quaternion()
		var axis = car_mesh.global_transform.basis.y.normalized()   # ось Y автомобиля
		var delta_quat = Quaternion(axis, rotate_input)
		var new_quat = current_quat * delta_quat
		var final_quat = current_quat.slerp(new_quat, turn_speed * delta)
		var current_scale = car_mesh.global_transform.basis.get_scale()
		car_mesh.global_transform.basis = Basis(final_quat).scaled(current_scale)
