extends Node

#the following is a dummy node to 
#handle tweening


onready var main = get_node("../")
onready var tween = get_node("../Tween")
var total_tweens = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	if(main.tweens_left == 0):
		if(main.discard_cards.size() > 0):
			for card in main.discard_cards:
				main.remove_child(card)
				main.deck.erase(card)
			main.discard_cards.clear()
		
		var save_data = main.create_deck_data()
		main.save(save_data)
		
		for i in range(main.deck.size()):
			main.deck[i].set_process_input(true)
		main.set_process(true)
		set_process(false)
		tween.remove_all()
		
	elif(main.tweens_left == 1):
		if(main.new_game == true):
			tween.remove_all()
			
			#delete cards
			for card in main.deck:
				main.remove_child(card)
			main.deck.clear()
			
			#add new cards
			for i in range(main.suits.size()): #mess with to check endgame logic
				for j in range(main.ranks.size()): #originally suits.size() then ranks.size()
					var card_instance = main.cards.instance()
					var texture = load("res://cards/" + main.suits[i] + main.ranks[j] + ".png")
					card_instance.suit = main.suits[i]
					card_instance.rank = main.ranks[j]
					card_instance.set_texture(texture)
					
					main.deck.append(card_instance)
					main.add_child(card_instance)
			
			#shuffle deck
			for i in range(main.deck.size()):
				var last = main.deck.size() - 1
				var num = main.rand_range_int(i, last)
				var temp = main.deck[i]
				main.deck[i] = main.deck[num]
				main.deck[num] = temp
			
			main.top_pos = -90
			main.bottom_pos = main.top_pos + (main.deck.size() * main.shift)
			for i in range(main.deck.size()):
				var old_pos = Vector2(0,0)
				old_pos.x = main.rand_range_int(-75, 525)
				old_pos.y = main.rand_range_int(801, 1000)
				main.deck[i].set_pos(old_pos)
				main.deck[i].set_z(i)
			
			get_node("../end_screen/end_message").hide()
			get_node("../cards_left").set_text(str(main.deck.size()))
			
			var final_pos = Vector2(155, (main.top_pos + (main.shift/2)))
			for i in range(main.deck.size()):
				tween.interpolate_property(main.deck[i], "transform/pos", main.deck[i].get_pos(), final_pos, 1.0, tween.TRANS_QUAD, tween.EASE_OUT, 0.25) 
				final_pos.y += main.shift
				
			main.new_game = false
			main.tweens_left -= 1
			set_process(false)
			tween.start()

func _on_Tween_tween_complete( object, key ):
	set_process(true)