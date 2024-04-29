extends CharacterBody3D

var speed
const RUN_SPEED = 8.5
const WALK_SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity: float = 9.8

@onready var neck := $Pivot
@onready var camera := $Pivot/Camera3D
#@onready var flashlight := $Pivot/Camera3D/Flashlight

#@export var footstep_sounds : Array[AudioStreamOggVorbis]
#@export var footstep_player : AudioStreamPlayer3D

# MOUSE
const SENSITIVITY = 0.008

# PASSOS
const BOB_FREQUENCY = 2.0
const BOB_AMPLTIUDE = 0.2
var t_bob = 0.0

# SONS PASSOS
#const WALK_VOLUME = -25.0
#const RUN_VOLUME = -20.0
#var can_play = true
#signal step

# LANTERNA
#const LIGHT_ON = 280
#const LIGHT_OFF = 0 
#var light_status := true
#
#var power_off := false

func _ready():
	pass
	#light_group = get_tree().get_nodes_in_group("lights_power_off")
	#flickering_lights_group = get_tree().get_nodes_in_group("flickering_lights")
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))
			
			#flashlight.rotation.x = camera.rotation.y
			#flashlight.rotation.y = neck.rotation.x
			
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("A", "D", "W", "S")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if Input.is_action_pressed("shift"):
		speed = RUN_SPEED
		#footstep_player.volume_db = RUN_VOLUME
	else:
		speed = WALK_SPEED
		#footstep_player.volume_db = WALK_VOLUME
		
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	#flashlight.transform.origin = _headbob(t_bob) * 0.6
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLTIUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLTIUDE
	
	# SOM DOS PASSOS
	#var low_pos = BOB_AMPLTIUDE - 0.05
	## reseta quando dá um passo (saiu do ponto mais baixo)
	#if pos.y > -low_pos:
		#can_play = true
	#
	#if pos.y < -low_pos and can_play: 
		#can_play = false
		#var random_index = randi_range(0, footstep_sounds.size() - 1)
		#footstep_player.stream = footstep_sounds[random_index]
		#footstep_player.pitch_scale = randf_range(0.8, 1.2)
		#footstep_player.play()
	return pos
	
	
