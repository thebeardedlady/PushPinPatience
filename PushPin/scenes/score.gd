
extends Node2D

var hold = 0.0
onready var main = get_node("../")
onready var tween = get_node("../Tween")
onready var touch = get_node("../touch")
var new_game = false


func _ready():
	set_process(true)

func _process(delta):
	
	#start a new game
	if(get_node("cardback").is_pressed()):
		if(hold < 1.0):
			hold += delta
		else:
			for i in range(main.deck.size()):
				var new_pos = Vector2(0,0)
				new_pos.y = main.rand_range_int(850, 1050)
				new_pos.x = main.rand_range_int(-75, 575)
				tween.interpolate_property(main.deck[i], "transform/pos", main.deck[i].get_pos(), new_pos, 1.0, tween.TRANS_QUAD, tween.EASE_OUT)
				tween.interpolate_property(main.deck[i], "visibility/opacity", main.deck[i].get_opacity(), 0.0, 1.0, tween.TRANS_CUBIC, tween.EASE_IN)
				main.deck[i].set_process_input(false)
			new_game = true
			hold = 0.0
			main.tweens_left = 1
			main.printed = false
			main.set_process(false)
			touch.set_process_input(false)
			set_process(false)
			if(main.out_of_moves == true):
				get_node("../end_screen/end_animation").play("end", 1, -1, true)
				main.out_of_moves = false
			tween.start()
	else:
		hold = 0.0
	
