
extends Node2D

var angle = 0.0
var angular = 0.0
var center = Vector2(225, 400)
onready var tween = get_node("Tween")
onready var main = get_node("../")
var moving = false
const SPEED = 200.0
const RADIUS = 145.0
const STRETCH = 1.3571428
const PERIOD = 2 * PI

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	angular += angle
	
	if(angular > PERIOD):
		angular -= PERIOD
	
	var pos1 = Vector2(0,0)
	var pos2 = Vector2(0,0)
	pos1.x = RADIUS * cos(angular)
	pos1.y = RADIUS * STRETCH * sin(angular)
	pos2.x = pos1.x * -1.0
	pos2.y = pos1.y * -1.0
	
	pos1.x += center.x
	pos1.y += center.y
	pos2.x += center.x
	pos2.y += center.y
	
	var size = main.deck[0].get_texture().get_size()
	
	pos1.x -= (size.x/2.0)
	pos1.y -= (size.y/2.0)
	pos2.x -= (size.x/2.0)
	pos2.y -= (size.y/2.0)
	
	var distance = main.deck[0].get_pos().distance_to(pos1)
	var time = distance / SPEED
	var trans = tween.TRANS_SINE
	
	tween.interpolate_property(main.deck[0], "transform/pos", main.deck[0].get_pos(), pos1, time, trans, 2) 
	tween.interpolate_property(main.deck[1], "transform/pos", main.deck[1].get_pos(), pos2, time, trans, 2) 
	
	if(moving == true):
		var temp = main.deck[0].get_z()
		main.deck[0].set_z(main.deck[1].get_z())
		main.deck[1].set_z(temp)
	else:
		moving = true
	
	
	tween.start()
	set_process(false)



func _on_Tween_tween_complete( object, key ):
	set_process(true)
