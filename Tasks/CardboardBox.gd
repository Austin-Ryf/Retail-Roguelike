extends RigidBody2D

const CardboardBoxEffect = preload("res://Effects/CardboardBoxEffect.tscn")

onready var player = get_tree().get_nodes_in_group("player")[0]
onready var collision = $CollisionShape2D

var picked_up = false

func create_box_effect():
	var cardboardBoxEffect = CardboardBoxEffect.instance()
	get_parent().add_child(cardboardBoxEffect)
	cardboardBoxEffect.global_position = global_position

func _on_Hurtbox_area_entered(area):
	create_box_effect()
	queue_free()
	
func _physics_process(delta):
	if picked_up == true:
		self.z_index = player.z_index + 1
		self.global_position = player.global_position + Vector2(0, -24)
		collision.set_deferred("disabled", true)
