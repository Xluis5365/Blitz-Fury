extends Resource

class_name WeaponResource

@export var Weapon_Name : String
@export var Activate_Anim : String
@export var Deactivate_Anim : String
@export var Shoot_Anim : String
@export var Reload_Anim : String
@export var Out_of_Ammo : String

@export var Current_Ammo: int
@export var Reserve_Ammo: int
@export var Magazine: int
@export var Max_Ammo: int
@export var Infinite_Ammo : bool
@export var Damage : int
@export var Pick_Up_Ammo : int
@export_flags("Hitscan", "Projectile") var Type
@export var Projectile_To_Load : PackedScene
@export var Weapon_Range : int
@export var Projectile_Velocity: int
