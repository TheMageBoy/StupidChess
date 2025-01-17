extends Node2D

@export var board_tiles: Vector2i = Vector2(8, 8)
var screen_size: Vector2i = Vector2i(1152, 648) #DisplayServer.window_get_size()
@export var square_size: int = 60

var top_left_tile: Vector2i = (screen_size - board_tiles * square_size) / 2

var based_pieces: Array = [

	[Vector2i(0,0), Globals.Archer, Globals.White],
	[Vector2i(0,2), Globals.Clock, Globals.Black]
	
]

@export var pieces: Dictionary = {
	Vector2i(99,99): null
}
var current_piece_clicked: Node2D = null # current piece being clicked whose movement options are being shown
var movement_icons: Array = []

var move_history: Array = []

var turn: int = Globals.White
var max_players = 2

var bonus = {
	Globals.White: [],
	Globals.Black: []
}

var clocks = {
	Globals.White: [Vector2i(0, -1), Vector2i(0, -1)],
	Globals.Black: [Vector2i(1, 1), Vector2i(1, 1)]
}

var waiting_for_player := true
var ai_timer := 0

var side_turn := Globals.White

var forced_prize = -1

func _ready() -> void:
	for row in range(board_tiles.y):
		for column in range(board_tiles.x):
			pieces[Vector2i(column, row)] = null
	var poses = calculate_positions(0, square_size * (board_tiles.y - 1), 5)
	var poses2 = poses.duplicate()
	poses2.reverse()
	for x in range(5):
		create_prize_boxes(x, poses2, Globals.White, top_left_tile.x - (5 * square_size)/4)
		create_prize_boxes(x, poses, Globals.Black, top_left_tile.x + board_tiles.x * square_size + (1 * square_size)/4)
	_draw()
	create_init_pieces()

@onready var turn_display: RichTextLabel = $"Turn Display"	
@onready var move_history_white: VBoxContainer = $"Move History/Split/WhiteList"
@onready var move_history_black: VBoxContainer = $"Move History/Split/BlackList"
@onready var scroll_bar: ScrollContainer = $"Move History"

func advance_turn():
		
	current_piece_clicked = null
	side_turn += 1
	if side_turn > Globals.Black:
		side_turn = Globals.White
	if Globals.who_plays[side_turn] == "Player":
		waiting_for_player = true
	else:
		ai_timer = 40
	if win == Globals.White:
		turn_display.text = "White Wins"
	elif win == Globals.Black:
		turn_display.text = "Black Wins"
	elif side_turn == Globals.White:
		turn_display.text = "White's Turn"
	else:
		turn_display.text = "Black's Turn"
	#rotate side clocks
	clocks[side_turn][0] = Globals.rotate_clock(clocks[side_turn][0])
	if side_turn == Globals.White and clocks[side_turn][0] == Vector2i(0, -1):
		clocks[side_turn][1] = Globals.rotate_clock(clocks[side_turn][1])
	elif side_turn == Globals.Black and clocks[side_turn][0] == Vector2i(0, 1):
		clocks[side_turn][1] = Globals.rotate_clock(clocks[side_turn][1])
	#
	for key in pieces.keys():
		if pieces[key] != null:
			pieces[key].get_child(1).get_child(0).disabled = true
			# disable en passant
			if pieces[key].en_passant and pieces[key].side == side_turn:
				pieces[key].en_passant = false
			# update clock sprites
			if pieces[key].piece_type == Globals.Clock and pieces[key].side == side_turn:
				var clockno = str(Globals.directions.find(clocks[side_turn][1])) + str(Globals.directions.find(clocks[side_turn][0]))
				pieces[key].get_child(0).texture = load("res://Graphics/Pieces/Clocktower/"+clockno+".png")
			if pieces[key].piece_type == Globals.Mercenary:
				pieces[key].side = side_turn
		if pieces[key] != null and side_turn == pieces[key].side and Globals.who_plays[side_turn] == "Player" and win == -1:
			pieces[key].get_child(1).get_child(0).disabled = false
	
	for x in range(5):
		bonus[Globals.White][x].piece_node.get_child(1).get_child(0).disabled = true
		bonus[Globals.Black][x].piece_node.get_child(1).get_child(0).disabled = true
		if Globals.who_plays[side_turn] == "Player" and bonus[side_turn][x].prize != -1 and win == -1:
			bonus[side_turn][x].piece_node.get_child(1).get_child(0).disabled = false
		if bonus[Globals.White][x].prize == Globals.Clock and Globals.White == side_turn:
			var clockno = str(Globals.directions.find(clocks[side_turn][1])) + str(Globals.directions.find(clocks[side_turn][0]))
			bonus[Globals.White][x].piece_node.get_child(0).texture = load("res://Graphics/Pieces/Clocktower/"+clockno+".png")
		elif bonus[Globals.Black][x].prize == Globals.Clock and Globals.Black == side_turn:
			var clockno = str(Globals.directions.find(clocks[side_turn][1])) + str(Globals.directions.find(clocks[side_turn][0]))
			bonus[Globals.Black][x].piece_node.get_child(0).texture = load("res://Graphics/Pieces/Clocktower/"+clockno+".png")
	if win != -1:
		game_done = true

func _draw():
	for row in range(board_tiles.y):
		for column in range(board_tiles.x):
			var tile_position = top_left_tile + Vector2i(column, row) * square_size
			var color = Color(0.2, 0.2, 0.2) if (row + column) % 2 == 0 else Color(0.8, 0.8, 0.8)
			draw_rect(Rect2(tile_position, Vector2(square_size, square_size)), color)

func calculate_positions(start, end, count):
	var step = (end - start) / (count - 1)  # Divide into 4 gaps for 5 boxes
	
	var positions = []
	for i in range(count):
		var position = start + (step * i)
		positions.append(position)
	return positions

func create_prize_boxes(x, poses, side, xpos):
	var box = Node2D.new()
	var script = load("res://Code/Prize.gd")
	box.set_script(script)
	box.prize = -1
	box.position = Vector2i(xpos, top_left_tile.y + poses[x])
		
	var new_piece = create_piece(Vector2i(99,99), Globals.Dummy, side)
	new_piece.bonus_num = x
	new_piece.position = Vector2i(xpos, top_left_tile.y + poses[x])
	pieces[Vector2i(99,99)] = null
	new_piece.get_child(0).visible = false
	new_piece.get_child(1).get_child(0).disabled = true
	box.piece_node = new_piece
	
	self.add_child(box)
	bonus[side].append(box)

func create_piece(board_position: Vector2i, piece_id: int, side: int) -> Node2D:
	if !pieces.has(board_position):
		return null
	if pieces[board_position] != null:
		return null
	
	var piece = Node2D.new()
	var data = Globals.PieceWiki[piece_id]
	
	var script = load("res://Code/Piece.gd")
	piece.set_script(script)
	piece.call("initialize", piece_id, board_position, side) 
	
	var spr_p = ""
	if piece_id == Globals.Clock:
		spr_p = str(Globals.directions.find(clocks[side][1])) + str(Globals.directions.find(clocks[side][0]))
	var sprite = Sprite2D.new()
	
	sprite.texture = load("res://Graphics/Pieces/"+data.piece_sprite+spr_p+".png")
	var shared_material = load("res://Graphics/PieceShaderMaterial.tres")
	sprite.material = shared_material.duplicate()
	var shader_material = sprite.material as ShaderMaterial
	if side == Globals.Black:
		shader_material.set("shader_param/new_color", Color(0.36, 0.36, 0.36, 1.0))
	elif side == Globals.White:
		shader_material.set("shader_param/new_color", Color(1.0, 1.0, 1.0, 1.0))
	
	sprite.centered = false
	var texture_size = sprite.texture.get_size()
	var scale_factor = Vector2(square_size, square_size) / texture_size
	sprite.scale = scale_factor
	
	piece.add_child(sprite)
	piece.position = board_position * square_size + top_left_tile
	self.add_child(piece)
	pieces[board_position] = piece
	
	var area = Area2D.new()
	piece.add_child(area)
	var collision_shape = CollisionShape2D.new()
	if turn != side:
		collision_shape.disabled = true
	area.add_child(collision_shape)
	area.position += Vector2(square_size/2, square_size/2)
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(square_size/2, square_size/2)  # Set the size of the rectangle (half-width, half-height)
	collision_shape.shape = rectangle_shape
	area.connect("input_event", Callable(self.on_piece_clicked).bind(piece))
	
	return piece

func create_init_pieces():
	for piece in Globals.base_pieces:
		var _new_piece = create_piece(piece[0], piece[1], piece[2])

func Vector2ToTileName(board_position: Vector2i) -> String:
	var char = String.chr("a".unicode_at(0) + board_position.x)
	return char + str(board_tiles.y - board_position.y)

func on_piece_clicked(viewport, event, shape_idx, piece):
	if event is InputEventMouseButton and event.pressed:
		if current_piece_clicked == null:
			var piece_options := get_piece_movement(piece)
			if piece_options.size() > 0:
				clear_icons()
				current_piece_clicked = piece
			for option in piece_options:
				#print(option)
				draw_icon(option)
		elif current_piece_clicked == piece:
			current_piece_clicked = null
			clear_icons()

func count_piece(piece_id: int, side: int):
	var n = 0
	for key in pieces.keys():
		if pieces[key] != null:
			if pieces[key].piece_type == piece_id and pieces[key].side == side:
				n += 1
	return n

func get_piece_movement(piece: Node2D) -> Array:
	var piece_id = piece.piece_type
	var move := []
	match piece_id:
		Globals.Dummy:
			var file = 0
			if side_turn == Globals.White:
				file = 5
			for key in pieces.keys():
				if pieces[key] == null and key.y >= file and key.y <= file + 2:
					move.append([Globals.Place, key, bonus[side_turn][piece.bonus_num].prize , piece.bonus_num])
		Globals.Messenger, Globals.Guard, Globals.Innkeeper, Globals.Doctor, Globals.Weaver, Globals.Clerk, Globals.Blacksmith, Globals.Farmer:
			var dist = 1 + count_piece(Globals.Centurion, side_turn)
			var dir = Vector2i(0,1)
			if !piece.has_moved:
				dist += 1
			if piece.side == Globals.White:
				dir = Vector2i(0,-1)
			move = Globals.directional_movement(pieces, piece.board_position, side_turn, dist, false, 1, false, [dir])
			var en = [-1, 1]
			for a in en:
				var pos = piece.board_position + Vector2i(a,dir.y)
				var pos2 = piece.board_position + Vector2i(a,0)
				if pieces.has(pos) and Globals.occupied_by_foe(pieces, pos, side_turn):
					move.append([Globals.Capture, pos])
				elif pieces.has(pos) and Globals.occupied_by_foe(pieces, pos2, side_turn) and pieces[pos2].en_passant == true:
					move.append([Globals.SpecialCapture, pos, pos2])
			#move = Globals.pawn_movement(pieces, piece.board_position, piece.side, piece.has_moved)
		Globals.Knight:
			move = Globals.horse_movement(pieces, piece.board_position, piece.side, false)
		Globals.Bishop:
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
		Globals.Rook:
			move = Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
		Globals.Queen, Globals.Mercenary:
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true) + Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
		Globals.King, Globals.Centurion:
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 1, false, 1,true) + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false , 1, true)
		Globals.Querquisite:
			if piece.board_position.x == 0 or piece.board_position.x == 7:
				move = Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			elif piece.board_position.x == 1 or piece.board_position.x == 6:
				move = Globals.horse_movement(pieces, piece.board_position, piece.side, false)
			elif piece.board_position.x == 2 or piece.board_position.x == 5:
				move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			elif piece.board_position.x == 3:
				move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true) + Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			else:
				move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 1, false, 1,true) + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false , 1, true)
		Globals.Nightrider:
			move = Globals.horse_movement(pieces, piece.board_position, piece.side, true)
		Globals.Grasshopper:
			move = Globals.real_grasshopper_movement(pieces, piece.board_position, piece.side)
		Globals.Cannon:
			var cannon := Globals.bishop_movement(pieces, piece.board_position, piece.side, 3, true, 2, true)
			var attacks := []
			var temp = []
			for moves in cannon:
				if moves[0] == Globals.Capture:
					temp = moves
					temp[0] = Globals.Projectile
					attacks.append(temp)
			move = attacks + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false, 1, false)
		Globals.Archer:
			var cannon := Globals.rook_movement(pieces, piece.board_position, piece.side, 2, true, 2, true) + Globals.bishop_movement(pieces, piece.board_position, piece.side, 1, true, 1, true)
			var attacks := []
			var temp = []
			for moves in cannon:
				if moves[0] == Globals.Capture:
					temp = moves
					temp[0] = Globals.Projectile
					attacks.append(temp)
			move = attacks + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false, 1, false)
		Globals.Bull:
			var bull := Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			bull += Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			bull += Globals.horse_movement(pieces, piece.board_position, piece.side, false)
			var attacks_only := []
			for moves in bull:
				if moves[0] == Globals.Capture:
					attacks_only.append(moves)
			if attacks_only.size() > 0:
				move = attacks_only
			else:
				move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 1, false, 1, false) + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false, 1, false)
		Globals.Trebuchet:
			move = Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false, 1, false)
		Globals.Samurai:
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, true, 1, false) + Globals.rook_movement(pieces, piece.board_position, piece.side, 99, true, 1, false) + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false, 1, true)
		Globals.Angel:
			for key in pieces.keys():
				if pieces[key] == null and alt_under_attack(piece, key).size() > 0:
					move.append([Globals.Basic, key])
				elif pieces[key] != null and pieces[key].side == side_turn and pieces[key] != piece:
					move.append([Globals.Swap, key])
		Globals.Ship:
			if pieces.has(piece.board_position + Vector2i(-1, 0)):
				move += Globals.directional_movement(pieces, piece.board_position + Vector2i(-1, 0), piece.side, 99, false, 1, true, [Vector2i(0,1), Vector2i(0,-1)])
			if pieces.has(piece.board_position + Vector2i(1, 0)):
				move += Globals.directional_movement(pieces, piece.board_position + Vector2i(1, 0), piece.side, 99, false, 1, true, [Vector2i(0,1), Vector2i(0,-1)])
		Globals.Clock:
			move += Globals.directional_movement(pieces, piece.board_position, piece.side, 3, true, 1, true, [clocks[piece.side][0]])
			move += Globals.directional_movement(pieces, piece.board_position, piece.side, 99, false, 1, true, [clocks[piece.side][1]])
		Globals.Sheriff:
			var cannon := Globals.rook_movement(pieces, piece.board_position, piece.side, 2, true, 2, true)
			var attacks := []
			var temp = []
			for moves in cannon:
				if moves[0] == Globals.Capture:
					temp = moves
					temp[0] = Globals.Projectile
					attacks.append(temp)
			move = attacks + Globals.horse_movement(pieces, piece.board_position, piece.side, false)
		Globals.Windmill:
			var adjs := []
			for pos in Globals.directions:
				if Globals.exists(pieces, piece.board_position + pos):
					adjs.append(piece.board_position + pos)
			for adj in adjs:
				var relative_pos = adj - piece.board_position
				var init = Globals.directions.find(relative_pos)
				var x = 1
				var hit_wall = false
				while x % Globals.directions.size() != 0 and !hit_wall:
					var square = adj + Globals.directions[ (init + x) % Globals.directions.size() ]
					if Globals.exists(pieces, square) and !Globals.occupied(pieces, square):
						move.append([Globals.Basic, square])
					x += 1
		Globals.Archbishop:
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			var values = [-1, 1]
			for a in values:
				for b in values:
					if Globals.exists(pieces, piece.board_position + Vector2i(a, b)):
						move += Globals.bishop_movement(pieces, piece.board_position + Vector2i(a, b), piece.side, 99, false, 1, true)
		Globals.Bastion:
			move = Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			var values = [-1, 1]
			for a in values:
				if Globals.exists(pieces, piece.board_position + Vector2i(0, a)) and !Globals.occupied(pieces, piece.board_position + Vector2i(0, a)):
					move += Globals.rook_movement(pieces, piece.board_position + Vector2i(0, a), piece.side, 99, false, 1, true)
		Globals.Soldier:
			var dist = 1 + count_piece(Globals.Centurion, side_turn)
			var dir = Vector2i(0,1)
			if !piece.has_moved:
				dist += 1
			if piece.side == Globals.White:
				dir = Vector2i(0,-1)
			move = Globals.directional_movement(pieces, piece.board_position, side_turn, dist, false, 1, true, [dir])
			for i in range(move.size()):
				if move[i][0] == Globals.Capture:
					continue
				var pos = move[i][1]
				var values = [-1, 1]
				for a in values:
					var pos2 = pos + Vector2i(a,-dir.y)
					if pieces.has(pos2) and Globals.occupied_by_foe(pieces, pos2, side_turn) and pieces[pos2].en_passant == true:
						move[i] = [Globals.SpecialCapture, pos, pos2]
		_:
			print(piece_id)
	move = move + Globals.trebuchet_movement_extension(pieces, piece.board_position, piece.side)
	var final_return := {}
	for m in move:
		final_return[m] = true
	return final_return.keys() as Array
	
func draw_icon(args) -> bool:
	var move_type = args[0]
	var board_position = args[1]
	
	if !pieces.has(board_position): # check if its an illegal position
		return false
	
	var icon = Node2D.new()
	var moves = ["Dropmarker", "Basic", "Capture", "Shoot", "SpecialMove", "Swap"]
	
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Graphics/Icons/"+moves[move_type+1]+".png")
	
	sprite.centered = false
	var texture_size = sprite.texture.get_size()
	var scale_factor = Vector2(square_size, square_size) / texture_size
	sprite.scale = scale_factor
	
	icon.add_child(sprite)
	icon.position = board_position * square_size + top_left_tile
	self.add_child(icon)
	movement_icons.append(icon)
	
	var area = Area2D.new()
	icon.add_child(area)
	var collision_shape = CollisionShape2D.new()
	area.add_child(collision_shape)
	area.position += Vector2(square_size/2, square_size/2)
	
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.extents = Vector2(square_size/2, square_size/2) 
	collision_shape.shape = rectangle_shape
	area.connect("input_event", Callable(self.on_icon_clicked).bind(args))
	
	return true

# to move TODO
func on_icon_clicked(viewport, event, shape_idx, config):
	if event is InputEventMouseButton and event.pressed:
		var n = perform_move(current_piece_clicked, config)
		record_turn(n, side_turn)
		waiting_for_player = false

func clear_icons():
	for icon in movement_icons:
		icon.queue_free()
	movement_icons = []
	
func perform_move(piece, config):
	clear_icons()
	var pos = config[1]
	var move_type = config[0]
	
	if move_type == Globals.Place and config[2] != -1:
		# config[2] is the piece id, [3] is the prize piece number
		print("Creating Piece for side: "+str(side_turn)+" with number "+str(config[2]))
		var nota = Globals.PieceWiki[config[2]].piece_notation + "@" + Vector2ToTileName(pos)
		create_piece(pos,config[2],side_turn)
		if config[3] == 4:
			bonus[side_turn][4].prize = -1
			bonus[side_turn][4].piece_node.get_child(0).visible = false
		else:
			for x in range(config[3],4):
				var next = bonus[side_turn][x+1]
				var prize = next.prize
				if prize == -1:
					bonus[side_turn][x].prize = -1
					bonus[side_turn][x].piece_node.get_child(0).visible = false
					break
				else:
					bonus[side_turn][x].prize = prize
					var spr_p = ""
					if prize == Globals.Clock:
						spr_p = str(Globals.directions.find(clocks[side_turn][1])) + str(Globals.directions.find(clocks[side_turn][0]))
					bonus[side_turn][x].piece_node.get_child(0).texture = load("res://Graphics/Pieces/"+Globals.PieceWiki[prize].piece_sprite+spr_p+".png")
				if x == 3:
					bonus[side_turn][4].prize = -1
					bonus[side_turn][4].piece_node.get_child(0).visible = false		
			pieces[Vector2i(99,99)] = null
		return nota
	elif move_type == Globals.Place and config[2] == -1:
		print("Attempting to place illegal piece")
	
	var piece_id = piece.piece_type
	var data = Globals.PieceWiki[piece_id]
	
	#check if ANY other piece can perform this move (for notation)
	var has_same_rank = false
	var has_same_file = false
	var other_move = []
	for key in pieces.keys():
		if pieces[key] == null or pieces[key] == piece:
			continue
		elif pieces[key].side != piece.side:
			continue
		# sorry for this monstrosity, pawns are all different "types" so need this check
		elif pieces[key].piece_type != piece_id and not (piece_id < Globals.Knight and pieces[key].piece_type < Globals.Knight):
			continue
		else:
			other_move = get_piece_movement(pieces[key])
			for move in other_move:
				if move == config:
					if pieces[key].board_position.x == piece.board_position.x:
						has_same_file = true
					else:
						has_same_rank = true
	var notation = data.piece_notation
	if has_same_rank:
		notation += Vector2ToTileName(piece.board_position)[0]
	if has_same_file:
		var a = Vector2ToTileName(piece.board_position)
		notation += a.substr(1, a.length() - 1) 
	
	var prize = ""
	if move_type == Globals.Capture: # capturing
		notation += "x"
		if piece_id == Globals.Sheriff:
			forced_prize = pieces[config[1]].piece_type
		prize = on_capture(pieces[config[1]])
	elif move_type == Globals.Projectile: # projectile capturing
		notation += "!"
		prize = on_capture(pieces[config[1]])
		notation += Vector2ToTileName(pos) + prize
		return notation
		
	notation += Vector2ToTileName(pos) + prize
	if move_type == Globals.SpecialCapture: # capturing
		notation += "x"
		prize = on_capture(pieces[config[2]])
		notation += Vector2ToTileName(config[2]) + prize
	var temp_piece = null
	if move_type == Globals.Swap:
		notation += "⇄"
		temp_piece = pieces[pos]
	#actually perform move
	
	var old_pos = piece.board_position
	pieces[pos] = piece
	pieces[old_pos] = null
	
	piece.board_position = pos
	piece.position = pos * square_size + top_left_tile
	
	if move_type == Globals.Swap:
		pieces[old_pos] = temp_piece
		temp_piece.board_position = old_pos
		temp_piece.position = old_pos * square_size + top_left_tile
	
	var can_be_en_passanted := [Globals.Soldier]
	var centurion_count = count_piece(Globals.Centurion, side_turn)
	if piece.has_moved == false and (piece.piece_type <= Globals.Knight or can_be_en_passanted.has(piece.piece_type)) and abs(old_pos.y - pos.y) == 2 + centurion_count:
		piece.en_passant = true
		
	if piece.piece_type < Globals.Knight and ((side_turn == Globals.White and piece.board_position.y == 0) or (side_turn == Globals.Black and piece.board_position.y == 7)):
		piece.piece_type = Globals.Queen
		piece.get_child(0).texture = load("res://Graphics/Pieces/"+Globals.PieceWiki[Globals.Queen].piece_sprite+".png")
		notation += "(Q)"
	elif piece.piece_type == Globals.Soldier and ((side_turn == Globals.White and piece.board_position.y == 0) or (side_turn == Globals.Black and piece.board_position.y == 7)):
		piece.piece_type = Globals.Centurion
		piece.get_child(0).texture = load("res://Graphics/Pieces/"+Globals.PieceWiki[Globals.Centurion].piece_sprite+".png")
		notation += "(C)"
	
	piece.has_moved = true
	
	return notation
	
var win := -1
var game_done := false

func on_capture(piece: Node2D):
	var prizes = 0
	var input_list = []
	var no_prizes := [Globals.Archer, Globals.Angel, Globals.King, Globals.Soldier]
	var double_prizes := [Globals.Queen, Globals.Archbishop, Globals.Bastion]
	if piece.piece_type == Globals.King:
		win = side_turn
	if double_prizes.has(piece.piece_type):
		prizes = 2
	elif piece.piece_type >= Globals.Knight and !no_prizes.has(piece.piece_type):
		prizes = 1
	var end_of_prizes := false
	while prizes > 0:
		var roll = roll_unit()
		if forced_prize > 0:
			roll = forced_prize
		var x = 0
		var found = false
		while x < 5 and not found:
			if bonus[side_turn][x].prize == -1:
				found = true
				bonus[side_turn][x].prize = roll
				input_list.append(Globals.PieceWiki[roll].piece_notation)
				var spr_p = ""
				if roll == Globals.Clock:
					spr_p = str(Globals.directions.find(clocks[side_turn][1])) + str(Globals.directions.find(clocks[side_turn][0]))
				bonus[side_turn][x].piece_node.get_child(0).texture = load("res://Graphics/Pieces/"+Globals.PieceWiki[roll].piece_sprite+spr_p+".png")
				bonus[side_turn][x].piece_node.get_child(0).visible = true
				forced_prize = -1
			x += 1
		#bonus[side_turn].append()
		prizes += -1
	pieces[piece.board_position].queue_free()
	pieces[piece.board_position] = null
	if input_list.size() == 0:
		return ""
	return "{" + array_to_string(input_list) + "}"

func array_to_string(input_array: Array) -> String:
	var result = ""
	for i in range(input_array.size()):
		result += str(input_array[i])
		if i < input_array.size() - 1:
			result += ","
	return result

func roll_unit():
	var options = [
		0, 0, Globals.Knight, Globals.Bishop, Globals.Rook, Globals.Queen,
		Globals.Grasshopper, Globals.Cannon, Globals.Nightrider, Globals.Angel,
		Globals.Bull, Globals.Trebuchet, Globals.Archer, Globals.Ship,
		Globals.Samurai, Globals.Clock, Globals.Sheriff, Globals.Archbishop,
		Globals.Bastion, Globals.Soldier, Globals.Querquisite, Globals.Centurion
	]
	if Globals.who_plays[Globals.White] != "AI" and Globals.who_plays[Globals.Black] != "AI":
		options.append(Globals.Mercenary)
	var pawns = [
		Globals.Messenger, Globals.Guard, Globals.Innkeeper, Globals.Doctor,
		Globals.Weaver, Globals.Clerk, Globals.Blacksmith, Globals.Farmer
	]
	var picked = options[randi() % options.size()]
	if picked == 0:
		picked = pawns[randi() % pawns.size()]
	return picked

func under_attack_by(piece: Node2D):
	var return_array = []
	var moves = []
	for key in pieces.keys():
		if pieces[key] == null:
			continue
		elif pieces[key].side == piece.side:
			continue
		elif pieces[key].piece_type == Globals.Angel:
			continue
		else:
			#print(key)
			moves = get_piece_movement(pieces[key])
			for move in moves:
				if (move[0] == Globals.Capture || move[0] == Globals.Projectile) && move[1] == piece.board_position:
					return_array.append(piece)
				elif move[0] == Globals.SpecialCapture && move[2] == piece.board_position:
					return_array.append(piece)
	return return_array
	
func alt_under_attack(orig_piece: Node2D, pos: Vector2i):
	var ret := []
	var temp = pieces[pos]
	var script = load("res://Code/Piece.gd")
	pieces[orig_piece.board_position] = null
	var side = orig_piece.side
	
	var piece = Node2D.new()
	piece.set_script(script)
	piece.call("initialize", Globals.Dummy, pos, side) 
	pieces[pos] = piece
	ret = under_attack_by(piece)
	pieces[pos].queue_free()
	pieces[pos] = temp
	pieces[orig_piece.board_position] = orig_piece
	
	return ret

func get_side_pieces(side: int):
	var ret := []
	for key in pieces.keys():
		if pieces[key] != null and pieces[key].side == side:
			ret.append(pieces[key])
	return ret
#---------------------------------------
# AI
#---------------------------------------

var attacks_this_turn := []
var ai_picking := false
var best_move = null
var best_score := -INF
const checks_per_frame := 20
var current_checking := -1

func ai_pick_move(side: int, start: int):
	
	var all_moves = attacks_this_turn
	
	for i in range(start, min(all_moves.size(), start+checks_per_frame) ):
		var move_entry = all_moves[i]
		var piece = move_entry["piece"]
		var move = move_entry["move"]
		#if move[0] == Globals.Place:
			#print("After: " + str(move))
		var score = evaluate_move(piece, move)
		#print(Globals.PieceWiki[piece.piece_type].piece_name + " @ " + Vector2ToTileName(piece.board_position) + " " + str(move_entry["move"]) + " " + str(score))
		if score > best_score or (score == best_score and randi_range(0,1) == 0):
			best_score = score
			best_move = move_entry
		start = false

func populate_attacks(side):
	best_move = null
	best_score = -INF
	var pieces2 = get_side_pieces(side)
	var all_moves = []
	for piece in pieces2:
		var moves = get_piece_movement(piece)
		for move in moves:
			all_moves.append({"piece": piece, "move": move})
	
	for a in range(5):
		if bonus[side][a].prize != -1:
			#print("A: " + str(a))
			var moves = get_piece_movement(bonus[side][a].piece_node)
			for move in moves:
				#print("Before: " + str(move))
				all_moves.append({"piece": bonus[side][a].piece_node, "move": move})
	attacks_this_turn = all_moves
	

func evaluate_move(piece: Node2D, move: Array) -> int:
	var movement_type = move[0]
	var after_pos = move[1] if move[0] != Globals.Projectile else piece.board_position
	var capture_pos = null
	
	if movement_type == Globals.Capture or Globals.Projectile:
		capture_pos = move[1]
	elif movement_type == Globals.SpecialCapture:
		capture_pos = move[2]
	var score = 0
	#broken rn, dont wanna implement it
	if movement_type == Globals.Swap:
		score += -INF
	
	# encourage placing piece down
	if movement_type == Globals.Place:
		score += Globals.PieceWiki[move[2]].value
	# encourage capturing
	if capture_pos != null:
		var target_piece = pieces[capture_pos]
		if target_piece != null:
			var piece_value = get_piece_value(target_piece)
			score += piece_value
	# discourage moving into a vulnerable position
	if alt_under_attack(piece, after_pos).size() > 0 and movement_type != Globals.Projectile:
		score -= get_piece_value(piece)
	# discourage randomly moving the king if not needed
	if piece.piece_type == Globals.King and under_attack_by(piece).size() == 0:
		score -= 5
	# discourage moving pawns 1 square if they can move 2
	if piece.piece_type < Globals.Knight and !piece.has_moved and movement_type == Globals.Basic and abs(piece.board_position.y - after_pos.y) < 2:
		score -= 5
	# encourage moving/capturing from a threatened space to an unthreatened space
	if movement_type != Globals.Place and under_attack_by(piece).size() > 0 and alt_under_attack(piece, after_pos).size() == 0:
		score += get_piece_value(piece)
	# variation
	#score += randi_range(-5, 5)
	return score
	
func get_piece_value(piece: Node2D) -> int:
	if piece.piece_type == Globals.King:
		return 999
	return Globals.PieceWiki[piece.piece_type].value
	
func _process(delta):
	if game_done:
		return
	if Globals.who_plays[side_turn] == "Player" && !waiting_for_player:
		advance_turn()
	elif Globals.who_plays[side_turn] == "AI":
		if !ai_picking:
			ai_timer = 40
			current_checking = 0
			populate_attacks(side_turn)
			ai_picking = true
		elif current_checking >= attacks_this_turn.size() and ai_picking and ai_timer == 0:
			ai_picking = false
			var n = perform_move(best_move["piece"], best_move["move"])
			record_turn(n, side_turn)
			advance_turn()
		elif ai_picking and current_checking < attacks_this_turn.size():
			ai_pick_move(side_turn, current_checking)
			current_checking = min(current_checking+checks_per_frame, attacks_this_turn.size()) + 1
	if ai_timer > 0:
		ai_timer += -1

func _back_to_main():
	Globals._back_to_main()
	
func record_turn(texts: String, side: int):
	var move_label_scene = load("res://Prefabs/move_label.tscn") as PackedScene
	var move_label = move_label_scene.instantiate()
	move_label.text = texts
	if side == Globals.White:
		move_history_white.add_child(move_label)
	else:
		move_history_black.add_child(move_label)
	await get_tree().process_frame
	scroll_bar.set_deferred("scroll_vertical", scroll_bar.get_v_scroll_bar().max_value)
