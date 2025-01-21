extends Node

class_name Piece

var piece_type: int = 0
var board_position: Vector2i = Vector2i(0,0)
var side: int = 0
var has_moved = false
var en_passant = false # can be killed by en_passant
var bonus_num = -1
var hour_hand: Vector2i = Vector2i(0,0)
var minute_hand: Vector2i = Vector2i(0,0)

func initialize(the_type: int, pos: Vector2i, _side: int):
	piece_type = the_type
	board_position = pos
	side = _side

func update_piece(side_turn, new_sprite, benched = false):
	if side == side_turn:
		en_passant = false
	var sprite = get_child(0)
	sprite.texture = new_sprite
	
	if piece_type == Globals.Mercenary and !benched:
		side = side_turn
