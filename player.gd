extends Node3D

@onready var ball = $Ball
@onready var car_mesh = $sedan
@onready var ground_ray = $GroundRay

var sphere_offset = Vector3(0, -1, 0)

var acceleration = 120
var steering = 15.0      # максимальный угол поворота в градусах
var turn_speed = 10
var turn_stop_limit = 0.15

var speed_input = 0
var rotate_input = 0

func _ready():
	ground_ray.add_exception(ball)

func _process(_delta):
	# Считываем ввод каждый кадр - реакция на клавиши должна быть мгновенной
	if not ground_ray.is_colliding():
		# В воздухе сбрасываем газ и руль, чтобы машина не продолжала
		# "разгоняться" и поворачивать, пока летит
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
	# Синхронизация видимой модели с физическим шаром
	car_mesh.transform.origin = ball.transform.origin + sphere_offset

	# Двигатель: толкаем шар в направлении, куда смотрит кузов
	ball.apply_central_force(car_mesh.global_transform.basis.z * speed_input)

	# Поворот - только если машина реально движется
	if ball.linear_velocity.length() > turn_stop_limit:
		var current_quat = car_mesh.global_transform.basis.get_rotation_quaternion()
		var axis = car_mesh.global_transform.basis.y.normalized()
		var delta_quat = Quaternion(axis, rotate_input)
		var new_quat = current_quat * delta_quat
		var final_quat = current_quat.slerp(new_quat, turn_speed * delta)

		var current_scale = car_mesh.global_transform.basis.get_scale()
		car_mesh.global_transform.basis = Basis(final_quat).scaled(current_scale)
