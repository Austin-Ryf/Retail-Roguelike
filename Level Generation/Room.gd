extends Node2D

var connected_rooms = {
	Vector2(1, 0): null, #Right
	Vector2(-1, 0): null, #Left
	Vector2(0, 1): null, #Down
	Vector2(0, -1): null, #Up
}

var level_key = Vector2.ZERO

var num_connections = 0
var tilemap = null
