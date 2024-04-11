extends Node3D

@onready var animation_player: AnimationPlayer = get_node("%AnimationPlayer")

var Current_Weapon = null

var Weapon_Stack = [] # an array of weapons currently held by the player

var Next_Weapon: String

var Weapon_List = {}

@export var _weapon_resources : Array[WeaponResource]

@export var Start_Weapon : Array[String]

func _ready() -> void:
	initialize(Start_Weapon) #enter the state machine
	

func initialize(_start_weapon : Array):
	#Creating a dictionary to refer to our weapons
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
	
	for i in _start_weapon:
		Weapon_Stack.push_back(i) # add our start weapons
	
	Current_Weapon = Weapon_List[Weapon_Stack[0]] # Set the first weapon in the stack to current
	enter()

	
func enter(): # call when first "entering" into a weapon
	animation_player.queue(Current_Weapon.Activate_Anim)

func exit():# in order to change weapon first call exit
	pass

func Change_Weapon():
	pass
