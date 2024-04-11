extends RigidBody3D

var health = 5

func Hit_Successful(Damage):
	health -= Damage
	print("Target Health: " + str(health))
	if health <= 0:
		queue_free()
