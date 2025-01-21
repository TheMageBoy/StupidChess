extends Node

class_name PieceData

var piece_name: String = ""
var piece_sprite: String = "Pawn"
var piece_notation: String = ""
var flip_sprite: bool = false
var piece_info: String = ""
var value: int = 0

func create(_name: String, _sprite: String, notation: String, val: int, info: String):
	piece_name = _name
	piece_sprite = _sprite if _sprite != "" else _name
	piece_notation = notation
	value = val
	piece_info = info
	return self
