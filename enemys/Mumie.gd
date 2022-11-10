extends Enemy

func _ready():
	pass 

func on_attack(other: Node2D):
	defaultAttackBehauvior(other)

func on_damage(damage: float):
	defaultDamageBehauvior(damage)
