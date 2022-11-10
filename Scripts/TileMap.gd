tool
extends Node2D

export var ChunkSize = 100
export var Octaves = 9
export (float) var Size = 1

export var Generate = false setget generate 

var noise : OpenSimplexNoise
var tree := preload("res://enemys/Tree.tscn")
var once = true

const GRASS := 0
const LIGHTWATER := 4
const WATER := 2
const DEEPWATER := 3
const SAND := 1

export var WaterLevel = 0.1

func generate(new = false):
	if once:
		once = false
		return

	if noise == null:
		noise = OpenSimplexNoise.new()
		
	noise.octaves = Octaves

	var GrassMap := $GrassMap as TileMap
	var SandMap := $SandMap as TileMap
	var WaterMap := $WaterMap as TileMap
	var Objects := $Entitys
	var Player := get_node("Entitys/Player")
	#GrassMap.clear()
	#SandMap.clear()
	#WaterMap.clear()
	for c in Objects.get_children():
		if c.name == "Player":
			continue
		c.queue_free()
	
	for x in 0:
		for y in 0: 
			var val = noise.get_noise_2d(x*Size,y*Size)
			if val < WaterLevel-0.1:
				WaterMap.set_cell(x,y,DEEPWATER)
			elif val < WaterLevel:
				WaterMap.set_cell(x,y,WATER)
			elif val < WaterLevel+0.05:
				WaterMap.set_cell(x,y,LIGHTWATER)
			elif val < WaterLevel+0.11:
				SandMap.set_cell(x,y,SAND)
				SandMap.update_bitmask_area(Vector2(x,y))
				WaterMap.set_cell(x,y,LIGHTWATER)
			else:
				GrassMap.set_cell(x,y,GRASS)
				GrassMap.update_bitmask_area(Vector2(x,y))
				SandMap.set_cell(x,y,SAND)
				SandMap.update_bitmask_area(Vector2(x,y))
				WaterMap.set_cell(x,y,LIGHTWATER)
				
	for x in ChunkSize/4:
		for y in ChunkSize/4:
			if randi() % 2 == 0 and noise.get_noise_2d(x*2+1000,y*2+1000) > 0.05 and GrassMap.get_cell(x*4,y*4) == GRASS:
						var inst := tree.instance() 
						inst.position = Vector2(x*32*4, y*32*4) + Vector2(rand_range(-20,20), rand_range(-20,20))
						inst.set("map_Path", SandMap.get_path())
						inst.set("player_Path", Player.get_path())
						Objects.add_child(inst)
						inst.set_owner(get_tree().edited_scene_root)
