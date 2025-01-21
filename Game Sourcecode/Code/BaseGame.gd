extends Node

@export var board_tiles: Vector2i = Vector2(8, 8)
var screen_size: Vector2i = Vector2i(1152, 648) #DisplayServer.window_get_size()
@export var square_size: int = 75

@onready var top_left_tile: Vector2i = $Game/Chessboard.position

@export var pieces: Dictionary = {
	Vector2i(99,99): null
}
var current_piece_clicked: Node2D = null # current piece being clicked whose movement options are being shown
var movement_icons: Array = []
var move_icons: Dictionary = {}

var move_history: Array = []

var turn: int = Globals.White
var max_players = 2

var clocks = {
	Globals.White: [Vector2i(0, -1), Vector2i(0, -1)],
	Globals.Black: [Vector2i(1, 1), Vector2i(1, 1)]
}

var button = {}

var waiting_for_player := true
var ai_timer := 0

var side_turn := Globals.White

var forced_prize = -1

func _ready() -> void:
	update_piece_info(Globals.Pawn)
	for row in range(8):
		for column in range(8):
			pieces[Vector2i(column, row)] = null
			move_icons[Vector2i(column, row)] = []
			# draws the tile
			var tile_scene = load("res://Prefabs/tile.tscn") as PackedScene
			var tile = tile_scene.instantiate()
			tile.get_child(0).connect("pressed", Callable(self, "on_tile_pressed").bind(column, row))
			var col = $"Game/Chessboard".get_child(column)
			tile.set_color(Globals.square_colors[(row + column) % 2])
			col.add_child(tile)
			var b = tile.get_child(0) as Button
			#b.text = str(column) + ", " + str(row)
			button[Vector2i(column, row)] = b
	await get_tree().process_frame
	top_left_tile = $Game/Chessboard.global_position
	create_init_pieces()
	set_advantage_bar()

@onready var turn_display: RichTextLabel = $"Turn Display"	
@onready var move_history_: GridContainer = $"Move History/Scroll Bar/GridContainer"
@onready var move_history_black: VBoxContainer = $"Move History/Scroll Bar/GridContainer/BlackList"
@onready var scroll_bar: ScrollContainer = $"Move History/Scroll Bar"
@onready var advantage_bar: ProgressBar = $"AdvantageBar"
@onready var piece_info: RichTextLabel = $"PieceInformation/Scroll Bar/RichTextLabel"

var killed_last_turn = {
	Globals.White: {},
	Globals.Black: {}
}

var last_moved_piece = {
	Globals.White: 0,
	Globals.Black: 0
}

func advance_turn():
	set_advantage_bar()
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
	# clear killed last turn
	if side_turn == Globals.White:
		killed_last_turn[Globals.Black] = {}
	else:
		killed_last_turn[Globals.White] = {}
	# update pieces
	for key in pieces.keys():
		if pieces[key] != null:
			pieces[key].update_piece(side_turn, get_piece_sprite(pieces[key].piece_type, pieces[key].side))
	
	var prize_benches = [$"Game/White Prize Bench", $"Game/Black Prize Bench"]
	var x = 0
	for bench in prize_benches:
		var y = 0
		for benched in bench.get_children():
			if benched.piece_node != null:
				benched.piece_node.update_piece(side_turn, get_piece_sprite(benched.piece_node.piece_type, benched.piece_node.side), true)
				benched.icon = get_piece_sprite(benched.piece_node.piece_type, benched.piece_node.side)
			else:
				print("Bench Number: "+str(x)+" Item Number: "+str(y))
			y += 1
		x += 1
	if win != -1:
		game_done = true
		
func calculate_positions(start, end, count):
	var step = (end - start) / (count - 1)  # Divide into 4 gaps for 5 boxes
	
	var positions = []
	for i in range(count):
		var position = start + (step * i)
		positions.append(position)
	return positions

func get_prize_bench(side: int) -> VBoxContainer:
	var prize_bench = null
	
	if side == Globals.White:
		prize_bench = $"Game/White Prize Bench"
	else:
		prize_bench = $"Game/Black Prize Bench"
	return prize_bench

func create_prize_button(prize: int, side:int) -> bool:
	var prize_bench = get_prize_bench(side)
		
	if prize_bench.get_child_count() >= 5:
		return false
	
	var prize_scene = load("res://Prefabs/prize_button.tscn") as PackedScene
	var prize_button = prize_scene.instantiate()

	prize_button.prize = prize
	pieces[Vector2i(99,99)] = null
	print("Prize ID: "+str(prize))
	var new_piece = create_piece(Vector2i(99,99), prize, side)
	prize_button.piece_node = new_piece
	prize_button.icon = get_piece_sprite(prize, side)
	
	add_side_shader(prize_button, side)
	
	prize_button.connect("pressed", Callable(self, "on_prize_button_pressed").bind(prize_button))
	
	prize_bench.add_child(prize_button)
	if prize_button.piece_node == null:
		print("Created Button with Null")
	return true

func add_side_shader(object, side):
	var shared_material = load("res://Graphics/PieceShaderMaterial.tres")
	object.material = shared_material.duplicate()
	var shader_material = object.material as ShaderMaterial
	if side == Globals.Black:
		shader_material.set("shader_param/new_color", Color(0.36, 0.36, 0.36, 1.0))
	elif side == Globals.White:
		shader_material.set("shader_param/new_color", Color(1.0, 1.0, 1.0, 1.0))

func create_piece(board_position: Vector2i, piece_id: int, side: int) -> Node2D:
	if !pieces.has(board_position):
		return null
	if pieces[board_position] != null:
		return null
		
	var piece_scene = load("res://Prefabs/piece.tscn") as PackedScene
	var piece = piece_scene.instantiate()
	
	piece.call("initialize", piece_id, board_position, side) 
	
	var sprite = piece.get_child(0)
	sprite.texture = get_piece_sprite(piece_id, side)
	var flip = [Globals.Crab, Globals.Archer]
	
	if piece_id in flip and side == Globals.Black:
		sprite.flip_v = true
	
	add_side_shader(sprite, side)

	piece.position = board_position * square_size + top_left_tile
	self.add_child(piece)
	pieces[board_position] = piece
	
	return piece
	
func get_piece_sprite(piece_id, side):
	var data = Globals.PieceWiki[piece_id]
	var spr_p = ""
	if piece_id == Globals.Clock:
		spr_p = str(Globals.directions.find(clocks[side][1])) + str(Globals.directions.find(clocks[side][0]))
	return load("res://Graphics/Pieces/"+data.piece_sprite+spr_p+".png")

func create_init_pieces():
	for piece in Globals.base_pieces:
		var _new_piece = create_piece(piece[0], piece[1], piece[2])

func Vector2ToTileName(board_position: Vector2i) -> String:
	var char = String.chr("a".unicode_at(0) + board_position.x)
	return char + str(board_tiles.y - board_position.y)


func on_tile_pressed(x: int, y: int):
	#print("Button clicked at "+str(x)+","+str(y))
	var moves = ["Dropmarker", "Basic", "Capture", "Shoot", "SpecialMove", "Swap"]
	var pos = Vector2i(x,y)
	if move_icons[pos] != []:
		# if a move is to be performed here
		var n = perform_move(current_piece_clicked, move_icons[pos])
		record_turn(n, side_turn)
		waiting_for_player = false
	elif pieces[pos] == null:
		clear_icons()
	elif pieces[pos].side != side_turn or (pieces[pos].side == side_turn and Globals.who_plays[side_turn] != "Player") or win != -1:
		clear_icons()
		update_piece_info(pieces[pos].piece_type)
		# put smth here that opens data on the new piece
	elif pieces[pos] == current_piece_clicked:
		update_piece_info(pieces[pos].piece_type)
		clear_icons()
		current_piece_clicked = null
	elif pieces[pos].side == side_turn:
		update_piece_info(pieces[pos].piece_type)
		var piece = pieces[pos]
		var piece_options := get_piece_movement(piece)
		clear_icons()
		current_piece_clicked = piece
		for option in piece_options:
			var tile_button: Button = button[Vector2i(option[1].x, option[1].y)]
			tile_button.icon = load("res://Graphics/Icons/"+moves[option[0]+1]+".png")
			move_icons[option[1]] = option

func on_prize_button_pressed(pb):
	if pb.piece_node.side != side_turn or (pb.piece_node.side == side_turn and Globals.who_plays[side_turn] != "Player") or win != -1: 
		clear_icons()
		current_piece_clicked = null
		update_piece_info(pb.piece_node.piece_type)
	elif pb.piece_node == current_piece_clicked:
		clear_icons()
		current_piece_clicked = null
	else:
		update_piece_info(pb.piece_node.piece_type)
		var piece = pb.piece_node
		var piece_options := get_piece_movement(piece, pb.get_index())
		if piece_options.size() > 0:
			clear_icons()
			current_piece_clicked = piece
		for option in piece_options:
			var tile_button: Button = button[Vector2i(option[1].x, option[1].y)]
			tile_button.icon = load("res://Graphics/Icons/Dropmarker.png")
			move_icons[option[1]] = option

func count_piece(piece_id: int, side: int):
	var n = 0
	for key in pieces.keys():
		if pieces[key] != null:
			if pieces[key].piece_type == piece_id and pieces[key].side == side:
				n += 1
	return n

func get_piece_movement(piece: Node2D, prize_index: int = -1)-> Array:
	var piece_id = piece.piece_type
	var move := []
	if prize_index > -1:
		var file = 0
		if side_turn == Globals.White:
			file = 5
		for key in pieces.keys():
			if pieces[key] == null and key.y >= file and key.y <= file + 2:
				move.append([Globals.Place, key, prize_index])
		return move
	match piece_id:
		Globals.Pawn, Globals.Messenger, Globals.Guard, Globals.Innkeeper, Globals.Doctor, Globals.Weaver, Globals.Clerk, Globals.Blacksmith, Globals.Farmer:
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
		Globals.Queen:
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
			move = Globals.grasshopper_movement(pieces, piece.board_position, piece.side)
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
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, true, 1, false) + Globals.rook_movement(pieces, piece.board_position, piece.side, 99, true, 1, false) + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false, 1, true) + Globals.bishop_movement(pieces, piece.board_position, piece.side, 1, false, 1, true)
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
		Globals.Ranger:
			var cannon = Globals.rook_movement(pieces, piece.board_position, piece.side, 2, true, 2, true) + Globals.bishop_movement(pieces, piece.board_position, piece.side, 1, true, 1, true)
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
					if Globals.exists(pieces, piece.board_position + Vector2i(a, b)) and !Globals.occupied(pieces, piece.board_position + Vector2i(a, b)):
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
		Globals.Crab:
			var values = [Vector2i(-1, -2),Vector2i(1, -2),Vector2i(-2, 1),Vector2i(2, 1)]
			if piece.side == Globals.Black:
				values = [Vector2i(-1, 2),Vector2i(1, 2),Vector2i(-2, -1),Vector2i(2, -1)]
			for val in values:
				var pos = val + piece.board_position
				if pieces.has(pos):
					if pieces[pos] == null:
						move.append([Globals.Basic, pos])
					elif Globals.occupied_by_foe(pieces, pos, piece.side):
						move.append([Globals.Capture, pos])
		Globals.Priest:
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 2, false, 1, true)
		Globals.Rookie:
			move = Globals.rook_movement(pieces, piece.board_position, piece.side, 2, false, 1, true)
		Globals.Bomb:
			move = Globals.bishop_movement(pieces, piece.board_position, piece.side, 1, false, 1,false) + Globals.rook_movement(pieces, piece.board_position, piece.side, 1, false , 1, false)
			for d in Globals.directions:
				var pos = d + piece.board_position
				if pieces.has(pos) and Globals.occupied(pieces, pos):
					var m = [Globals.SpecialCapture, pos, piece.board_position]
					for e in Globals.directions:
						if pieces.has(piece.board_position + e) and Globals.occupied(pieces, piece.board_position + e):
							m.append(piece.board_position + e)
					move.append(m)
		Globals.Damsel:
			var queen = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true) + Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			for q in queen:
				if alt_under_attack(piece, q[1]).size() > 0:
					move.append(q)
		Globals.Paladin:
			move = Globals.horse_movement(pieces, piece.board_position, piece.side, false, [3,1])
		Globals.Mercenary:
			for key in pieces.keys():
				if pieces[key] == null and key != Vector2i(99,99):
					move.append([Globals.Basic, key])
		Globals.Healer:
			var q = Globals.bishop_movement(pieces, piece.board_position, piece.side, 99, false, 1, true) + Globals.rook_movement(pieces, piece.board_position, piece.side, 99, false, 1, true)
			for m in q:
				if (m[0] == Globals.Capture and killed_last_turn[side_turn].has(m[1])):
					move.append(m)
				elif m[0] == Globals.Basic:
					move.append(m)
		Globals.Jester:
			piece.piece_type = get_last_side_piece(piece.side)
			move = get_piece_movement(piece)
			piece.piece_type = Globals.Jester
			return move
		_:
			print("Tried to get movement for null piece id #"+str(piece_id))
	move = move + Globals.trebuchet_movement_extension(pieces, piece.board_position, piece.side)
	var final_return := {}
	for m in move:
		final_return[m] = true
	return final_return.keys() as Array
	
func get_last_side_piece(side):
	var l = last_moved_piece[Globals.White]
	if side == Globals.White:
		l = last_moved_piece[Globals.Black]
	if l == Globals.Jester:
		return Globals.King
	return l

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
	for key in move_icons.keys():
		var tile_button: Button = button[key]
		tile_button.icon = null
		move_icons[key] = []
	
func perform_move(piece, config):
	clear_icons()
	
	last_moved_piece[side_turn] = piece.piece_type
	if piece.piece_type == Globals.Jester:
		if side_turn == Globals.White:
			last_moved_piece[side_turn] = last_moved_piece[Globals.Black]
		else:
			last_moved_piece[side_turn] = last_moved_piece[Globals.White]
	
	var pos = config[1]
	var move_type = config[0]
	
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
		#if piece_id == Globals.Sheriff:
		#	forced_prize = pieces[config[1]].piece_type
		prize = on_capture(pieces[config[1]])
	elif move_type == Globals.Projectile: # projectile capturing
		notation += "!"
		prize = on_capture(pieces[config[1]])
		notation += Vector2ToTileName(pos) + prize
		return notation
	
	if move_type == Globals.Place:
		notation += "@"
		var prize_bench = get_prize_bench(side_turn)
		var button = prize_bench.get_child(config[2])
		button.queue_free()
	notation += Vector2ToTileName(pos) + prize
	if move_type == Globals.SpecialCapture: # capturing
		for cap in range(2,config.size()):
			notation += "x"
			prize = on_capture(pieces[config[cap]])
			notation += Vector2ToTileName(config[cap]) + prize
	var temp_piece = null
	if move_type == Globals.Swap:
		notation += "⇄"
		temp_piece = pieces[pos]
	#actually perform move
	
	var old_pos = piece.board_position
	pieces[pos] = piece
	pieces[old_pos] = null
	
	if killed_last_turn[side_turn].has(pos) and (piece.piece_type == Globals.Healer or (piece.piece_type == Globals.Jester and get_last_side_piece(piece.side) == Globals.Healer) ):
		create_prize_button(killed_last_turn[side_turn][pos], side_turn)
		notation += "+{" + Globals.PieceWiki[killed_last_turn[side_turn][pos]].piece_notation + "}"
	
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
		
	if promotion(piece.piece_type) != -1 and ((side_turn == Globals.White and piece.board_position.y == 0) or (side_turn == Globals.Black and piece.board_position.y == 7)):
		var pro = promotion(piece.piece_type)
		piece.piece_type =  pro
		piece.get_child(0).texture = get_piece_sprite(pro, side_turn)
		piece.get_child(0).flip_v = false
		notation += "("+ Globals.PieceWiki[pro].piece_notation +")"
	
	piece.has_moved = true
	
	return notation

func promotion(piece_id: int):
	var promos = {
		Globals.Pawn: Globals.Queen,
		Globals.Archer: Globals.Ranger,
		Globals.Priest: Globals.Bishop,
		Globals.Rookie: Globals.Rook,
		Globals.Soldier: Globals.Centurion
	}
	if promos.has(piece_id):
		return promos[piece_id]
	return -1

var win := -1
var game_done := false

func on_capture(piece: Node2D):
	var prizes = 0
	var input_list = []
	var no_prizes := [Globals.Archer, Globals.Angel, Globals.King, Globals.Soldier, Globals.Rookie, Globals.Priest]
	var double_prizes := [Globals.Queen, Globals.Archbishop, Globals.Bastion]
	if piece.piece_type == Globals.King:
		win = side_turn
	if double_prizes.has(piece.piece_type):
		prizes = 2
	elif piece.piece_type >= Globals.Knight and !no_prizes.has(piece.piece_type):
		prizes = 1
	while prizes > 0:
		var roll = roll_unit()
		if forced_prize > 0:
			roll = forced_prize
		var made_button = create_prize_button(roll, side_turn)
		if made_button:
			input_list.append(Globals.PieceWiki[roll].piece_notation)
		prizes += -1
	# deleting piece
	killed_last_turn[piece.side][piece.board_position] = piece.piece_type
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
		0, Globals.Knight, Globals.Bishop, Globals.Rook, Globals.Queen,
		Globals.Grasshopper, Globals.Cannon, Globals.Nightrider, Globals.Angel,
		Globals.Bull, Globals.Trebuchet, Globals.Archer, Globals.Ship,
		Globals.Samurai, Globals.Clock, Globals.Ranger, Globals.Archbishop,
		Globals.Bastion, Globals.Soldier, Globals.Querquisite, Globals.Centurion,
		Globals.Crab, Globals.Priest, Globals.Rookie, Globals.Damsel, Globals.Bomb,
		Globals.Paladin, Globals.Healer, Globals.Jester, Globals.Mercenary
	]
	#if Globals.who_plays[Globals.White] != "AI" and Globals.who_plays[Globals.Black] != "AI":
	#	options.append()
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
				elif move[0] == Globals.SpecialCapture:
					for a in range(2,move.size()):
						if move[a] == piece.board_position:
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
	piece.call("initialize", Globals.Pawn, pos, side) 
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
	
	var prize_bench = get_prize_bench(side)
	for index in prize_bench.get_child_count():
		var moves = get_piece_movement(prize_bench.get_child(index).piece_node, index)
		for move in moves:
			all_moves.append({"piece": prize_bench.get_child(index).piece_node, "move": move})
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
			if side_turn == target_piece.side:
				score -= piece_value
			else:
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
	move_history_.add_child(move_label)
	await get_tree().process_frame
	scroll_bar.set_deferred("scroll_vertical", scroll_bar.get_v_scroll_bar().max_value)

func set_advantage_bar():
	var score = {
		Globals.White: 0,
		Globals.Black: 0
	}
	for key in pieces.keys():
		if pieces[key] != null:
			score[pieces[key].side] += Globals.PieceWiki[pieces[key].piece_type].value
	advantage_bar.max_value = score[Globals.Black] + score[Globals.White]
	advantage_bar.value = score[Globals.White]

func update_piece_info(piece: int):
	var s = Globals.PieceWiki[piece].piece_info
	piece_info.text = s
