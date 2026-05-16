extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

@onready var camera := $Camera3D
@onready var visor := $Camera3D/MeshInstance3D

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

# grab camera
func _ready() -> void:
	if is_multiplayer_authority():
		camera.make_current()
		visor.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
