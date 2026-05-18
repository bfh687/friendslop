extends CharacterBody3D

const BASE_SPEED = 5.0
const SPRINT_SPEED = 8.0

const BASE_FOV = 75.0
const SPRINT_FOV = 85.0
const ZOOM_FOV = 40.0

const DECELERATION = 8.0

const JUMP_VELOCITY = 3.75
const MOUSE_SENSITIVITY = 0.002

const BOB_FREQUENCY = 24.0
const BOB_AMPLITUDE = 0.03

const FALL_MULTIPLIER = 1.75

@onready var camera := $Camera3D
@onready var visor := $Camera3D/MeshInstance3D

var is_sprinting: bool = false
var bob_time: float = 0.0

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if is_multiplayer_authority():
		camera.make_current()
		visor.visible = false
		# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera.clear_current()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)  # left/right on player
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)  # up/down on camera
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)  # prevent flipping

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	update_velocity(delta)
	update_camera(delta)
	move_and_slide()
	
func update_velocity(delta: float) -> void:
	# jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		
	# gravity
	if not is_on_floor():
		if velocity.y < 0:
			velocity += get_gravity() * delta * FALL_MULTIPLIER
		else:
			velocity += get_gravity() * delta

	# wasd movement + sprinting
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	is_sprinting = Input.is_action_pressed("sprint") and direction
	var current_speed = SPRINT_SPEED if is_sprinting else BASE_SPEED
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		velocity.z = move_toward(velocity.z, 0, DECELERATION)

func update_camera(delta) -> void: 
	# camera sprint fov
	var target_fov := ZOOM_FOV if Input.is_action_pressed("zoom") else (SPRINT_FOV if is_sprinting else BASE_FOV)
	camera.fov = lerp(camera.fov, target_fov, 0.15)
	
	# camera bobbing
	if is_sprinting and is_on_floor():
		bob_time += delta
		camera.position.y = sin(bob_time * BOB_FREQUENCY) * BOB_AMPLITUDE
	else:
		bob_time = 0.0
		camera.position.y = lerp(camera.position.y, 0.0, delta * 8.0)
