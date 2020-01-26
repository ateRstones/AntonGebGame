extends KinematicBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (PackedScene) var Cube
export var GRAVITY = 800.0
export var WALK_SPEED = 800
export var SLOWDOWN_SPEED = 1000
export var SLOWDOWN_SPEED_AIR = 600
export var MAX_WALK_SPEED = 350
export var JUMP_SPEED = 600
export var JUMP_SIDE_SPEED = 400
export var LANDED_SMALL_TIME = 0.1

var velocity = Vector2()
var landedDelta = LANDED_SMALL_TIME + 1
var lastWallMod = 0
var directionMod = 1
var cubeCount = 0
var firstPos = null

# Called when the node enters the scene tree for the first time.
func _ready():
	firstPos = position

func addCube():
	cubeCount += 1

func _process(delta):
	if directionMod == 1:
		$AnimatedSprite.flip_h = false
	else:
		$AnimatedSprite.flip_h = true
	
	if is_on_floor():
		if abs(velocity.x) > 0:
			$AnimatedSprite.animation = "running"
		elif landedDelta <= LANDED_SMALL_TIME:
			$AnimatedSprite.animation = "small"
		else:
			$AnimatedSprite.animation = "standing"
	else:
		$AnimatedSprite.animation = "long"

func respawn():
	velocity = Vector2(0, 0)
	position = firstPos

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept") and cubeCount > 0:
		cubeCount -= 1
		var cube = Cube.instance()
		cube.position = position + Vector2(32 * directionMod, -32)
		$"../Cubes".add_child(cube)
	
	if is_on_floor():
		landedDelta += delta
	else:
		landedDelta = 0
	
	var moving = false
	if Input.is_action_pressed("ui_right"):
		velocity.x += WALK_SPEED * delta
		moving = true
	if Input.is_action_pressed("ui_left"):
		velocity.x -= WALK_SPEED * delta
		moving = true
	
	velocity.x = clamp(velocity.x, -MAX_WALK_SPEED, MAX_WALK_SPEED)
	
	if not moving:
		var deltaSpeed = 0
		if is_on_floor():
			deltaSpeed = SLOWDOWN_SPEED * delta
		else:
			deltaSpeed = SLOWDOWN_SPEED_AIR * delta
		
		if velocity.x > deltaSpeed:
			velocity.x -= deltaSpeed
		elif velocity.x < -deltaSpeed:
			velocity.x += deltaSpeed
		else:
			velocity.x = 0
	if Input.is_action_just_pressed("ui_up"):
		if is_on_floor():
			velocity.y = -JUMP_SPEED
		elif is_on_wall():
			velocity.y = -JUMP_SPEED
			velocity.x = JUMP_SIDE_SPEED * lastWallMod
			
	
	velocity.y += delta * GRAVITY
	var res = move_and_slide(velocity, Vector2(0, -1))
	for collId in range(0, get_slide_count()):
		var coll = get_slide_collision(collId)
		var n = coll.normal
		
		if abs(n.y) > 0.6:
			velocity.y = 0
		if abs(n.x) > 0.6:
			velocity.x = 0
			if n.x > 0:
				lastWallMod = 1
			else:
				lastWallMod = -1
	
	if velocity.x > 0:
		directionMod = 1
		
	if velocity.x < 0:
		directionMod = -1
	
	if position.y >= 1080:
		respawn()
	
	#if res.y == 0 and ((is_on_floor() and velocity.y > 0) or (is_on_ceiling() and velocity.y < 0)):
	#	velocity.y = 0
	
	#if res.x == 0:
	#	velocity.x = 0
