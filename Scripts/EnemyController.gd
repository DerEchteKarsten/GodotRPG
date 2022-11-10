extends KinematicBody2D

class_name Enemy

var Velocity = Vector2(0,0)

export var Damage = 10
export var Health = 50
export var MaxHealth = 50
export var MovmentSpeed = 100
export var Sight = 500
export var KockBack = 100
export var KockBackResistence = 1
export (NodePath) var player_Path
export (NodePath) var map_Path
var IFrames = 0 
var RegenTimer = 0
var Blink = true

onready var Player := get_node(player_Path) as KinematicBody2D
onready var SandMap := get_node(map_Path) as TileMap

enum {
	Wandering,
	Waiting,
	Traking,
}

var state := Traking
var WanderTarget = position + Vector2(10,10)  
var WaitTimer = 0
var WaterFactor = 1

func _ready():
	pass
	
func _physics_process(delta):
	if MovmentSpeed == 0:
		return
	var MoveDir = Vector2(0,0)
	
	if SandMap.get_cell(position.x/32, position.y/32) == TileMap.INVALID_CELL:
		WaterFactor = 0.5
	else:
		WaterFactor = 1
	match state:
			Traking:
				MoveDir = (position - Player.position).normalized() * MovmentSpeed * delta * -100
				move_and_slide((MoveDir+Velocity)*WaterFactor)
				#print_debug("Traking")
			Waiting:
				move_and_slide(Velocity*WaterFactor)
				#print_debug("Waiting")
			Wandering:
				MoveDir = (position - WanderTarget).normalized() * MovmentSpeed * delta * -100
				move_and_slide((MoveDir+Velocity) * 0.5* WaterFactor)
				#print_debug("Wandering")
	Velocity *= 0.8

func _process(delta):
	if WaitTimer > 0:
		WaitTimer -= delta
	else:
		WaitTimer = 0
		
	if RegenTimer > 0:
		RegenTimer -= delta
	else:
		RegenTimer = 0
		
	if IFrames > 0:
		IFrames -= 1
		if Blink:
			$Sprite.set_modulate(Color.red) 
	else:
		if Blink:
			$Sprite.set_modulate(Color.white)
	
	if RegenTimer == 0:
		Health += delta
	
	if MovmentSpeed == 0:
		return
	if (position - Player.position).length() < Sight and not Player.get("dead"):
		state = Traking
	elif state != Wandering and state != Waiting:
		state = Wandering
		randomize()
		WanderTarget = position + Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * rand_range(100, 2000)
	elif (WanderTarget - position).length() < 2:
		randomize()
		if state != Waiting:
			WaitTimer = rand_range(0.5,5)
			state = Waiting
	if WaitTimer == 0 and state == Waiting:
		randomize()
		WanderTarget = position + Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * rand_range(100, 2000)
		state = Wandering


func on_death():
	queue_free()

func defaultAttackBehauvior(other: Node2D):
	other.set("RegenTimer", 10)
	var velocity = other.get("Velocity")
	var delta = other.position - position
	var res = other.get("KockBackResistence")
	var knock_amount
	if res == null:
		knock_amount = delta.normalized() * KockBack * 10
	else:
		knock_amount = delta.normalized() * KockBack * 10 * res
	if velocity != null:
		velocity += knock_amount
		other.set("Velocity", velocity)
	
	if other.has_method("on_damage"):
		other.on_damage(Damage)

func defaultDamageBehauvior(damage: float):
	IFrames = 10
	Health -= damage
	if Health < 0:
		on_death()

func on_damage(damage: float):
	defaultDamageBehauvior(damage)

func on_attack(other: Node2D):
	defaultAttackBehauvior(other)
