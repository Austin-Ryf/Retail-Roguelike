extends Node

var room = preload("res://Level Generation/Room.tscn")

var min_rooms = 40
var max_rooms = 50

var generation_chance = 60

func generate(room_seed):
	seed(room_seed)
	
	var level = {}
	var size = floor(rand_range(min_rooms, max_rooms))

	level[Vector2(0, 0)] = room.instance()
	size -= 1
	
	while(size > 0):
		for i in level.keys():
			if(rand_range(0, 100) < generation_chance):
				var direction = rand_range(0, 4)
				if(direction < 1):
					var new_room_position = i + Vector2(1, 0)
					if(!level.has(new_room_position)):
						level[new_room_position] = room.instance()
						size -= 1
					connect_rooms(level.get(i), level.get(new_room_position), Vector2(1, 0))
				if(direction < 2):
					var new_room_position = i + Vector2(-1, 0)
					if(!level.has(new_room_position)):
						level[new_room_position] = room.instance()
						size -= 1
					connect_rooms(level.get(i), level.get(new_room_position), Vector2(-1, 0))
				if(direction < 3):
					var new_room_position = i + Vector2(0, 1)
					if(!level.has(new_room_position)):
						level[new_room_position] = room.instance()
						size -= 1
					connect_rooms(level.get(i), level.get(new_room_position), Vector2(0, 1))
				if(direction < 4):
					var new_room_position = i + Vector2(0, -1)
					if(!level.has(new_room_position)):
						level[new_room_position] = room.instance()
						size -= 1
					connect_rooms(level.get(i), level.get(new_room_position), Vector2(0, -1))
	return level

func connect_rooms(room1, room2, direction):
	room1.connected_rooms[direction] = room2
	room2.connected_rooms[-direction] = room1
	room1.num_connections += 1
	room2.num_connections += 1
