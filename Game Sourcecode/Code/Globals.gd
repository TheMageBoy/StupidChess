extends Node

# Sides
const Duck: int = 0
const White: int = 1
const Black: int = 2
const Win_State: int = 999

# Piece IDs

const Dummy: 			int = 0

const Messenger: 		int = 1
const Guard: 			int = 2
const Innkeeper: 		int = 3
const Doctor: 			int = 4
const Weaver: 			int = 5
const Clerk: 			int = 6
const Blacksmith: 		int = 7
const Farmer: 			int = 8

const Knight: 			int = 9
const Bishop: 			int = 10
const Rook: 			int = 11
const Queen: 			int = 12
const King: 			int = 13

const Grasshopper: 		int = 14
const Cannon: 			int = 15
const Jester: 			int = 16
const Angel: 			int = 17
const Nightrider: 		int = 18
const Bull: 			int = 19
const Archer:			int = 20
const Bomb: 			int = 21
const Trebuchet: 		int = 22
const Samurai: 			int = 23
const Ship: 			int = 24
const Querquisite: 		int = 25
const Clock:			int = 26
const Mercenary: 		int = 27
const Sheriff:	 		int = 28
const Windmill:			int = 29
const Archbishop:		int = 30
const Bastion:			int = 31
const Soldier: 			int = 32
const Centurion:		int = 33

# Movement Types
const Place: int = -1 # places down a piece onto the board from hand
const Basic: int = 0
const Capture: int = 1
const Projectile: int = 2 # capture the foe without movement
const SpecialCapture: int = 3 # kills foe and moves but different spaces
const Swap: int = 4
#ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀꜱᴛᴜᴠᴡxʏᴢ
var PieceWiki: Array = [
	PieceData.new().create("Dummy", "Pawn", "⚠", 1),
	PieceData.new().create("Messenger", "Pawn", "", 1),
	PieceData.new().create("Guard", "Pawn", "", 1),
	PieceData.new().create("Innkeeper", "Pawn", "", 1),
	PieceData.new().create("Doctor", "Pawn", "", 1),
	PieceData.new().create("Weaver", "Pawn", "", 1),
	PieceData.new().create("Clerk", "Pawn", "", 1),
	PieceData.new().create("Blacksmith", "Pawn", "", 1),
	PieceData.new().create("Farmer", "Pawn", "", 1),
	PieceData.new().create("Knight", "", "N", 3),
	PieceData.new().create("Bishop", "", "B", 3),
	PieceData.new().create("Rook", "", "R", 5),
	PieceData.new().create("Queen", "", "Q", 9),
	PieceData.new().create("King", "", "K", 0),
	PieceData.new().create("Grasshopper", "", "G", 3),
	PieceData.new().create("Cannon", "", "Cɴ", 2),
	PieceData.new().create("Jester", "", "J", 2),
	PieceData.new().create("Angel", "", "Aɢ", 4),
	PieceData.new().create("Nightrider", "", "N₂", 6),
	PieceData.new().create("Bull", "", "Bʟ", 5),
	PieceData.new().create("Archer", "", "A", 2),
	PieceData.new().create("Bomb", "", "X", 2),
	PieceData.new().create("Trebuchet", "", "T", 3),
	PieceData.new().create("Samurai", "", "侍", 4),
	PieceData.new().create("Ship", "", "S", 2),
	PieceData.new().create("Querquisite", "", "?", 4),
	PieceData.new().create("Clocktower", "Clocktower/", "Cᴛ", 5),
	PieceData.new().create("Mercenary", "", "M", 4),
	PieceData.new().create("Sheriff", "", "Sʀ", 4),
	PieceData.new().create("Windmill", "", "W", 1),
	PieceData.new().create("Archbishop", "", "B₂", 6),
	PieceData.new().create("Bastion", "", "R₂", 6),
	PieceData.new().create("Soldier", "", "ꜱ", 1),
	PieceData.new().create("Centurion", "", "C", 1),
]
# movement

func pawn_movement(board: Dictionary, piece_pos: Vector2i, side: int, has_moved: bool) -> Array:
	var return_array = []
	# direction moved based on side
	var dir := 1 if (side == Black) else -1
	# check move
	var tiles := 1 if has_moved else 2
	var has_move := true
	var i := 0
	var pos = piece_pos
	while has_move and i < tiles:
		pos = pos + Vector2i(0, dir)
		if exists(board, pos) && !occupied(board, pos):
			return_array.append([Basic, pos])
		else:
			has_move = false
		i += 1
	pos = piece_pos + Vector2i(1, dir)
	if exists(board, pos) && occupied_by_foe(board, pos, side ):
		return_array.append([Capture, pos])
	pos = piece_pos + Vector2i(-1, dir)
	if exists(board, pos) && occupied_by_foe(board, pos, side ):
		return_array.append([Capture, pos])
	
	pos = piece_pos + Vector2i(1, dir)
	var pos2 = piece_pos + Vector2i(1, 0)
	if exists(board, pos) and occupied_by_foe(board, pos2, side) and board[pos2].piece_type < Knight and board[pos2].en_passant:
		return_array.append([SpecialCapture, pos, pos2])
	
	pos = piece_pos + Vector2i(-1, dir)
	pos2 = piece_pos + Vector2i(-1, 0)
	if exists(board, pos) && occupied_by_foe(board, pos2, side) and board[pos2].piece_type < Knight and board[pos2].en_passant:
		return_array.append([SpecialCapture, pos, pos2])
	
	return return_array

func horse_movement(board: Dictionary, piece_pos: Vector2i, side: int, infinite_move: bool, jump_type: Array = [2, 1]) -> Array:
	var return_array = []
	var pos = piece_pos
	var legal_tiles := true
	var values = [-jump_type[0], -jump_type[1], jump_type[1], jump_type[0]]	
	for a in values:
		for b in values:
			if abs(a) != abs(b):
				legal_tiles = true
				pos = piece_pos
				while legal_tiles:
					pos = pos + Vector2i(a, b)
					if exists(board, pos):
						if occupied_by_foe(board, pos, side):
							return_array.append([Capture, pos])
							legal_tiles = false
						elif !occupied(board, pos): 
							return_array.append([Basic, pos])
						else:
							legal_tiles = false
					else:
						legal_tiles = false
					# infinite move is really only for nightrider
					legal_tiles = legal_tiles and infinite_move
					
	return return_array
	
func bishop_movement(board: Dictionary, piece_pos: Vector2i, side: int, move_range: int, can_jump: bool, min_range: int, can_capture: bool) -> Array:
	var return_array = []
	var pos = piece_pos
	var legal_tiles := true
	var values = [-1, 1]
	var move := 0
	for a in values:
		for b in values:
			legal_tiles = true
			move = 0
			pos = piece_pos
			while legal_tiles:
				move += 1
				pos = pos + Vector2i(a, b)
				if exists(board, pos):
					if occupied_by_foe(board, pos, side) and move >= min_range:
						if can_capture:
							return_array.append([Capture, pos])
						legal_tiles = legal_tiles and can_jump
					elif occupied(board, pos):
						legal_tiles = legal_tiles and can_jump
					elif move >= min_range: 
						return_array.append([Basic, pos])
				else:
					legal_tiles = false
				legal_tiles = legal_tiles and (move < move_range)
	return return_array

func rook_movement(board: Dictionary, piece_pos: Vector2i, side: int, move_range: int, can_jump: bool, min_range: int, can_capture: bool) -> Array:
	var return_array = []
	var pos = piece_pos
	var legal_tiles := true
	var values = [-1, 1, 0]
	var move := 0
	for a in values:
		for b in values:
			if (a == 0) != (b == 0):
				legal_tiles = true
				move = 0
				pos = piece_pos
				while legal_tiles:
					move += 1
					pos = pos + Vector2i(a, b)
					if exists(board, pos):
						if occupied_by_foe(board, pos, side) and move >= min_range:
							if can_capture:
								return_array.append([Capture, pos])
							legal_tiles = legal_tiles and can_jump
						elif occupied(board, pos):
							legal_tiles = legal_tiles and can_jump
						elif move >= min_range: 
							return_array.append([Basic, pos])
					else:
						legal_tiles = false
					legal_tiles = legal_tiles and (move < move_range)
	return return_array

func real_grasshopper_movement(board: Dictionary, piece_pos: Vector2i, side: int) -> Array:
	var return_array = []
	var pos = piece_pos
	var legal_tiles := true
	var values = [-1, 1]
	var encountered_jumpable := false
	# bishop
	for a in values:
		for b in values:
			legal_tiles = true
			pos = piece_pos
			encountered_jumpable = false
			while legal_tiles:
				pos = pos + Vector2i(a, b)
				if exists(board, pos):
					if occupied(board, pos) and !encountered_jumpable:
						encountered_jumpable = true
					elif occupied_by_foe(board, pos, side) and encountered_jumpable:
						return_array.append([Capture, pos])
					elif encountered_jumpable and !occupied(board, pos): 
						return_array.append([Basic, pos])
				else:
					legal_tiles = false
	# rook
	values = [-1, 1, 0]
	for a in values:
		for b in values:
			if (a == 0) != (b == 0):
				legal_tiles = true
				pos = piece_pos
				encountered_jumpable = false
				while legal_tiles:
					pos = pos + Vector2i(a, b)
					if exists(board, pos):
						if occupied(board, pos) and !encountered_jumpable:
							encountered_jumpable = true
						elif occupied_by_foe(board, pos, side) and encountered_jumpable:
							return_array.append([Capture, pos])
						elif encountered_jumpable and !occupied(board, pos): 
							return_array.append([Basic, pos])
					else:
						legal_tiles = false
	return return_array
	
func grasshopper_movement(board: Dictionary, piece_pos: Vector2i, side: int) -> Array:
	var return_array = []
	var pos = piece_pos
	var legal_tiles := true
	var values = [-1, 1]
	var encountered_jumpable := false
	var first := true
	# bishop
	for a in values:
		for b in values:
			legal_tiles = true
			pos = piece_pos
			encountered_jumpable = false
			first = true
			while legal_tiles:
				pos = pos + Vector2i(a, b)
				if exists(board, pos):
					if occupied(board, pos) and !encountered_jumpable and first:
						encountered_jumpable = true
					elif occupied_by_foe(board, pos, side) and encountered_jumpable:
						return_array.append([Capture, pos])
					elif encountered_jumpable and !occupied(board, pos): 
						return_array.append([Basic, pos])
					elif first:
						legal_tiles = false
				else:
					legal_tiles = false
				first = false
	# rook
	values = [-1, 1, 0]
	for a in values:
		for b in values:
			if (a == 0) != (b == 0):
				legal_tiles = true
				pos = piece_pos
				encountered_jumpable = false
				first = true
				while legal_tiles:
					pos = pos + Vector2i(a, b)
					if exists(board, pos):
						if occupied(board, pos) and !encountered_jumpable and first:
							encountered_jumpable = true
						elif occupied_by_foe(board, pos, side) and encountered_jumpable:
							return_array.append([Capture, pos])
						elif encountered_jumpable and !occupied(board, pos): 
							return_array.append([Basic, pos])
						elif first:
							legal_tiles = false
					else:
						legal_tiles = false
					first = false
	return return_array
	
func trebuchet_movement_extension(board: Dictionary, piece_pos: Vector2i, side: int) -> Array:
	var values = [0, -1, 1]
	var return_array := []
	var legal_tiles := true
	var pos = 0
	var can_jump = false
	for a in values:
		for b in values:
			if a != 0 or b != 0:
				legal_tiles = false
				pos = piece_pos  + Vector2i(a, b)
				if exists(board, pos) and occupied(board, pos) and board[pos].piece_type == Globals.Trebuchet and board[pos].side == side:
					legal_tiles = true
				while legal_tiles:
					pos = pos + Vector2i(a, b)
					if exists(board, pos):
						if occupied_by_foe(board, pos, side):
							return_array.append([Capture, pos])
							legal_tiles = legal_tiles and can_jump
						elif occupied(board, pos):
							legal_tiles = legal_tiles and can_jump
						else: 
							return_array.append([Basic, pos])
					else:
						legal_tiles = false
	return return_array
	

func exists(board: Dictionary, pos: Vector2i) -> bool: #checks if a particular position exists
	return board.has(pos)

func occupied(board: Dictionary, pos: Vector2i) -> bool:
	return board[pos] != null
	
func occupied_by_foe(board: Dictionary, pos: Vector2i, side: int) -> bool:
	if !occupied(board, pos):
		return false
	if board[pos].side == Duck:
		return false
	elif board[pos].side == side:
		return false
	return true

var directions = [
		Vector2i(0, -1),  # N
		Vector2i(1, -1),   # NE
		Vector2i(1, 0),   # E
		Vector2i(1, 1),   # SE
		Vector2i(0, 1),   # S
		Vector2i(-1, 1),  # SW
		Vector2i(-1, 0),  # W
		Vector2i(-1, -1), # NW	
	]

func rotate_clock(direction: Vector2i):
	
	var index = directions.find(direction)
	if index == -1:
		return direction  # return unchanged if not
	return directions[(index + 1) % directions.size()]
	
func directional_movement(board: Dictionary, piece_pos: Vector2i, side: int, move_range: int, can_jump: bool, min_range: int, can_capture: bool , directions: Array) -> Array:
	var return_array = []
	var pos = piece_pos
	var legal_tiles := true
	var values = [-1, 1, 0]
	var move := 0
	for direction in directions:
		var a = direction.x
		var b = direction.y
		legal_tiles = true
		move = 0
		pos = piece_pos
		while legal_tiles:
			move += 1
			pos = pos + Vector2i(a, b)
			if exists(board, pos):
				if occupied_by_foe(board, pos, side) and move >= min_range:
					if can_capture:
						return_array.append([Capture, pos])
					legal_tiles = legal_tiles and can_jump
				elif occupied(board, pos):
					legal_tiles = legal_tiles and can_jump
				elif move >= min_range: 
					return_array.append([Basic, pos])
			else:
				legal_tiles = false
			legal_tiles = legal_tiles and (move < move_range)
	return return_array

var base_pieces: Array = [
	
	[Vector2i(3,4), Globals.Soldier, Globals.White],
	[Vector2i(0,6), Globals.Messenger, Globals.White],
	[Vector2i(1,6), Globals.Guard, Globals.White],
	[Vector2i(2,6), Globals.Innkeeper, Globals.White],
	[Vector2i(3,6), Globals.Doctor, Globals.White],
	[Vector2i(4,6), Globals.Weaver, Globals.White],
	[Vector2i(5,6), Globals.Clerk, Globals.White],
	[Vector2i(6,6), Globals.Blacksmith, Globals.White],
	[Vector2i(7,6), Globals.Farmer, Globals.White],
	
	[Vector2i(0,7), Globals.Rook, Globals.White],
	[Vector2i(1,7), Globals.Knight, Globals.White],
	[Vector2i(2,7), Globals.Bishop, Globals.White],
	[Vector2i(3,7), Globals.Queen, Globals.White],
	[Vector2i(4,7), Globals.King, Globals.White],
	[Vector2i(5,7), Globals.Bishop, Globals.White],
	[Vector2i(6,7), Globals.Knight, Globals.White],
	[Vector2i(7,7), Globals.Rook, Globals.White],
	
	[Vector2i(0,1), Globals.Messenger, Globals.Black],
	[Vector2i(1,1), Globals.Guard, Globals.Black],
	[Vector2i(2,1), Globals.Innkeeper, Globals.Black],
	[Vector2i(3,1), Globals.Doctor, Globals.Black],
	[Vector2i(4,1), Globals.Weaver, Globals.Black],
	[Vector2i(5,1), Globals.Clerk, Globals.Black],
	[Vector2i(6,1), Globals.Blacksmith, Globals.Black],
	[Vector2i(7,1), Globals.Farmer, Globals.Black],
	
	[Vector2i(0,0), Globals.Rook, Globals.Black],
	[Vector2i(1,0), Globals.Knight, Globals.Black],
	[Vector2i(2,0), Globals.Bishop, Globals.Black],
	[Vector2i(3,0), Globals.Queen, Globals.Black],
	[Vector2i(4,0), Globals.King, Globals.Black],
	[Vector2i(5,0), Globals.Bishop, Globals.Black],
	[Vector2i(6,0), Globals.Knight, Globals.Black],
	[Vector2i(7,0), Globals.Rook, Globals.Black],
	
]

var who_plays = {
	White: "Player",
	Black: "AI",
}

func _on_vs_ai_pressed() -> void:
	if randi_range(0,1) == 0:
		who_plays[White] = "Player"
		who_plays[Black] = "AI"
	else:
		who_plays[White] = "AI"
		who_plays[Black] = "Player"
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _on_pvp_pressed() -> void:
	who_plays[White] = "Player"
	who_plays[Black] = "Player"
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _back_to_main() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main Menu.tscn")
