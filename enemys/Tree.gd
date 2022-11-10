extends Enemy

func _ready():
	Damage = 0
	Health = 100
	MaxHealth = 100
	MovmentSpeed = 0
	Sight = 0
	KockBack = 0
	KockBackResistence = 0
	Blink = false

func on_attack(other: Node2D):
	pass

func on_damage(damage: float):
	defaultDamageBehauvior(damage) 
