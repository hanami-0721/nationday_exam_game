extends CharacterBody2D

@export_category("移动参数")
@export var double_press_interval := 0.3
@export var move_speed: float = 75.0
@export var acceleration: float = 600.0
@export var deceleration: float = 800.0
@export var jump_velocity: float = -190.0
@export var max_jumps := 2
@export var dash_speed: float = 240.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45


@onready var sprite: Sprite2D = $Sprite2D
@onready var lives_label: Label = $UI/LivesLabel

var flying : bool = false
var last_space_press_time := -1000
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := 1.0
var jumps_left := 0
var lives := 5

func _ready() -> void:
	update_lives_label()

func _physics_process(delta: float) -> void:

	dash_timer = maxf(dash_timer - delta, 0.0)
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

	if dash_timer > 0.0:
		velocity.x = dash_direction * dash_speed
		velocity.y = 0.0
		update_sprite_direction()
		move_and_slide()
		return

	if !flying:
		apply_gravity(delta)
		if is_on_floor():
			jumps_left = max_jumps
		handle_jump()
	else:
		handle_vertical_movement(delta)
	
	handle_horizontal_movement(delta)
	update_sprite_direction()
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_vertical_movement(delta:float) -> void:
	var direction := Input.get_axis("squat", "jump")
	var target_speed := direction * jump_velocity
	
	if direction != 0.0:
		velocity.y = move_toward(
				velocity.y,
				target_speed,
				acceleration * delta
		)
	else:
		velocity.y = move_toward(
				velocity.y,
				0.0,
				acceleration * delta
		)
	
func handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * move_speed

	if direction != 0.0:
		velocity.x = move_toward(
				velocity.x,
				target_speed,
				acceleration * delta
		)
	else:
		velocity.x = move_toward(
				velocity.x,
				0.0,
				deceleration * delta
		)

func handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return

	if is_on_floor():
		velocity.y = jump_velocity
		jumps_left = max_jumps - 1
	elif jumps_left > 0:
		velocity.y = jump_velocity
		jumps_left -= 1

func update_sprite_direction() -> void:
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fly") and !event.is_echo():
		handle_space_pressed()
	elif event.is_action_pressed("dash") and !event.is_echo():
		start_dash()
	
func handle_space_pressed() -> void:
	var current_time := Time.get_ticks_msec()
	var elapsed_time := current_time - last_space_press_time

	if elapsed_time <= double_press_interval * 1000.0:
		flying = not flying
		last_space_press_time = -1000
	else:
		last_space_press_time = current_time

func start_dash() -> void:
	if dash_cooldown_timer > 0.0 or dash_timer > 0.0:
		return

	if velocity.x != 0.0:
		dash_direction = signf(velocity.x)
	else:
		dash_direction = -1.0 if sprite.flip_h else 1.0

	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

func take_damage() -> void:
	if lives <= 0:
		return

	lives -= 1
	print("生命 -1，剩余生命：", lives)
	update_lives_label()
	if lives <= 0:
		print("失败")

func on_victory() -> void:
	print("胜利！")

func update_lives_label() -> void:
	lives_label.text = "当前生命：" + str(lives)
