extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export(int) var MAX_SPEED = 40
export(int) var ACCELERATION = 500
export(int) var FRICTION = 500
export(int) var KNOCKBACK = 6
export(int) var DETECTION = 50
export(int) var MAX_HEALTH = 3
export(int) var WANDER_TARGET_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE,
	AGGRO
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = IDLE

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var detection = $PlayerDetectionZone/CollisionShape2D
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController

func _ready():
	stats.health = MAX_HEALTH
	state = pick_random_state([IDLE, WANDER])
	
func pick_state_and_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))
	
func accelerate_toward_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0
	
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
		
func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, (FRICTION * delta) - KNOCKBACK)
	knockback = move_and_slide(knockback)
	
	
	match state:
		IDLE:
			sprite.animation = "Idle"
			detection.shape.radius = DETECTION
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			
			if wanderController.get_time_left() == 0:
				pick_state_and_wander()
			
			
		WANDER:
			sprite.animation = "Walk"
			seek_player()
			if wanderController.get_time_left() == 0:
				pick_state_and_wander()
				
			accelerate_toward_point(wanderController.target_position, delta)
			
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				pick_state_and_wander()
			
		CHASE:
			sprite.animation = "Chase"
			var player = playerDetectionZone.player
			if player != null:
				accelerate_toward_point(player.global_position, delta)
				self.detection.shape.radius = 75
				MAX_SPEED = 50
			else:
				state = IDLE
				sprite.animation = "Idle"
			
			if stats.health < MAX_HEALTH:
				state = AGGRO
			
			
		AGGRO:
			sprite.animation = "Aggro"
			var player = playerDetectionZone.player
			if player != null:
				#Leave this the way it is, changing it screws up their movement
				var direction = (player.global_position - global_position).normalized()
				velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
				sprite.flip_h = velocity.x < 0
				detection.shape.radius = 90
				MAX_SPEED = 75
			else:
				state = IDLE
				sprite.animation = "Idle"
			
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	
	velocity = move_and_slide(velocity)

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 150
	hurtbox.start_invinicibility(0.25)

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
