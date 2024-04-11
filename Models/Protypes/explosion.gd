extends Node3D

@onready var spark : GPUParticles3D = get_node("%Spark")
@onready var flash: GPUParticles3D = $Flash
@onready var fire: GPUParticles3D = $Fire
@onready var smoke: GPUParticles3D = $Smoke
@onready var area_3d: Area3D = $Area3D

func _enter_tree() -> void:
	pass
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spark.emitting = true
	flash.emitting = true
	fire.emitting = true
	smoke.emitting = true
	area_3d.connect("body_entered", body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if smoke.emitting == false:
		queue_free()

func body_entered(body: Node3D):
	var speed := 5.0
	var air_speed := 15.0
	var vector := body.global_transform.origin - global_transform.origin
	var direction := vector.normalized()
	var distance := vector.length_squared()
	
	var velocity := direction * speed/distance
	var air_velocity := direction * air_speed/distance
	if body is CharacterBody3D:
		if body.is_on_floor():
			body.velocity += velocity
		if body.is_on_floor() == false:
			body.velocity += air_velocity
