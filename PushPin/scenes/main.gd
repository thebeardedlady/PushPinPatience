
extends Node2D

const EXACT_COPY = 2
const IS_MATCH = 1
const NO_MATCH = 0
const NORMAL_SPEED = 400
var deck = []
var selected = []
var pair = [] #used for discarding
var deck_index = 0
var counter = 0
var top_pos = -120
var bottom_pos
var shift = 60
var printed = false
var hold = 0.0
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
	
	
	var depth = 0
	var column = Vector2(155, (top_pos + (shift/2)))
	for i in range(deck.size()):
		deck[i].set_pos(column)
		deck[i].set_z(depth)
		column.y += shift
		depth += 1
	bottom_pos = top_pos + (deck.size() * shift)
	
	get_node("end_screen/end_message").hide()
	get_node("cards_left").set_text(str(deck.size()))
	set_process(true)

func _process(delta):
	
	#move cards
	if(Input.is_action_pressed("move_down") or get_node("go_down").is_pressed()):
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
	
	if(Input.is_action_pressed("move_up") or get_node("go_up").is_pressed()):
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
	
	
	#discard cards
	if(pair.size() == 2 and counter == 0):
		if(is_match(pair[0].suit, pair[0].rank, pair[1].suit, pair[1].rank) == IS_MATCH):
			var anchor = deck.find(pair[1])
			var match_down = true
			var match_up = true
			var index
			var compare
			var current
			var discard_up = []
			var discard_down = []
			
			
			index = (anchor + 1 + deck.size()) % (deck.size())
			compare = deck[index]
			if(compare != pair[0]):
				discard_down.append(compare)
				index = (index + 1 + deck.size()) % (deck.size())
				current = deck[index]
				while(match_down == true and current != pair[0]):
					if(is_match(compare.suit, compare.rank, current.suit, current.rank) != IS_MATCH):
						match_down = false
					else:
						discard_down.append(current)
					index = (index + 1 + deck.size()) % (deck.size())
					current = deck[index]
			else:
				match_down = false
			
			
			index = (anchor - 1 + deck.size()) % (deck.size())
			compare = deck[index]
			if(compare != pair[0]):
				discard_up.append(compare)
				index = (index - 1 + deck.size()) % (deck.size())
				current = deck[index]
				while(match_up == true and current != pair[0]):
					if(is_match(compare.suit, compare.rank, current.suit, current.rank) != IS_MATCH):
						match_up = false
					else:
						discard_up.append(current)
					index = (index - 1 + deck.size()) % (deck.size())
					current = deck[index]
			else:
				match_up = false
			
			
			if(match_down == true and match_up == true):
				print("Double Valid discard")
				for card in discard_down:
					if(deck.has(card)):
						deck.erase(card)
						remove_child(card)
				for card in discard_up:
					if(deck.has(card)):
						deck.erase(card)
						remove_child(card)
				
				var temp_y = (800 - (shift * (deck.size() + 2))) / 2 #viewport height
				top_pos = temp_y
				anchor = deck.find(pair[1])
				if(anchor == 0):
					deck[anchor].set_pos(Vector2(155, temp_y))
					deck[anchor + 1].set_pos(Vector2(155, temp_y + shift))
				elif(anchor == 1):
					deck[anchor - 1].set_pos(Vector2(155, temp_y))
					deck[anchor].set_pos(Vector2(155, temp_y + shift))
				bottom_pos = top_pos + (deck.size() * shift)
				get_node("cards_left").set_text(str(deck.size()))
				
				var save_data = create_deck_data()
				save(save_data)
				
			elif(match_down == true or match_up == true):
				if(match_down == true):
					print("Valid discard below of size " + str(discard_down.size()))
					for card in discard_down:
						if(deck.has(card)):
							deck.erase(card)
							remove_child(card)
				if(match_up == true):
					print("Valid discard above of size " + str(discard_up.size()))
					for card in discard_up:
						if(discard_up.has(card)):
							deck.erase(card)
							remove_child(card)
				
				#reshaping the deck
				anchor = deck.find(pair[1])
				if(deck.size() >= 14):
					if(match_up == true):
						var space = floor(((deck[anchor].get_pos().y - top_pos) / shift))
						space = space - anchor
						for i in range(space):
							var last = deck.size() - 1
							var temp = deck[last]
							deck.pop_back()
							deck.push_front(temp)
				else:
					var temp_y = (800 - (shift * (deck.size() + 2))) / 2 #viewport height
					top_pos = temp_y
					temp_y += (shift * anchor) + (shift/2)
					deck[anchor].set_pos(Vector2(155, temp_y))
				bottom_pos = top_pos + (deck.size() * shift)
				get_node("cards_left").set_text(str(deck.size()))
				
				
				anchor = deck.find(pair[1])
				index = anchor + 1
				while(index < deck.size()):
					var position = deck[index].get_pos()
					position.y = deck[index - 1].get_pos().y + shift
					deck[index].set_pos(position)
					index += 1
				index = anchor - 1
				while(index > -1):
					var position = deck[index].get_pos()
					position.y = deck[index + 1].get_pos().y - shift
					deck[index].set_pos(position)
					index -= 1
				
				var save_data = create_deck_data()
				save(save_data)
			else:
				print("Invalid discard")
		else:
			print("No Match")
		counter = 1
	
	if(pair.size() != 2):
		counter = 0
	
	#depth, aabb, selection, opacity
	for i in range(deck.size()):
		deck[i].set_z(i)
		deck[i].rect.pos = deck[i].get_pos()
		if(deck[i].is_selected == true):
			deck[i].set_modulate(Color(0.6,0.6,6.0))
		else:
			deck[i].set_modulate(Color(1.0,1.0,1.0))
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
		for i in range(deck.size() - 1):
			var index = (deck.find(two[0]) + i) % (deck.size())
			if(is_match(two[0].suit, two[0].rank, deck[index].suit, deck[index].rank) == IS_MATCH):
				two.append(deck[index])
				var cur_index = (deck.find(two[0]) + 1) % (deck.size())
				var compare = deck[cur_index]
				if(compare != two[1]):
					var matching = true
					cur_index = (cur_index + 1) % (deck.size())
					while(matching == true and deck[cur_index] != two[1]):
						if(is_match(compare.suit, compare.rank, deck[cur_index].suit, deck[cur_index].rank) != IS_MATCH):
							matching = false
						cur_index = (cur_index + 1) % (deck.size())
					if(matching == true):
						moves_left = true
						break
				two.pop_back()
		two.clear()
		if(moves_left == true):
			break
	
	if(moves_left == false and printed == false):
		get_node("end_screen/end_message").show()
		save("0")
		if(deck.size() == 2):
			print("You win")
			get_node("end_screen/end_message").set_text("You Win!")
		else:
			print("Out of Moves")
			get_node("end_screen/end_message").set_text("Out of Moves")
		printed = true
	
	if(get_node("cards_left").is_pressed()):
		if(hold < 0.9):
			hold += delta
		else:
			#start new game
			
			#remove old cards
			for i in range(deck.size()):
				remove_child(deck[i])
			deck.clear()
			
			#create new cards
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
			
			top_pos = -120
			var depth = 0
			var column = Vector2(155, (top_pos + (shift/2)))
			for i in range(deck.size()):
				deck[i].set_pos(column)
				deck[i].set_z(depth)
				column.y += shift
				depth += 1
			bottom_pos = top_pos + (deck.size() * shift)
			
			var save_data = create_deck_data()
			save(save_data)
			get_node("end_screen/end_message").hide()
			get_node("cards_left").set_text(str(deck.size()))
			hold = 0.0
			printed = false
	else:
		hold = 0.0

func rand_range_int(low, high):
	randomize()
	return randf() * (high - low) + low

func add_to_selected(card):
	selected.append(card)

func is_match(suit1, rank1, suit2, rank2):
	
	if (suit1 == suit2 and rank1 == rank2):
		return EXACT_COPY
	elif (suit1 == suit2 or rank1 == rank2):
		return IS_MATCH
	else:
		return NO_MATCH

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