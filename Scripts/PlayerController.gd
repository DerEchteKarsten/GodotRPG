extends KinematicBody2D

export (float) var WALK_SPEED = 100
export (float) var DASH_DISTANCE = 100
export (float) var KockBack = 10

export(NodePath) var get_map_path
export(NodePath) var respawn_point

onready var map = get_node(get_map_path)
onready var anim = $AnimatedSprite
export var KockBackResistence = 1 

var last_anim := "_down"
var attacking := false
onready var Hitbox := $Area2D as Area2D 

var Health = 100
var MaxHealth = 100
var Damage = 10
var RegenTimer = 0

var dead = false
var IFrames = 0

var Velocity = Vector2(0,0) 
var attack_dir = Vector2(0,1) 
onready var swordHitbox = $SwordHitbox/Hitbox
onready var swordArea = $SwordHitbox
#var dirMap := {
#	Vector2(0, -1):"_up",
#	Vector2(0, -1):"_down",
#	Vector2(-1, 0):"_left",
#	Vector2(-1,-1):"_left",
#	Vector2(-1, 1):"_left",
#	Vector2(1, 0):"_right",
#	Vector2(1,-1):"_right",
#	Vector2(1, 1):"_right"
#}

onready var healthBar = get_node("/root/Scene/CanvasLayer/Node2D/TextureProgress") as TextureProgress

func _ready():
	healthBar.max_value = MaxHealth
	$Camera2D.limit_bottom = 32 * map.get("ChunkSize")
	$Camera2D.limit_right = 32 * map.get("ChunkSize")

func _process(delta):	
	if position.x > 32000 or position.x < 0 or position.y > 32000 or position.y < 0:
		on_death() 
	
	if IFrames > 0:
		IFrames -= 1
		anim.set_modulate(Color.red) 
	else:
		anim.set_modulate(Color.white)
	
	if RegenTimer > 0:
		RegenTimer -= delta
	else:
		RegenTimer = 0
	
	if RegenTimer == 0:
		Health += delta
	
	healthBar.value = Health
	
	var mouse = get_global_mouse_position()
	if Input.is_action_just_pressed("mouse_right"):
		if map.get_child(1).get_cell((mouse/32).x, (mouse/32).y) != TileMap.INVALID_CELL and map.get_child(0).get_cell((mouse/32).x, (mouse/32).y) == TileMap.INVALID_CELL:
			map.get_child(1).set_cellv(mouse/32, TileMap.INVALID_CELL)
			map.get_child(1).update_bitmask_area(mouse/32)
		elif map.get_child(0).get_cell((mouse/32).x, (mouse/32).y) != TileMap.INVALID_CELL:
			map.get_child(0).set_cellv(mouse/32, TileMap.INVALID_CELL)
			map.get_child(0).update_bitmask_area(mouse/32)
		
	if Input.is_action_just_pressed("mouse_left"):
		if map.get_child(0).get_cell((mouse/32).x, (mouse/32).y) == TileMap.INVALID_CELL and map.get_child(1).get_cell((mouse/32).x, (mouse/32).y) != TileMap.INVALID_CELL:
			map.get_child(0).set_cellv(mouse/32, 0)
			map.get_child(0).update_bitmask_area(mouse/32)
			map.get_child(1).set_cellv(mouse/32, 1)
			map.get_child(1).update_bitmask_area(mouse/32)
		elif map.get_child(1).get_cell((mouse/32).x, (mouse/32).y) == TileMap.INVALID_CELL:
			map.get_child(1).set_cellv(mouse/32, 1)
			map.get_child(1).update_bitmask_area(mouse/32)

func _physics_process(delta):
	if dead:
		return
		
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	var move_direction = Vector2(0,0)

		
	if map.get_child(1).get_cell(position.x / 32, position.y / 32) == TileMap.INVALID_CELL:
		move_direction = input_vector.normalized() * 0.5
		play_animation("swimm", input_vector)
	elif Input.is_action_just_pressed("ui_accept"): 
		attacking = true
		
		var mouse = get_global_mouse_position()
		attack_dir = (mouse - position).normalized().round()
		swordHitbox.position = attack_dir * 50
		
			
	elif attacking:
		var areas = swordArea.get_overlapping_areas() 
		for area in areas:
			var other = area.get_parent() as Node2D
			if not is_instance_valid(other):
				continue
			if other == self:
				continue
			on_attack(other)
		play_animation("attack", attack_dir)
	else:
		move_direction = input_vector.normalized()
		play_animation("walk", input_vector)
	
	Velocity *= 0.8
	move_and_slide(move_direction * WALK_SPEED + Velocity)
	

func play_animation(name: String, dir: Vector2):
	if dir.x == 0 and dir.y == 0:
		if name == "walk":
			anim.play("idle"+last_anim)
		else: 
			anim.play(name+last_anim)
	elif abs(dir.x) >= abs(dir.y):
		if dir.x > 0:
			last_anim = "_right"
			anim.play(name+ "_right")
		else:
			last_anim = "_left"
			anim.play(name+ "_left")
	elif abs(dir.x) < abs(dir.y):
		if dir.y > 0:
			last_anim = "_down"
			anim.play(name+ "_down")
		else:
			last_anim = "_up"
			anim.play(name+ "_up")
	return


func on_attack(other: Node2D):
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
	
	if other.get("IFrames") != 0:
		 return
		
	if other.has_method("on_damage"):
		other.on_damage(Damage)

func on_damage(damage: float):
	Health -= damage
	IFrames = 10
	if Health < 0:
		on_death()

func on_death():
	dead = true
	anim.play("death")

func on_respawn():
	position = get_node(respawn_point).position
	Health = MaxHealth
	dead = false

func _on_Area2D_area_entered(area: Area2D):
	var other = area.get_parent()
	if other == self:
		return
	if IFrames != 0:
		return
		
	if other.has_method("on_attack"):
		other.on_attack(self)

func _on_AnimatedSprite_animation_finished():
	if anim.animation == "attack_up" or anim.animation == "attack_down" or anim.animation == "attack_left" or anim.animation == "attack_right":
		 attacking = false
	if anim.animation == "death":
		 dead = false
		 on_respawn()
