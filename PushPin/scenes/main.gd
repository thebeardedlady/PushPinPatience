
extends Node2D

const NORMAL_SPEED = 400
var deck = []
var selected = []
var pair = [] #used for discarding
var deck_index = 0
var counter = 0
var top_pos = -90
var bottom_pos
var shift = 60
var printed = false
var tweens_left = 0
var discard_cards = []
var out_of_moves = false
onready var tween = get_node("Tween")
var cards = preload("res://scenes/card.xscn")
var suits = ["C","D","H","S"]
var ranks = ["A", "2", "3", "4", "5",
			"6", "7", "8", "9", "X",
			"J", "Q", "K"]


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here\
	
	#next 2 blocks are starting a new game
	#i.e. if save data == "0"
	var data
	data = load_save()
	randomize()
	
	if(data == "0"):
		#create cards
		for i in range(suits.size()): #mess with to check endgame logic
			for j in range(ranks.size()): #originally suits.size() then ranks.size()
				var card_instance = cards.instance()
				var texture = load("res://cards/" + suits[i] + ranks[j] + ".png")
				card_instance.suit = suits[i]
				card_instance.rank = ranks[j]
				card_instance.set_texture(texture)
				
				deck.append(card_instance)
				add_child(card_instance)
	
		#shuffle deck
		for i in range(deck.size()):
			var last = deck.size() - 1
			var num = rand_range_int(i, last)
			var temp = deck[i]
			deck[i] = deck[num]
			deck[num] = temp
		
		var save_data = create_deck_data()
		save(save_data)
	else:
		var old_deck = data.split(",", false)
		for card in old_deck:
			var suit = card.left(1)
			var rank = card.right(1)
			var card_instance = cards.instance()
			var texture = load("res://cards/" + suit + rank + ".png")
			card_instance.suit = suit
			card_instance.rank = rank
			card_instance.set_texture(texture)
			
			deck.append(card_instance)
			add_child(card_instance)
	
	if(deck.size() < 14): 
		top_pos = (800 - (shift * (deck.size() + 2))) / 2 #viewport height
	bottom_pos = top_pos + (deck.size() * shift)
	
	for i in range(deck.size()):
		var old_pos = Vector2(0,0)
		old_pos.x = rand_range_int(-75, 525)
		old_pos.y = rand_range_int(801, 1000)
		deck[i].set_pos(old_pos)
		deck[i].set_z(i)
	
	#get_node("end_screen").hide()
	get_node("score/cards_left").set_text(str(deck.size()))
	
	var final_pos = Vector2(155, (top_pos + (shift/2)))
	for i in range(deck.size()):
		tween.interpolate_property(deck[i], "transform/pos", deck[i].get_pos(), final_pos, 1.0, tween.TRANS_QUAD, tween.EASE_OUT, 0.25) 
		final_pos.y += shift
	
	tweens_left = 0
	tween.start()

func _process(delta):
	
	#move cards
	if(Input.is_action_pressed("move_down")):
		for card in deck:
			var temp_pos = card.get_pos()
			temp_pos.y += NORMAL_SPEED * delta
			card.set_pos(temp_pos)
		
		var back = deck.size() - 1
		if(deck[back].get_pos().y > bottom_pos):
			var temp_pos = deck[back].get_pos()
			temp_pos.y = deck[0].get_pos().y - shift
			deck[back].set_pos(temp_pos)
			
			var temp_card = deck[back]
			deck.pop_back()
			deck.push_front(temp_card)
	
	if(Input.is_action_pressed("move_up")):
		for card in deck:
			var temp_pos = card.get_pos()
			temp_pos.y -= NORMAL_SPEED * delta
			card.set_pos(temp_pos)
		
		if(deck[0].get_pos().y < top_pos):
			var temp_pos = deck[0].get_pos()
			var last = deck.size() - 1
			temp_pos.y = deck[last].get_pos().y + shift
			deck[0].set_pos(temp_pos)
			
			var temp_card = deck[0]
			deck.pop_front()
			deck.push_back(temp_card)
	
	#select/deselect a card
	if(selected.size() > 0):
		var prev_depth = -100
		var index = -1
		for i in range(selected.size()):
			if(selected[i].get_z() > prev_depth):
				index = i
				prev_depth = selected[i].get_z()
		if(selected[index].is_selected == true):
			selected[index].is_selected = false
			pair.erase(selected[index])
		else:
			selected[index].is_selected = true
			if(pair.size() == 2):
				pair[0].is_selected = false
				pair[1].is_selected = false
				pair.clear()
			pair.append(selected[index])
		selected.clear()
	
	#depth, aabb, selection, opacity
	for i in range(deck.size()):
		deck[i].set_z(i)
		deck[i].rect.pos = deck[i].get_pos()
		if(deck[i].is_selected == true):
			deck[i].set_modulate(Color(0.6,0.6,6.0))
		else:
			deck[i].set_modulate(Color(1.0,1.0,1.0))
		if(tween.is_active() == false):
			if(deck.size() > 2):
				if(deck[i].get_pos().y < top_pos + (shift/2)):
					var opacity = (deck[i].get_pos().y - top_pos) / (shift/2)
					deck[i].set_opacity(opacity)
				elif(deck[i].get_pos().y > bottom_pos - (shift/2)):
					var opacity = (bottom_pos - deck[i].get_pos().y) / (shift/2)
					deck[i].set_opacity(opacity)
				else:
					deck[i].set_opacity(1)
			else:
				deck[i].set_opacity(1)
	
	#possible moves
	var moves_left = false
	for i in range(deck.size()):
		var two = []
		two.append(deck[i])
		for j in range(deck.size()):
			var index = (deck.find(two[0]) + j) % (deck.size())
			if(is_pair(two[0], deck[index]) != "0"):
				two.append(deck[index])
				var cur_index = (deck.find(two[0]) + 1) % (deck.size())
				var compare = deck[cur_index]
				if(compare != two[1]):
					var matching = true
					cur_index = (cur_index + 1) % (deck.size())
					var overlap = is_pair(compare, deck[cur_index])
					while(matching == true and deck[cur_index] != two[1]):
						var cur_pair = is_pair(compare, deck[cur_index])
						if(overlap != cur_pair or cur_pair == "0"):
							matching = false
						cur_index = (cur_index + 1) % (deck.size())
					if(matching == true):
						moves_left = true
						break
				two.pop_back()
		two.clear()
		if(moves_left == true):
			break
	
	#game is over
	if(moves_left == false and printed == false):
		out_of_moves = true
		save("0")
		if(deck.size() == 2):
			print("You win")
			for i in range(deck.size()):
				deck[i].set_process_input(false)
			get_node("touch").set_process_input(false)
			get_node("end_screen/end_message").set_text(" You Win!  ")
		else:
			print("Out of Moves")
			get_node("end_screen/end_message").set_text("Out of Moves")
		get_node("end_screen/end_animation").play("end")
		printed = true
	
	if(pair.size() != 2):
		counter = 0
	
	#discard cards
	if(pair.size() == 2 and counter == 0):
		if(is_pair(pair[0], pair[1]) != "0"):
			var anchor = deck.find(pair[1])
			var match_down = true
			var match_up = true
			var index
			var compare
			var current
			var discard_up = []
			var discard_down = []
			
			
			#detect discard below
			index = (anchor + 1 + deck.size()) % (deck.size())
			compare = deck[index]
			if(compare != pair[0]):
				discard_down.append(compare)
				index = (index + 1 + deck.size()) % (deck.size())
				current = deck[index]
				var overlap = is_pair(compare, current)
				while(match_down == true and current != pair[0]):
					var cur_pair = is_pair(compare, current)
					if(overlap == cur_pair and cur_pair != "0"):
						discard_down.append(current)
					else:
						match_down = false
					index = (index + 1 + deck.size()) % (deck.size())
					current = deck[index]
			else:
				match_down = false
			
			#detect discard above
			index = (anchor - 1 + deck.size()) % (deck.size())
			compare = deck[index]
			if(compare != pair[0]):
				discard_up.append(compare)
				index = (index - 1 + deck.size()) % (deck.size())
				current = deck[index]
				var overlap = is_pair(compare, current)
				while(match_up == true and current != pair[0]):
					var cur_pair = is_pair(compare, current)
					if(overlap == cur_pair and cur_pair != "0"):
						discard_up.append(current)
					else:
						match_up = false
					index = (index - 1 + deck.size()) % (deck.size())
					current = deck[index]
			else:
				match_up = false
			
			if(match_down == true or match_up == true):
				var new_size = deck.size()
				var time = 0.0
				if(match_down == true and match_up == true):
					time = (discard_down.size() + discard_up.size()) * 0.05
				else:
					if(match_down == true):
						time = discard_down.size() * 0.1
					else:
						time = discard_up.size() * 0.1
				
				if(time < 0.2):
					time = 0.2
				
				if(match_down == true):
					new_size -= discard_down.size()
					for i in range(discard_down.size()):
						discard_cards.append(discard_down[i])
						tween.interpolate_property(discard_down[i], "visibility/opacity", discard_down[i].get_opacity(), 0.0, time, tween.TRANS_QUAD, tween.EASE_OUT)
				if(match_up == true):
					new_size -= discard_up.size()
					for i in range(discard_up.size()):
						discard_cards.append(discard_up[i])
						tween.interpolate_property(discard_up[i], "visibility/opacity", discard_up[i].get_opacity(), 0.0, time, tween.TRANS_QUAD, tween.EASE_OUT)
				
				#setting the anchor position
				if(new_size < 16):
					top_pos = (800 - (shift * (new_size + 2))) / 2 #viewport height
				bottom_pos = top_pos + (new_size * shift)
				get_node("score/cards_left").set_text(str(new_size))
				
				var new_pos = Vector2(155, (top_pos + (shift/2)))
				for i in range(deck.size()):
					if(discard_cards.has(deck[i]) == false):
						tween.interpolate_property(deck[i], "transform/pos", deck[i].get_pos(), new_pos, time, tween.TRANS_QUAD, tween.EASE_IN)
						new_pos.y += shift
						if(deck[i].get_opacity() != 1.0):
							tween.interpolate_property(deck[i], "visibility/opacity", deck[i].get_opacity(), 1.0, time, tween.TRANS_QUAD, tween.EASE_OUT)
				
				if(new_size == 2):
					for i in range(pair.size()):
						tween.interpolate_property(pair[i], "modulate", pair[i].get_modulate(), Color(1.0,1.0,1.0), time, tween.TRANS_CUBIC, tween.EASE_IN_OUT)
						pair[i].is_selected = false
					pair.clear()
				
				set_process(false)
				get_node("touch").set_process_input(false)
				for i in range(deck.size()):
					deck[i].set_process_input(false)
				
				tweens_left = 0
				tween.start()
			else:
				print("Invalid Discard")
		else:
			print("No match")
		counter = 1

func rand_range_int(low, high):
	return (randf() * (high - low)) + low

func add_to_selected(card):
	selected.append(card)

func is_pair(card1, card2):
	
	if(card1.suit == card2.suit and card1.rank == card2.rank):
		return "0"
	elif(card1.suit == card2.suit):
		return card1.suit
	elif(card1.rank == card2.rank):
		return card1.rank
	else:
		return "0"

func create_deck_data():
	var deck_data = ""
	for i in range(deck.size()):
		deck_data += deck[i].suit + deck[i].rank + ","
	return deck_data

func save(content):
	var file = File.new()
	file.open("user://saved_game.pp", file.WRITE)
	if(file.is_open()):
		file.store_string(content)
	file.close()

func load_save():
	var file = File.new()
	var data
	if(file.file_exists("user://saved_game.pp")):
		file.open("user://saved_game.pp", file.READ)
		data = file.get_as_text()
		return data
	else:
		return "0"