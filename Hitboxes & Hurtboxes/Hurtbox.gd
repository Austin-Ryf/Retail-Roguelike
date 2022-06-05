extends Area2D

var invincible = false setget set_invincible

onready var timer = $Timer

signal invincibility_start
signal invincibility_end

func set_invincible(value):
	invincible = value
	if invincible == true:
		emit_signal("invincibility_start")
	else:
		emit_signal("invincibility_end")
		
func start_invinicibility(duration):
	self.invincible = true
	timer.start(duration)


func _on_Timer_timeout():
	self.invincible = false


func _on_Hurtbox_invincibility_start():
	set_deferred("monitoring", false)


func _on_Hurtbox_invincibility_end():
	set_deferred("monitoring", true)
