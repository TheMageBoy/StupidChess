extends Node

# Sides
const Duck: int = 0
const White: int = 1
const Black: int = 2
const Win_State: int = 999

# Square Colors
const square_colors = [Color(0.2, 0.2, 0.2), Color(0.8, 0.8, 0.8)]

# Piece IDs

const Dummy: 			int = 0
const Pawn: 			int = 0

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
const Ranger:	 		int = 28
const Windmill:			int = 29
const Archbishop:		int = 30
const Bastion:			int = 31
const Soldier: 			int = 32
const Centurion:		int = 33
const Crab:				int = 34
const Priest:			int = 35
const Rookie:			int = 36
const Horseman:			int = 37
const Damsel:			int = 38
const Paladin:			int = 39
const Healer:			int = 40

# Movement Types
const Place: int = -1 # places down a piece onto the board from hand
const Basic: int = 0
const Capture: int = 1
const Projectile: int = 2 # capture the foe without movement
const SpecialCapture: int = 3 # kills foe and moves but different spaces
const Swap: int = 4
#ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀꜱᴛᴜᴠᴡxʏᴢ₁₂₃₄₅₆₇₈
var PieceWiki: Array = [
	PieceData.new().create("Pawn", "Pawn", "", 1,"[center][img=50]Graphics/Pieces/Pawn.png[/img]Pawn[/center]\n\n[b]Notation:[/b] None\n[b]Prize Tier:[/b] 0\n\nThe Pawn moves 1 step away from its side of the board, or 2 on its first movement. It cannot capture forward, instead it captures diagonally forward.\n\nIt may capture a pawn to the left or right of it digonally forawrd in its direction if they have just done their first long move. This is called \"en passant\".\n\nPawns promote Queens upon reaching the furthest tile on the other side of the board."),
	PieceData.new().create("Messenger", "Pawn", "₁", 1, ""),
	PieceData.new().create("Guard", "Pawn", "₂", 1, ""),
	PieceData.new().create("Innkeeper", "Pawn", "₃", 1, ""),
	PieceData.new().create("Doctor", "Pawn", "₄", 1, ""),
	PieceData.new().create("Weaver", "Pawn", "₅", 1, ""),
	PieceData.new().create("Clerk", "Pawn", "₆", 1, ""),
	PieceData.new().create("Blacksmith", "Pawn", "₇", 1, ""),
	PieceData.new().create("Farmer", "Pawn", "₈", 1, ""),
	PieceData.new().create("Knight", "", "N", 3, "[center][img=50]Graphics/Pieces/Knight.png[/img]Knight[/center]\n\n[b]Notation:[/b] N\n[b]Prize Tier:[/b] 1\n\nThe Knight can move or capture to any tile 2 squares away orthogonally and 1 square perpendicular to that. The knight ignores any pieces inbetween, allowing it to jump over pieces."),
	PieceData.new().create("Bishop", "", "B", 3, "[center][img=50]Graphics/Pieces/Bishop.png[/img]Bishop[/center]\n\n[b]Notation:[/b] B\n[b]Prize Tier:[/b] 1\n\nThe Bishop can move or capture to any reachable diagonal tile."),
	PieceData.new().create("Rook", "", "R", 5, "[center][img=50]Graphics/Pieces/Rook.png[/img]Rook[/center]\n\n[b]Notation:[/b] R\n[b]Prize Tier:[/b] 1\n\nThe Rook can move or capture to any reachable orthogonal tile.\n\nCannot Castle."),
	PieceData.new().create("Queen", "", "Q", 9, "[center][img=50]Graphics/Pieces/Queen.png[/img]Queen[/center]\n\n[b]Notation:[/b] Q\n[b]Prize Tier:[/b] 2\n\nThe Queen can move or capture to any reachable diagonal or orthogonal tile."),
	PieceData.new().create("King", "", "K", 0, "[center][img=50]Graphics/Pieces/King.png[/img]King[/center]\n\n[b]Notation:[/b] K\n[b]Prize Tier:[/b] 1\n\nThe King can move or capture to any reachable adjacent tile."),
	PieceData.new().create("Grasshopper", "", "G", 3, "[center][img=50]Graphics/Pieces/Grasshopper.png[/img]Grasshopper[/center]\n\n[b]Notation:[/b] Q\n[b]Prize Tier:[/b] 1\n\nThe Grasshopper can move like a Queen with the addition of jumping over any number of pieces but needs a piece adjacent to it on row/column/diagonal."),
	PieceData.new().create("Cannon", "", "Cɴ", 2, "[center][img=50]Graphics/Pieces/Cannon.png[/img]Cannon[/center]\n\n[b]Notation:[/b] Cɴ\n[b]Prize Tier:[/b] 1\n\nThe Cannon can move like a King.\n\nThe Cannon cannot capture. Instead it can Shoot targets 2-3 Diagonal tiles away."),
	PieceData.new().create("Jester", "", "J", 2, "[center][img=50]Graphics/Pieces/Jester.png[/img]Jester[/center]\n\n[b]Notation:[/b] J\n[b]Prize Tier:[/b] 1\n\nThe Jester moves like the last piece moved or placed by your opponent."),
	PieceData.new().create("Angel", "", "A", 4, "[center][img=50]Graphics/Pieces/Angel.png[/img]Angel[/center]\n\n[b]Notation:[/b] A\n[b]Prize Tier:[/b] 0\n\nThe Angel can teleport to any empty threatened square or swap places with any allied piece. Swaps are denoted by the ⇄ symbol."),
	PieceData.new().create("Nightrider", "", "N₂", 6, "[center][img=50]Graphics/Pieces/Nightrider.png[/img]Nightrider[/center]\n\n[b]Notation:[/b] N₂\n[b]Prize Tier:[/b] 1\n\nThe Nightrider can move or capture similarly to a Knight, however can continue to another square with the same L-shape configuration. This continues until there is a piece on its landing tile."),
	PieceData.new().create("Bull", "", "Bʟ", 5, "[center][img=50]Graphics/Pieces/Bull.png[/img]Bull[/center]\n\n[b]Notation:[/b] Bʟ\n[b]Prize Tier:[/b] 1\n\nThe Bull can move or capture with the combined powers of the Queen and the Knight, however, it can only perform capturing moves. If there are no pieces to capture, it moves like a King."),
	PieceData.new().create("Archer", "", "ᴀ", 2, "[center][img=50]Graphics/Pieces/Archer.png[/img]Archer[/center]\n\n[b]Notation:[/b] ᴀ\n[b]Prize Tier:[/b] 0\n\nThe Archer can move, but not capture orthogonally 1 space.\n\nIt can Shoot in diamond formation, hitting 2 squres orthogonally or 1 square diagonally away.\n\nArchers promote Bishops upon reaching the furthest tile on the other side of the board."),
	PieceData.new().create("Bomb", "", "X", 2, "[center][img=50]Graphics/Pieces/Bomb.png[/img]Bomb[/center]\n\n[b]Notation:[/b] X\n[b]Prize Tier:[/b] 1\n\nThe Bomb can move like a King. when capturing a piece, it captures all pieces adjacent to its original position, and destroys itself. Destroying allied pieces will not yield prize pieces.\n\nIf it is captured, it does NOT explode."),
	PieceData.new().create("Trebuchet", "", "T", 3, "[center][img=50]Graphics/Pieces/Trebuchet.png[/img]Trebuchet[/center]\n\n[b]Notation:[/b] T\n[b]Prize Tier:[/b] 1\n\nThe Trebuchet can move, but not capture orthogonally 1 space.\n\nThe Trebuchet grants movement to all adjacent pieces in the direction opposite to their position relative to it, allowing them to move in that direction until they encounter an obstacle. For example, a Pawn to the southwest of the Trebuchet will gain movement along the northeast diagonal."),
	PieceData.new().create("Samurai", "", "侍", 4, "[center][img=50]Graphics/Pieces/Samurai.png[/img]Samurai[/center]\n\n[b]Notation:[/b] 侍\n[b]Prize Tier:[/b] 1\n\nThe Samurai can move like a Queen with the addition of jumping over any number of pieces but can only capture adjacent pieces."),
	PieceData.new().create("Ship", "", "S", 2, "[center][img=50]Graphics/Pieces/Ship.png[/img]Ship[/center]\n\n[b]Notation:[/b] S\n[b]Prize Tier:[/b] 1\n\nThe Ship can move diagonally 1 tile, and then any number of spaces up or down depending on if the diagonal was upward or downward."),
	PieceData.new().create("Querquisite", "", "?", 4, "[center][img=50]Graphics/Pieces/Querquisite.png[/img]Querquisite[/center]\n\n[b]Notation:[/b] ?\n[b]Prize Tier:[/b] 1\n\nThe Querquisite moves as the pieces of the file it is currently standing on:\n(a/h) Rook\n(b/g) Knight\n(c/f) Bishop\n(d) Queen\n(e) King"),
	PieceData.new().create("Clocktower", "Clocktower/", "Cᴛ", 5, "[center][img=50]Graphics/Pieces/Clocktower/20.png[/img]Clocktower[/center]\n\n[b]Notation:[/b] Cᴛ\n[b]Prize Tier:[/b] 1\n\nAt the start of the game, each player's Clock's minute and hour hands are poiting pirectly away from their side of the board. On the player's respective turns, the minute hand  turn 45 degrees clockwise. If it returns to its position of pointing away from its side, the hour hand will also rotate 45 degrees\n\nThe Clocktower can move and catpture in the direction the minute hard is pointing, for 3 squares and is able to jump over any number of pieces. It may also move and capture any number of square towards where the hour hand is pointing."),
	PieceData.new().create("Duck", "", "D", 4, "[center][img=50]Graphics/Pieces/Duck.png[/img]Duck[/center]\n\n[b]Notation:[/b] D\n[b]Prize Tier:[/b] 1\n\nThe Duck can move to any unoccupied tile on the board, and may be moved by either player."),
	PieceData.new().create("Ranger", "", "Aʀ", 4, "[center][img=50]Graphics/Pieces/Ranger.png[/img]Ranger[/center]\n\n[b]Notation:[/b] Aʀ\n[b]Prize Tier:[/b] 1\n\nThe Ranger moves like a Knight. It can Shoot in diamond formation, hitting 2 squres orthogonally or 1 square diagonally away."),
	PieceData.new().create("Windmill", "", "W", 1, ""),
	PieceData.new().create("Archbishop", "", "B₂", 9, "[center][img=50]Graphics/Pieces/Archbishop.png[/img]Archbishop[/center]\n\n[b]Notation:[/b] B₂\n[b]Prize Tier:[/b] 2\n\nThe Archbishop can move like a Bishop, but in addition, may turn perpedicular to its trajectory after its first step."),
	PieceData.new().create("Bastion", "", "R₂", 9, "[center][img=50]Graphics/Pieces/Bastion.png[/img]Bastion[/center]\n\n[b]Notation:[/b] R₂\n[b]Prize Tier:[/b] 2\n\nThe Bastion can move like a Rook, but in addition, may turn perpedicular to its trajectory after its first step vertically."),
	PieceData.new().create("Soldier", "", "ꜱ", 1, "[center][img=50]Graphics/Pieces/Soldier.png[/img]Soldier[/center]\n\n[b]Notation:[/b] ꜱ\n[b]Prize Tier:[/b] 0\n\nThe Soldier is similar to a pawn, it moves forward away from its side by 1, and 2 on its first movements. Unlike the pawn, it captures forward.\n\nSoldiers have their own en passant, where they capture forward a passing Pawn or Soldier. If there is a regular piece that can be captured there instead, en passant is ignored. Soldiers may be captured by en passant.\n\nSoldiers promote Centurions upon reaching the furthest tile on the other side of the board."),
	PieceData.new().create("Centurion", "", "C", 4, "[center][img=50]Graphics/Pieces/Centurion.png[/img]Centurion[/center]\n\n[b]Notation:[/b] C\n[b]Prize Tier:[/b] 1\n\nThe Centurion can move like a King.\n\nIt has the additional passive ability to make pawns and soldiers be able to move 1 additional space. This is stackable with multiple centurions. A Pawn moving 2 spaces under the influence of 1 Centurion cannot be captured by en passant, but if it is moving 3 spaces (on its first move) it can be."),
	PieceData.new().create("Crab", "", "ᴄ", 1, "[center][img=50]Graphics/Pieces/Crab.png[/img]Crab[/center]\n\n[b]Notation:[/b] ᴄ\n[b]Prize Tier:[/b] 0\n\nThe Crab moves like a Knight, but only the 2 closer tiles in the direction away from its side, and only the 2 apart tiles in the direction towards its side."),
	PieceData.new().create("Priest", "", "ʙ", 2, "[center][img=50]Graphics/Pieces/Priest.png[/img]Priest[/center]\n\n[b]Notation:[/b] ʙ\n[b]Prize Tier:[/b] 0\n\nThe Priest moves like a Bishop but only 2 tiles.\n\nPriests promote Bishops upon reaching the furthest tile on the other side of the board."),
	PieceData.new().create("Rookie", "", "ʀ", 3, "[center][img=50]Graphics/Pieces/Rookie.png[/img]Rookie[/center]\n\n[b]Notation:[/b] ʀ\n[b]Prize Tier:[/b] 0\n\nThe Rookie moves like a Rook but only 2 tiles.\n\nRookies promote Rooks upon reaching the furthest tile on the other side of the board."),
	PieceData.new().create("Horseman", "", "ɴ", 3, ""),
	PieceData.new().create("Damsel", "", "ǫ", 2, "[center][img=50]Graphics/Pieces/Damsel.png[/img]Damsel[/center]\n\n[b]Notation:[/b] ǫ\n[b]Prize Tier:[/b] 0\n\nThe Damsel moves like a Queen, but only to tiles where it would be in danger.\n\nDamsels promote Queens upon reaching the furthest tile on the other side of the board."),
	PieceData.new().create("Paladin", "", "P", 3, "[center][img=50]Graphics/Pieces/Paladin.png[/img]Paladin[/center]\n\n[b]Notation:[/b] P\n[b]Prize Tier:[/b] 1\n\nThe Knight can move or capture to any tile 2 squares away diagonally and 1 square perpendicular to that.\n\nThis turned out to be exactly like a 3/1 Knight."),
	PieceData.new().create("Healer", "", "H", 7, "[center][img=50]Graphics/Pieces/Healer.png[/img]Healer[/center]\n\n[b]Notation:[/b] ǫ\n[b]Prize Tier:[/b] 1\n\nThe Healer moves like the Queen but cannot capture, except to tiles where an ally was captured last turn.\n\nWhen moving or capturing to a tile where an ally was captured last turn, re-add that piece to your hand."),
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
	
	#[Vector2i(1,5), Globals.Jester, Globals.White],
	[Vector2i(0,6), Globals.Pawn, Globals.White],
	[Vector2i(1,6), Globals.Pawn, Globals.White],
	[Vector2i(2,6), Globals.Pawn, Globals.White],
	[Vector2i(3,6), Globals.Pawn, Globals.White],
	[Vector2i(4,6), Globals.Pawn, Globals.White],
	[Vector2i(5,6), Globals.Pawn, Globals.White],
	[Vector2i(6,6), Globals.Pawn, Globals.White],
	[Vector2i(7,6), Globals.Pawn, Globals.White],
	
	[Vector2i(0,7), Globals.Rook, Globals.White],
	[Vector2i(1,7), Globals.Knight, Globals.White],
	[Vector2i(2,7), Globals.Bishop, Globals.White],
	[Vector2i(3,7), Globals.Queen, Globals.White],
	[Vector2i(4,7), Globals.King, Globals.White],
	[Vector2i(5,7), Globals.Bishop, Globals.White],
	[Vector2i(6,7), Globals.Knight, Globals.White],
	[Vector2i(7,7), Globals.Rook, Globals.White],
	
	[Vector2i(0,1), Globals.Pawn, Globals.Black],
	[Vector2i(1,1), Globals.Pawn, Globals.Black],
	[Vector2i(2,1), Globals.Pawn, Globals.Black],
	[Vector2i(3,1), Globals.Pawn, Globals.Black],
	[Vector2i(4,1), Globals.Pawn, Globals.Black],
	[Vector2i(5,1), Globals.Pawn, Globals.Black],
	[Vector2i(6,1), Globals.Pawn, Globals.Black],
	[Vector2i(7,1), Globals.Pawn, Globals.Black],
	
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
	get_tree().change_scene_to_file("res://Scenes/Game2.tscn")

func _on_pvp_pressed() -> void:
	who_plays[White] = "Player"
	who_plays[Black] = "Player"
	get_tree().change_scene_to_file("res://Scenes/Game2.tscn")

func _back_to_main() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main Menu.tscn")
