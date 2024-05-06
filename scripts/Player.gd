extends CharacterBody3D

var speed : float
const RUN_SPEED := 8.5
const WALK_SPEED := 5.0
const JUMP_VELOCITY := 4.5

var gravity := 9.8

var pivot = preload("res://scenes/player/pivot.tscn")
var neck: Node3D
var camera: Camera3D

# MOUSE
const SENSITIVITY = 0.008

# PASSOS
const BOB_FREQUENCY = 2.5
const BOB_AMPLTIUDE = 0.05
var t_bob = 0.0


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int(), true)
	if is_multiplayer_authority():
		neck = pivot.instantiate()
		add_child(neck)
		camera = neck.find_child("Camera3D")
		$Name_Label.hide()
		
	#var ma = "AUTHORITY" if is_multiplayer_authority() else "NOT AUTHORITY"
	#print(name + " entered the tree: " + ma)
	$Name_Label.text = name
	
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * SENSITIVITY)
			$MeshInstance3D.rotation = neck.rotation
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))
			
			
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if Input.is_action_pressed("run"):
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED
		
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLTIUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLTIUDE
	
	return pos
	
	
