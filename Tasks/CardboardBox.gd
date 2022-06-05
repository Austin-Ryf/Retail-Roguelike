extends StaticBody2D

const CardboardBoxEffect = preload("res://Effects/CardboardBoxEffect.tscn")

func create_grass_effect():
	var cardboardBoxEffect = CardboardBoxEffect.instance()
	get_parent().add_child(cardboardBoxEffect)
	cardboardBoxEffect.global_position = global_position

func _on_Hurtbox_area_entered(area):
	create_grass_effect()
	queue_free()
