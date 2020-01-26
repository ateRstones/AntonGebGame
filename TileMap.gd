extends TileMap

var AIR = -1
enum {STONE_0, STONE_1, STONE_2, BUTTON_OFF, BUTTON_ON, LOGIC_OFF, LOGIC_ON, WOOD_0, WOOD_1, WATER, GRASS_0, GRASS_1,
		AND_OFF_0, AND_OFF_1, AND_ON_2, OR_OFF_0, OR_ON_1, OR_ON_2, XOR_OFF_0, XOR_ON_1, XOR_OFF_2, DOOR_CLOSED, DOOR_OPEN_BOTTOM, DOOR_OPEN_TOP, DOOR_OPEN_MIDDLE, DIRT}
var STONE = [STONE_0, STONE_1, STONE_2]
var WOOD = [WOOD_0, WOOD_1]
var GRASS = [GRASS_0, GRASS_1]
var AND = [AND_OFF_0, AND_OFF_1, AND_ON_2]
var OR = [OR_OFF_0, OR_ON_1, OR_ON_2]
var XOR = [XOR_OFF_0, XOR_ON_1, XOR_OFF_2]
var GATE = AND + OR + XOR
var ON_LOGIC = [BUTTON_ON, LOGIC_ON, XOR_ON_1, OR_ON_1, OR_ON_2, AND_ON_2]
var OFF_LOGIC = [BUTTON_OFF, LOGIC_OFF, XOR_OFF_0, XOR_OFF_2, OR_OFF_0, AND_OFF_0, AND_OFF_1]
var DOOR_OPEN = [DOOR_OPEN_BOTTOM, DOOR_OPEN_TOP, DOOR_OPEN_MIDDLE]
var DOOR = [DOOR_CLOSED] + DOOR_OPEN
var DOOR_NO_BORDER = DOOR + [AIR]

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var toUpdate = []
var triggeredUpdates = []
var entityUpdate = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for pos in get_used_cells_by_id(BUTTON_OFF):
		entityUpdate.append(pos)
	for pos in get_used_cells_by_id(LOGIC_ON):
		toUpdate.append(pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	var entityInfos = []
	
	var player = $"../Entities/Player"
	var playerPos = player.position * 0.5
	playerPos.y += 8
	playerPos = world_to_map(playerPos)
	entityInfos.append([player, playerPos])
	
	var entities = $"../Entities/Cubes".get_children()
	for entity in entities:
		var entPos = entity.position * 0.5
		entPos.y += 6
		entPos = world_to_map(entPos)
		entityInfos.append([entity, entPos])
		
	for pos in entityUpdate:
		entityUpdateTile(pos, entityInfos)
	
	for pos in toUpdate:
		updateNeighbors(pos)
	
	var queuedUpdates = [] + triggeredUpdates
	triggeredUpdates = []
	
	for update in queuedUpdates:
		updateTile(update[0], update[1])
	
	toUpdate = []

func entityUpdateTile(pos, entityInfos):
	var cell = get_cellv(pos)
	
	var on = false
	
	for info in entityInfos:
		if info[1] == pos:
			on = true
			break
	
	if on and cell == BUTTON_OFF:
		set_cellv(pos, BUTTON_ON)
		queueTileUpdate(pos)
	
	if (not on) and cell == BUTTON_ON:
		set_cellv(pos, BUTTON_OFF)
		queueTileUpdate(pos)	

func queueTileUpdate(pos: Vector2):
	toUpdate.append(pos)

func updateTile(pos: Vector2, updating: Vector2):
	var cell = get_cellv(pos)
	var updatingCell = get_cellv(updating)
	if cell == LOGIC_OFF:
		if updatingCell in ON_LOGIC:
			set_cellv(pos, LOGIC_ON)
			updateNeighbors(pos)
	
	if cell == LOGIC_ON:
		if updatingCell in OFF_LOGIC:
			set_cellv(pos, LOGIC_OFF)
			updateNeighbors(pos)
	
	if cell in GATE:
		var updateTo = cell
		var flip = false
		var leftOn = get_cell(pos.x - 1, pos.y) == LOGIC_ON
		var rightOn = get_cell(pos.x + 1, pos.y) == LOGIC_ON
		
		var base = -1
		
		if cell in AND:
			base = AND_OFF_0
		elif cell in OR:
			base = OR_OFF_0
		elif cell in XOR:
			base = XOR_OFF_0
		
		if leftOn and rightOn:
			updateTo = base + 2
		elif leftOn:
			updateTo = base + 1
			updateUnderneath(pos)
		elif rightOn:
			updateTo = base + 1
			flip = true
		else:
			updateTo = base
		
		set_cellv(pos, updateTo, flip)
		
		if cell != updateTo:
			updateUnderneath(pos)
	
	if cell in DOOR:
		var updateTo = cell
		if updatingCell in ON_LOGIC or updatingCell in DOOR_OPEN:
			if not get_cell(pos.x, pos.y + 1) in DOOR_NO_BORDER:
				updateTo = DOOR_OPEN_BOTTOM
			elif not get_cell(pos.x, pos.y - 1) in DOOR_NO_BORDER:
				updateTo = DOOR_OPEN_TOP
			else:
				updateTo = DOOR_OPEN_MIDDLE
		if updatingCell in OFF_LOGIC or updatingCell == DOOR_CLOSED:
			updateTo = DOOR_CLOSED
		
		if cell != updateTo:
			set_cellv(pos, updateTo)
			updateNeighbors(pos)
	

func updateTileSafe(pos: Vector2, updating: Vector2):
	#if not pos in updatedTiles:
	#	if not get_cellv(pos) in GATE:
	#		updatedTiles.append(pos)
	#	updateTile(pos, updating)
	triggeredUpdates.append([pos, updating])

func updateUnderneath(pos: Vector2):
	updateTileSafe(Vector2(pos.x + 0, pos.y + 1), pos)

func updateNeighbors(pos: Vector2):
	updateTileSafe(Vector2(pos.x + 0, pos.y + 1), pos)
	updateTileSafe(Vector2(pos.x + 1, pos.y + 0), pos)
	updateTileSafe(Vector2(pos.x + 0, pos.y - 1), pos)
	updateTileSafe(Vector2(pos.x - 1, pos.y + 0), pos)