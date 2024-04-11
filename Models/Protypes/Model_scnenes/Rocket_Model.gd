extends RigidBody3D

var Damage: int = 0



func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Target") && body.has_method("Hit_successful"):
		body.Hit_Successful(Damage)
		queue_free()
	
	queue_free()
