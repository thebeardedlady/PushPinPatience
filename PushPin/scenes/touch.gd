
extends Node

onready var main = get_node("../")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process_input(true)

func _input(event):
	if(event.type == InputEvent.SCREEN_DRAG or event.type == InputEvent.MOUSE_MOTION):
		var no_button = true
		
		for i in range(main.deck.size()):
			if(main.deck[i].rect.has_point(event.pos)):
				no_button = false
		
		if(get_node("../cards_left").get_rect().has_point(event.pos)):
			no_button = false
		
		if(no_button == true):
			print("Change in y is " + str(event.relative_y) + " pixels")
			var move
			
			if(event.relative_y > -60 and event.relative_y < 60):
				move = event.relative_y
			elif(event.relative_y >= 60):
				move = 60
			else:
				move = -60
			
			for card in main.deck:
				var temp_pos = card.get_pos()
				temp_pos.y += move
				card.set_pos(temp_pos)
			
			var back = main.deck.size() - 1
			if(main.deck[back].get_pos().y > main.bottom_pos):
				var temp_pos = main.deck[back].get_pos()
				temp_pos.y = main.deck[0].get_pos().y - main.shift
				main.deck[back].set_pos(temp_pos)
			
				var temp_card = main.deck[back]
				main.deck.pop_back()
				main.deck.push_front(temp_card)
			elif(main.deck[0].get_pos().y < main.top_pos):
				var temp_pos = main.deck[0].get_pos()
				var last = main.deck.size() - 1
				temp_pos.y = main.deck[last].get_pos().y + main.shift
				main.deck[0].set_pos(temp_pos)
				
				var temp_card = main.deck[0]
				main.deck.pop_front()
				main.deck.push_back(temp_card)
