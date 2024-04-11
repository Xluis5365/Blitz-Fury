extends Node3D

@onready var animation_player: AnimationPlayer = get_node("%AnimationPlayer")

var Current_Weapon : WeaponResource = null

var Weapon_Stack = [] # an array of weapons currently held by the player

var Weapon_Indicator = 0 

var Next_Weapon: String

var Weapon_List = {}

@export var _weapon_resources : Array[WeaponResource]

@export var Start_Weapons : Array[String]

func _ready() -> void:
	initialize(Start_Weapons) #enter the state machine

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Weapon_Up"):
		Weapon_Indicator = min(Weapon_Indicator+1, Weapon_Stack.size()-1)
		exit(Weapon_Stack[Weapon_Indicator])
	
	if event.is_action_pressed("Weapon_Down"):
		Weapon_Indicator = max(Weapon_Indicator-1, 0)
		exit(Weapon_Stack[Weapon_Indicator])
	



func initialize(_start_weapon : Array):
	#Creating a dictionary to refer to our weapons
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
	
	for i in _start_weapon:
		Weapon_Stack.push_back(i) # add out start weapons
	
	Current_Weapon = Weapon_List[Weapon_Stack[0]] # Set the first weapon in the stack to current
	enter()

	
func enter(): # call when first "entering" into a weapon
	animation_player.play(Current_Weapon.Activate_Anim)

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
