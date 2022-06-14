extends Node2D

var level = {}
var rng = RandomNumberGenerator.new()
var tile_chance = []
var event_room_aray = []

var right = Vector2(1,0); var left = Vector2(-1,0); var down = Vector2(0,1); var up = Vector2(0,-1)
var generic_room = load("res://Level Generation/Room.tscn")
var enemy_karen = load("res://Enemies/Karen.tscn")
var event_box = load("res://Tasks/CardboardBox.tscn")

#var tilemap = load("res://Level Generation/PremadeTileMaps/TileMap" + str(randi() % 2 + 1) + ".tscn")
var ROOM_DIMENSIONS = 8
var CURR_ENEMIES = 0
var MAX_ENEMIES = 14
var CURR_EVENTS = 0
var MAX_EVENTS = 12

var max_vector_x = 0; var min_vector_x = 0
var max_vector_y = 0; var min_vector_y = 0
export(float) var t1_float = 10; export(float) var t2_float = 30; export(float) var t3_float = 60


onready var map_node = $MapNode

func _ready():
	level = LevelGeneration.generate(0)
	load_map()
	
func fill_tile_chance_array():
	var max_size = 100
	for i in range(max_size):
		if 0 < t1_float:
			tile_chance.append(1)
			t1_float -= 1
		elif 0 < t2_float:
			tile_chance.append(2)
			t2_float -= 1
		elif 0 < t3_float:
			tile_chance.append(3)
			t3_float -= 1
	
func set_tilemap(room):
	var i = randi() % 100
	var tilemap_num = tile_chance[i]
	
	room.tilemap = tilemap_num
	
	
func load_tilemap(room):
	var tilemap_num = room.tilemap
	
	if tilemap_num == 3:
		#If right and left both exist and are shelf tiles
		if room.connected_rooms[right] != null && room.connected_rooms[left] != null:
			if floor(room.connected_rooms[right].tilemap) == 3 && floor(room.connected_rooms[left].tilemap) == 3:
				tilemap_num = 3.9
		
		#If right exists but left doesn't or isnt a shelf
		if room.connected_rooms[right] != null:
			if room.connected_rooms[left] == null || floor(room.connected_rooms[left].tilemap) != 3:
				tilemap_num = 3.1
			
		if room.connected_rooms[left] != null:
			if room.connected_rooms[right] == null || floor(room.connected_rooms[right].tilemap) != 3:
				tilemap_num = 3.2
				
		if room.connected_rooms[right] != null && room.connected_rooms[left] != null:
			if floor(room.connected_rooms[right].tilemap) != 3 && floor(room.connected_rooms[left].tilemap) != 3:
				tilemap_num = 3
		
		if room.connected_rooms[right] == null && room.connected_rooms[left] != null:
			if floor(room.connected_rooms[left].tilemap) != 3:
				tilemap_num = 3
				
		if room.connected_rooms[left] == null && room.connected_rooms[right] != null:
			if floor(room.connected_rooms[right].tilemap) != 3:
				tilemap_num = 3
	
	room.tilemap = tilemap_num
	var tilemap = load("res://Level Generation/PremadeTileMaps/TileMap" + str(tilemap_num) + ".tscn")

	return tilemap

func add_room():
	var room_instance = generic_room.instance()
	return room_instance

func load_map():
	CURR_ENEMIES = 0
	CURR_EVENTS = 0
	fill_tile_chance_array()
	event_room_aray.clear()
	max_vector_x = 0; min_vector_x = 0; max_vector_y = 0; min_vector_y = 0
	for node in map_node.get_children():
		map_node.remove_child(node)
		node.queue_free()
	
	#Old map reset function that stopped working for some reason?
#	for i in range(0, map_node.get_child_count()):
#		map_node.remove_child(i)
#		map_node.get_child(i).queue_free()
		
	check_adjacencies()
		
	for i in level.keys():
		var room = add_room()
		map_node.add_child(room)
		room.level_key = i
		set_tilemap(level[i])
		#room.add_child(load_tilemap(level[i]).instance())

		
		#print(level[i].tilemap)
		room.position = i * (ROOM_DIMENSIONS * 32)
		var c_rooms = level.get(i).connected_rooms
		
		if(c_rooms.get(Vector2(1, 0)) != null):
			room.position = i * (ROOM_DIMENSIONS * 32)
			
		if(c_rooms.get(Vector2(0, 1)) != null):
			room.position = i * (ROOM_DIMENSIONS * 32)
		
		#print(level.get(i).connected_rooms)
		#print(level.get(i))
		var connections = get_connections(c_rooms)
		#print(connections)
		#print()
		connections = load_walls(room, connections)
		
		
		if CURR_ENEMIES < MAX_ENEMIES:
			spawn_enemy(enemy_karen, level[i].tilemap, room)
			
		
	#Loads room tilemaps in post map loading so that tilemap changes can be made during level creation
	#Also loads in events to random rooms
	for node in map_node.get_children():
		var room = level.get(node.level_key)
		
		check_min_max_vectors(node.level_key)
		node.add_child(load_tilemap(room).instance())
		if room.tilemap == 3:
			var shelf_stock = load("res://TileMaps/ShelfStockTiles/ShelfStock1.tscn")
			node.add_child(shelf_stock.instance())
		elif room.tilemap < 4 && room.tilemap > 3:
			var shelf_variation = 1 + fmod(room.tilemap, 1.0)
			var shelf_stock = load("res://TileMaps/ShelfStockTiles/ShelfStock" + str(shelf_variation) + ".tscn")
			node.add_child(shelf_stock.instance())
			
	fill_event_room_array()
	for node in map_node.get_children():
		
		if event_room_aray.has(node.level_key):
			spawn_event(event_box, node)
		
			
func spawn_event(event_type, node):
	var event = event_type.instance()
	node.add_child(event)
	event.position.x += 128
	event.position.y += 64
	print("spawned event")

func spawn_enemy(enemy_type, tilemap, room):
	if tilemap == 2:
		var enemy = enemy_type.instance()
		room.add_child(enemy)
		enemy.position.x += 64
		enemy.position.y += 64
		
		CURR_ENEMIES += 1
		print("spawned enemy")


func fill_event_room_array():
	var event_vector = Vector2.ZERO

	while CURR_EVENTS < MAX_EVENTS:
		var rand_x = rng.randi_range(min_vector_x, max_vector_x)
		event_vector.x = rand_x
		var rand_y = rng.randi_range(min_vector_y, max_vector_y)
		event_vector.y = rand_y
		print(event_vector)
		
		if !event_room_aray.has(event_vector):
			event_room_aray.append(event_vector)
			CURR_EVENTS += 1
			
		


func check_min_max_vectors(curr_level_key):
	if curr_level_key.x > max_vector_x:
		max_vector_x = curr_level_key.x
	if curr_level_key.x < min_vector_x:
		min_vector_x = curr_level_key.x
	if curr_level_key.y > max_vector_y:
		max_vector_y = curr_level_key.y
	if curr_level_key.y < min_vector_y:
		min_vector_y = curr_level_key.y

func check_adjacencies():
	#this is the next thing to work on
	#check if a room's connection, has a connection,
	#to a connection that would be counted as adjacent
	
	#EX: DOWN 1 neighbor, RIGHT 1 neighbor, UP 1 neighbor 
	#would need to count as a connection
	var room1; var room2; var room3; var room4
	#print(level)
	
	#Touch back on this next time, check out how they adjust vectors in the level generation code
	#that is likely your answer to solving this problem
	
	for i in level.keys():
		room1 = level.get(i)
		for j in room1.connected_rooms:
			
			
			if room1.connected_rooms[up] != null: #check up
				room2 = room1.connected_rooms[up]
				if room2.connected_rooms[right] != null: #check right
					room3 = room2.connected_rooms[right]
					if room3.connected_rooms[down] != null: #check down
						room4 = room3.connected_rooms[down]
						if room1.connected_rooms[right] == null:
							LevelGeneration.connect_rooms(room1, room4, right) #connect rooms
							
				if room2.connected_rooms[left] != null: #check left
					room3 = room2.connected_rooms[left]
					if room3.connected_rooms[down] != null: #check down
						room4 = room3.connected_rooms[down]
						if room1.connected_rooms[left] == null:
							LevelGeneration.connect_rooms(room1, room4, left) #connect rooms
							
			
			
			if room1.connected_rooms[down] != null: #check down
				room2 = room1.connected_rooms[down]
				if room2.connected_rooms[right] != null: #check right
					room3 = room2.connected_rooms[right]
					if room3.connected_rooms[up] != null: #check up
						room4 = room3.connected_rooms[up]
						if room1.connected_rooms[right] == null:
							LevelGeneration.connect_rooms(room1, room4, right) #connect rooms
							
				if room2.connected_rooms[left] != null: #check left
					room3 = room2.connected_rooms[left]
					if room3.connected_rooms[up] != null: #check up
						room4 = room3.connected_rooms[up]
						if room1.connected_rooms[left] == null:
							LevelGeneration.connect_rooms(room1, room4, left) #connect rooms
			
			
			
			if room1.connected_rooms[right] != null: #check right
				room2 = room1.connected_rooms[right]
				if room2.connected_rooms[down] != null: #check down
					room3 = room2.connected_rooms[down]
					if room3.connected_rooms[left] != null: #check left
						room4 = room3.connected_rooms[left]
						if room1.connected_rooms[down] == null:
							LevelGeneration.connect_rooms(room1, room4, down) #connect rooms
							
				if room2.connected_rooms[up] != null: #check up
					room3 = room2.connected_rooms[up]
					if room3.connected_rooms[left] != null: #check left
						room4 = room3.connected_rooms[left]
						if room1.connected_rooms[up] == null:
							LevelGeneration.connect_rooms(room1, room4, up) #connect rooms
					
					
					
			if room1.connected_rooms[left] != null: #check left
				room2 = room1.connected_rooms[left]
				if room2.connected_rooms[down] != null: #check down
					room3 = room2.connected_rooms[down]
					if room3.connected_rooms[right] != null: #check right
						room4 = room3.connected_rooms[right]
						if room1.connected_rooms[down] == null:
							LevelGeneration.connect_rooms(room1, room4, down) #connect rooms
							
				if room2.connected_rooms[up] != null: #check up
					room3 = room2.connected_rooms[up]
					if room3.connected_rooms[right] != null: #check right
						room4 = room3.connected_rooms[right]
						if room1.connected_rooms[up] == null:
							LevelGeneration.connect_rooms(room1, room4, up) #connect rooms


func load_walls(room, room_connections):
	var type = ""
	if !(room_connections.has("Up")):
		if !room_connections.has("Right") && !room_connections.has("Left"):
			type = "End"
		elif !room_connections.has("Right"):
			type = "RightEnd"
		elif !room_connections.has("Left"):
			type = "LeftEnd"
		else:
			type = ""
		
		var wall_up = load("res://Level Generation/Walls/WallUp" + type + ".tscn").instance()
		room.add_child(wall_up)
		wall_up.position.y -= (6 * 32)
		room_connections.erase("Up")
		
	if !(room_connections.has("Down")):
		if !room_connections.has("Right") && !room_connections.has("Left"):
			type = "End"
		elif !room_connections.has("Right"):
			type = "RightEnd"
		elif !room_connections.has("Left"):
			type = "LeftEnd"
		else:
			type = ""
			
		var wall_down = load("res://Level Generation/Walls/WallDown" + type + ".tscn").instance()
		room.add_child(wall_down)
		wall_down.position.y += (ROOM_DIMENSIONS * 32)
		room_connections.erase("Down")
		
	if !(room_connections.has("Right")):
		var wall_right = load("res://Level Generation/Walls/WallRight.tscn").instance()
		room.add_child(wall_right)
		wall_right.position.x += (ROOM_DIMENSIONS * 32)
		room_connections.erase("Right")
		
	if !(room_connections.has("Left")):
		var wall_left = load("res://Level Generation/Walls/WallLeft.tscn").instance()
		room.add_child(wall_left)
		wall_left.position.x -= (ROOM_DIMENSIONS * 32)
		room_connections.erase("Left")
		
			
func get_connections(room_connections):
	var connections = []
	for i in room_connections.keys():
		if room_connections.get(i) != null:
			if i == Vector2(1, 0):
				connections.append("Right")
			elif i == Vector2(-1, 0):
				connections.append("Left")
			elif i == Vector2(0, 1):
				connections.append("Down")
			elif i == Vector2(0, -1):
				connections.append("Up")
	return connections

#func load_map():
#	for i in range(0, map_node.get_child_count()):
#		map_node.get_child(i).queue_free()
#
#	for i in level.keys():
#		var temp = Sprite.new()
#		temp.texture = node_sprite
#		map_node.add_child(temp)
#		temp.z_index = 0
#		temp.position = i * 32
#		var c_rooms = level.get(i).connected_rooms
#
#		if(c_rooms.get(Vector2(1, 0)) != null):
#			temp = Sprite.new()
#			map_node.add_child(temp)
#			temp.z_index = 0
#			temp.position = i * 32 + Vector2(5, 0.5)
#
#		if(c_rooms.get(Vector2(0, 1)) != null):
#			temp = Sprite.new()
#			map_node.add_child(temp)
#			temp.z_index = 0
#			temp.rotation_degrees = 90
#			temp.position = i * 32 + Vector2(5, 0.5)

func _on_Button_pressed():
	randomize()
	level = LevelGeneration.generate(rand_range(-1000, 1000))
	load_map()
