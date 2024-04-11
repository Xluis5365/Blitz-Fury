extends CharacterBody3D

#Player Nodes

@onready var neck: Node3D = $neck
@onready var head: Node3D = $neck/head
@onready var camera_3d: Camera3D = $neck/head/eyes/Camera3D
@onready var eyes: Node3D = $neck/head/eyes

@onready var standing_mesh: MeshInstance3D = $Standing_Mesh
@onready var crouched_mesh: MeshInstance3D = $Crouched_Mesh

@onready var standing_collision_shape: CollisionShape3D = $Standing_Collision_Shape
@onready var crouched_collision_shape: CollisionShape3D = $Crouched_Collision_Shape
@onready var ray_cast_3d: RayCast3D = $RayCast3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Speed Vars

var current_speed = 8.0

const WALKING_SPEED = 4.0
const SPRINTING_SPEED = 8.0
const CROUCHING_SPEED = 2.0

# States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

#Head bobbing vars
const HEAD_BOBBING_SPRINTING_SPEED = 22.0
const HEAD_BOBBING_WALKING_SPEED = 14.0
const HEAD_BOBBING_CROUCHING_SPEED = 10.0

const HEAD_BOBBING_SPRINTING_INTENSITY = 0.2
const HEAD_BOBBING_WALKING_INTENSITY = 0.1
const HEAD_BOBBING_CROUCHING_INTENSITY = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

# Slide Vars
var slide_timer = 0.0
var slide_timer_max = 1.5
var slide_vector = Vector2.ZERO
var slide_speed = 6.0

#Movement Vars

var crouching_depth = -0.517
var JUMP_VELOCITY = 3.5
var lerp_speed = 10.0

var free_loop_tilt_amount = 7

#Input Vars

var mouse_sens = 0.12
var direction = Vector3.ZERO


#Movement Acceleration

const GROUND_ACCEL = 45
const AIR_ACCEL = 56
const FRICTION = 7
const MAX_SPEED = 13.0
const MAX_SPEED_AIR = 30.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Setting movement input
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	
	
	#Handle Movement state
	
	#Crouching
	if Input.is_action_pressed("crouch") or sliding:
		current_speed = CROUCHING_SPEED
		head.position.y = lerp(head.position.y,crouching_depth, delta * lerp_speed)
		standing_collision_shape.disabled = true
		crouched_collision_shape.disabled = false
		standing_mesh.visible = false
		crouched_mesh.visible = true
		
		# Slide begin logic
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			print("Slide Begin")
		
		
		walking = false
		sprinting = false
		crouching = true

		#Standing
	elif !ray_cast_3d.is_colliding():
		standing_collision_shape.disabled = false
		crouched_collision_shape.disabled = true
		standing_mesh.visible = true
		crouched_mesh.visible = false
		head.position.y = lerp(head.position.y,0.0, delta * lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			current_speed = SPRINTING_SPEED
			
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = WALKING_SPEED
			
			walking = true
			sprinting = false
			crouching = false

	# Handle Free Look
	if Input.is_action_pressed("free_look") or sliding:
		free_looking = true
		if sliding:
			camera_3d.rotation.z = lerp(camera_3d.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		else:
			camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_loop_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)
	
	# Handle Sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			print("Slide End")
			free_looking = false
	
	# Handle headbobbing
	if sprinting:
		head_bobbing_current_intensity = HEAD_BOBBING_SPRINTING_INTENSITY
		head_bobbing_index += HEAD_BOBBING_SPRINTING_SPEED * delta
	elif walking:
		head_bobbing_current_intensity = HEAD_BOBBING_WALKING_INTENSITY
		head_bobbing_index += HEAD_BOBBING_WALKING_SPEED * delta
	elif crouching:
		head_bobbing_current_intensity = HEAD_BOBBING_CROUCHING_INTENSITY
		head_bobbing_index += HEAD_BOBBING_CROUCHING_SPEED * delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intensity/2.0), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*head_bobbing_current_intensity, delta*lerp_speed)
	
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)
	
	

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sliding = false
	
	# Handle Idle animations
	#if input_dir == Vector2.ZERO and is_on_floor():
		#anim_player.play("blaster_withscope_idle")
	#else:
		#anim_player.play("RESET")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (slide_timer + 0.1) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.1) * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	if is_on_floor() && !sliding:
		velocity = accelerate(direction, delta, GROUND_ACCEL, MAX_SPEED)
		#apply friction
		var speed = velocity.length()
		if speed != 0:
			var drop = speed * FRICTION * delta
			velocity *= max(speed - drop, 0) / speed
	
	else:
		velocity = accelerate(direction, delta, AIR_ACCEL, MAX_SPEED_AIR)
		velocity.y -= gravity * delta #adds the gravity
		
		
	move_and_slide()

func accelerate(dir, delta, accel_type, max_velocity):
	var proj_vel = velocity.dot(dir)
	$CanvasLayer/VBoxContainer/HBoxContainer4/Proj_vel.text = str(proj_vel)
	$CanvasLayer/VBoxContainer/HBoxContainer5/Actual_vel.text = str(velocity.length())
	var accel_vel = accel_type * delta
	
	if (proj_vel + accel_vel > max_velocity):
		accel_vel = max_velocity - proj_vel
	
	return velocity + (dir * accel_vel)
