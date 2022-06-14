extends Area2D

var player = null
var overlay_opacity = 1

onready var box = $"../../CardboardBox"
onready var sprite = $"../Sprite"
onready var highlighted_sprite = $"../HighlightedSprite"

func can_see_player():
	return player != null
	


func _on_PlayerDetection_body_entered(body):
	player = body
	sprite.hide()
	highlighted_sprite.show()
	box.picked_up = true
	


func _on_PlayerDetection_body_exited(body):
	player = null
	sprite.show()
	highlighted_sprite.hide()
