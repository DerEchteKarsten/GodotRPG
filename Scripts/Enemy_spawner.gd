extends Node2D

export var MAX_ENEMIES = 50
var enemys = 0

var Mumie := preload("res://enemys/Mumie.tscn")

onready var player = $Player
onready var sandMap = get_node("../SandMap")

func _ready():
	randomize()

func _process(delta):
	if enemys < MAX_ENEMIES:
		var inst = Mumie.instance()
		inst.set("map_Path", sandMap.get_path())
		inst.set("player_Path", player.get_path())
		var rand 
		while true:
			rand = roll()
			if sandMap.get_cellv((player.position + rand) / 32) != TileMap.INVALID_CELL:
				break
	
		inst.position = rand + player.position
		add_child(inst)
		inst.connect("child_exiting_tree", self, "on_kill")
		enemys += 1

func roll() -> Vector2:
	var rand = Vector2(rand_range(500,10000), rand_range(500,10000))
	if rand_range(0,1) > 0.5:
		rand *= -1
	return rand

func on_kill():
	enemys -= 1
