
extends Sprite

var suit
var rank
var is_selected
var rect


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	rect = Rect2(self.get_pos(), self.get_texture().get_size())
	is_selected = false
	set_process_input(true)

func _input(event):
	if((event.type == InputEvent.MOUSE_BUTTON or event.type == InputEvent.SCREEN_TOUCH)):
		if(rect.has_point(event.pos) and event.is_pressed()):
			get_node("../").add_to_selected(self)