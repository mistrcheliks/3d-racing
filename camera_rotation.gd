extends Node3D

# Перетащите сюда ваш PhantomCamera3D из дерева сцены
@onready var pcam: PhantomCamera3D = $"../PhantomCamera3D"

@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.1

# Ограничения для вертикального вращения (ось X), чтобы камера не переворачивалась
@export var min_pitch: float = -45.0
@export var max_pitch: float = 30.0

func _ready() -> void:
	# Прячем курсор мыши и захватываем его в окне игры
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Проверяем, двигалась ли мышь
	if event is InputEventMouseMotion:
		# 1. Получаем текущие углы вращения из Phantom Camera
		var current_rotation: Vector3 = pcam.get_third_person_rotation_degrees()
		
		# 2. Вычисляем новое вращение на основе движения мыши
		# Горизонтальное вращение (Yaw - ось Y)
		var yaw: float = current_rotation.y - event.relative.x * mouse_sensitivity
		
		# Вертикальное вращение (Pitch - ось X)
		var pitch: float = current_rotation.x - event.relative.y * mouse_sensitivity
		
		# 3. Ограничиваем вертикальный угол (чтобы не смотреть строго под землю или в небо)
		pitch = clamp(pitch, min_pitch, max_pitch)
		
		# 4. Применяем новые значения обратно в Phantom Camera
		pcam.set_third_person_rotation_degrees(Vector3(pitch, yaw, 0))

func _process(_delta: float) -> void:
	# Возвращаем курсор по нажатию клавиши Esc (для удобства отладки)
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
