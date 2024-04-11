extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var animation_player: AnimationPlayer = get_node("%AnimationPlayer")
@onready var bullet_point: Marker3D = get_node("FPS_Rig/Bullet_Point")


var Debug_Bullet = preload("res://Scripts/Resource Scripts/Weapon Resource/bullet_debug.tscn")
var Explosion = preload("res://Models/Protypes/explosion.tscn")

var Current_Weapon : WeaponResource = null

var Weapon_Stack = [] # an array of weapons currently held by the player

var Weapon_Indicator = 0 

var Next_Weapon: String

var Weapon_List = {}

@export var _weapon_resources : Array[WeaponResource]

@export var Start_Weapons : Array[String]

enum {NULL, HITSCAN, PROJECTILE}

func _ready() -> void:
	initialize(Start_Weapons) #enter the state machine

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Weapon_Up"):
		Weapon_Indicator = min(Weapon_Indicator+1, Weapon_Stack.size()-1)
		exit(Weapon_Stack[Weapon_Indicator])
	
	if event.is_action_pressed("Weapon_Down"):
		Weapon_Indicator = max(Weapon_Indicator-1, 0)
		exit(Weapon_Stack[Weapon_Indicator])
	

 	
	if event.is_action_pressed("Reload"):
		reload()

func _process(delta: float) -> void:
	if Input.is_action_pressed("Shoot"):
		shoot()

func initialize(_start_weapon : Array):
	#Creating a dictionary to refer to our weapons
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
	
	for i in _start_weapon:
		Weapon_Stack.push_back(i) # add out start weapons
	
	Current_Weapon = Weapon_List[Weapon_Stack[0]] # Set the first weapon in the stack to current
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	enter()

	
func enter(): # call when first "entering" into a weapon
	animation_player.play(Current_Weapon.Activate_Anim)
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	

func exit(_next_weapon : String):# in order to change weapon first call exit
	if _next_weapon != Current_Weapon.Weapon_Name:
		if animation_player.get_current_animation() != Current_Weapon.Deactivate_Anim:
			animation_player.play(Current_Weapon.Deactivate_Anim)
			Next_Weapon = _next_weapon

func Change_Weapon(weapon_name : String):
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == Current_Weapon.Deactivate_Anim:
		Change_Weapon(Next_Weapon)

func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if !animation_player.is_playing(): # enforces the DPS by the animation lenght
			animation_player.play(Current_Weapon.Shoot_Anim)
			Current_Weapon.Current_Ammo -= 1
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			var Camera_Collision = get_camera_collision()
			match Current_Weapon.Type:
				NULL:
					print("weapon type not chosen")
				HITSCAN:
					Hit_Scan_Collistion(Camera_Collision)
				PROJECTILE:
					Launch_Projectile(Camera_Collision)
			
	elif Current_Weapon.Current_Ammo == 0 && Current_Weapon.Reserve_Ammo != 0:
		if Input.is_action_just_pressed("Shoot"):
			reload()


func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif !animation_player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			animation_player.play(Current_Weapon.Reload_Anim)
			var Reload_Amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo, Current_Weapon.Magazine, Current_Weapon.Reserve_Ammo)
			
			Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo + Reload_Amount
			Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo - Reload_Amount
			
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
		else:
			animation_player.play(Current_Weapon.Out_of_Ammo)

func get_camera_collision() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2) * Current_Weapon.Weapon_Range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Col_Point = Intersection.position
		return Col_Point
	else:
		return Ray_End

func Hit_Scan_Collistion(Collision_Point):
	var Bullet_Direction = (Collision_Point - bullet_point.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(bullet_point.get_global_transform().origin, Collision_Point+Bullet_Direction*2)
	
	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Bullet_Collision:
		var Hit_Indicator = Debug_Bullet.instantiate()
		var world = get_tree().get_root().get_child(0)
		world.add_child(Hit_Indicator)
		Hit_Indicator.global_translate(Bullet_Collision.position)
		Hit_Scan_Damage(Bullet_Collision.collider)
	
	

func Hit_Scan_Damage(Collider):
	if Collider.is_in_group("Target") and  Collider.has_method("Hit_Successful"):
		Collider.Hit_Successful(Current_Weapon.Damage)


func Launch_Projectile(Point: Vector3):
	var Direction = (Point - bullet_point.get_global_transform().origin).normalized()
	var Projectile = Current_Weapon.Projectile_To_Load.instantiate()
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(bullet_point.get_global_transform().origin, Point+Direction*2)
	
	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Bullet_Collision:
		var Explosion = Explosion.instantiate()
		var world = get_tree().get_root().get_child(0)
		world.add_child(Explosion)
		Explosion.global_translate(Bullet_Collision.position)
		Hit_Scan_Damage(Bullet_Collision.collider)
		Projectile.queue_free()
	
	bullet_point.add_child(Projectile)
	Projectile.Damage = Current_Weapon.Damage
	Projectile.set_linear_velocity(Direction * Current_Weapon.Projectile_Velocity)
	
	
	
