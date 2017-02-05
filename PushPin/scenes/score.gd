
extends Node2D

onready var main = get_node("../")
onready var tween = get_node("../Tween")
onready var touch = get_node("../touch")
var new_game = false
var is_selected = false


func _ready():
	var new_game = "Tap here to reset your game."
	new_game += " Tap elsewhere to cancel."
	set_process_input(true)
	get_node("new_game").add_text(new_game)
	get_node("new_game").set_scroll_active(false)

func _input(event):
	if(event.type == InputEvent.SCREEN_TOUCH):
		var press = false
		if(get_node("../rules_button/card_back").get_rect().has_point(event.pos) == true):
			press = true
		
		for i in range(main.deck.size()):
			if(main.deck[i].rect.has_point(event.pos) == true):
				press = true
		
		if(event.is_pressed() and press == false):
			if(is_selected == true):
				if(get_node("cardback").get_rect().has_point(event.pos)):
					get_node("../end_screen/Tween").remove_all()
					for i in range(main.deck.size()):
						var new_pos = Vector2(0,0)
						new_pos.y = main.rand_range_int(850, 1050)
						new_pos.x = main.rand_range_int(-75, 575)
						tween.interpolate_property(main.deck[i], "transform/pos", main.deck[i].get_pos(), new_pos, 1.8, tween.TRANS_QUAD, tween.EASE_OUT)
						tween.interpolate_property(main.deck[i], "visibility/opacity", main.deck[i].get_opacity(), 0.0, 1.8, tween.TRANS_CUBIC, tween.EASE_IN)
						main.deck[i].set_process_input(false)
					new_game = true
					main.tweens_left = 1
					main.printed = false
					main.set_process(false)
					touch.set_process_input(false)
					if(main.out_of_moves == true):
						get_node("../end_screen/end_animation").play("end", 1, -1, true)
						main.out_of_moves = false
					tween.start()
				get_node("new_game_animation").play("new_game", 1, -1, true)
				is_selected = false
				set_process_input(false)
			else:
				if(get_node("cardback").get_rect().has_point(event.pos)):
					get_node("new_game_animation").play("new_game")
					is_selected = true
					set_process_input(false)


func _on_new_game_animation_finished():
	set_process_input(true)
