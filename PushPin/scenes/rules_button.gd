
extends Node2D

var is_selected = false

func _ready():
	var rules = "Tap two cards of the same suit or rank"
	rules += " to discard all cards sandwiched between them"
	rules += " if and only if all cards in-between are of"
	rules += " the same suit or rank. \nDiscard the maximum"
	rules += " number of cards to win! \nHold the number in"
	rules += " the corner to start a new game."
	set_process_input(true)
	get_node("rules").add_text(rules)
	get_node("rules").set_scroll_active(false)

func _input(event):
	if(event.type == InputEvent.SCREEN_TOUCH):
		if(event.is_pressed() and get_node("card_back").get_rect().has_point(event.pos)):
			if(is_selected == false):
				get_node("rules_animation").play("rules")
				is_selected = true
				set_process_input(false)
			else:
				get_node("rules_animation").play("rules", 1, -1, true)
				is_selected = false
				set_process_input(false)



func _on_rules_animation_finished():
	set_process_input(true)
