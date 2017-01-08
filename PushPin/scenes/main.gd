
extends Node2D

const EXACT_COPY = 2
const IS_MATCH = 1
const NO_MATCH = 0
const NORMAL_SPEED = 300
var deck = []
var selected = []
var pair = [] #used for discarding
var deck_index = 0
var counter = 0
var top_pos = -60
var bottom_pos
var shift = 60
var cards = preload("res://scenes/card.xscn")
var suits = ["C","D","H","S"]
var ranks = ["A", "2", "3", "4", "5",
			"6", "7", "8", "9", "X",
			"J", "Q", "K"]

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here\
	
	#create cards
	for i in range(suits.size()):
		for j in range(ranks.size()):
			var card_instance = cards.instance()
			var texture = load("res://cards/" + suits[i] + ranks[j] + ".png")
			card_instance.suit = suits[i]
			card_instance.rank = ranks[j]
			card_instance.set_texture(texture)
			
			deck.append(card_instance)
			add_child(card_instance)
	
	#shuffle deck
	for i in range(deck.size()):
		var num = rand_range_int(i, 51)
		var temp = deck[i]
		deck[i] = deck[num]
		deck[num] = temp
	
	bottom_pos = top_pos + (deck.size() * shift) 
	var column = Vector2(155, (top_pos + shift))
	var depth = 0
	for i in range(deck.size()):
		deck[i].set_pos(column)
		deck[i].set_z(depth)
		column.y += shift
		depth += 1
	set_process(true)

func _process(delta):
	#uneven cards occur because once a card is deleted
	#the loop skips the top or bottom card which isn't
	#updated and is kept where it is while the other
	#cards are updated. 
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
					
				anchor = deck.find(pair[1])
				
				#reshaping the deck
				if(deck.size() > 14):
					if(match_up == true):
						var space = floor(((deck[anchor].get_pos().y - top_pos) / shift))
						space = space - anchor
						for i in range(space):
							var last = deck.size() - 1
							var temp = deck[last]
							deck.pop_back()
							deck.push_front(temp)
					
					bottom_pos = top_pos + (deck.size() * shift)
				else:
					print("Deck is small")
				
				
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
			else:
				print("Invalid discard")
		else:
			print("No Match")
		counter = 1
	
	if(pair.size() != 2):
		counter = 0
	
	for i in range(deck.size()):
		deck[i].set_z(i)
		deck[i].rect.pos = deck[i].get_pos()
		if(deck[i].is_selected == true):
			deck[i].set_modulate(Color(0.6,0.6,6.0))
		else:
			deck[i].set_modulate(Color(1.0,1.0,1.0))

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

