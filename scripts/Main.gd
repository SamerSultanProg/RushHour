extends Control

# ----------------- Board constants -----------------
const GRID_SIZE : int = 6      # 6x6 board
const CELL      : int = 96     # pixel size of one cell
const PADDING   : int = 24     # screen margin (global pos of the board only)
const LINE_PX   : int = 1      # grid line thickness (visual)

# ----------------- Runtime state -------------------
var board_rect : ColorRect                  # the board background (Control/ColorRect)
var cars : Dictionary = {}                  # id -> TextureRect (visual car)
var car_defs : Dictionary = {}              # id -> {x,y,len,dir} (logical state)
var occ : Array = []                        # occupancy[y][x] = id or null

# ----------------- SOLVABLE LEVEL ------------------
# Red ("R") at row 2 must reach the right; this layout is solvable
# without any initial overlaps.
var level := {
	"cars": [
		{"id":"R","x":1,"y":2,"len":2,"dir":"H"},  # target car

		{"id":"A","x":0,"y":0,"len":2,"dir":"H"},  # top-left H2
		{"id":"F","x":2,"y":0,"len":2,"dir":"H"},  # top middle H2
		{"id":"B","x":4,"y":0,"len":3,"dir":"V"},  # right-top V3 (will move down later)
		{"id":"C","x":3,"y":2,"len":3,"dir":"V"},  # center V3 (move down after freeing bottom-right)
		{"id":"D","x":0,"y":3,"len":3,"dir":"V"},  # left V3
		{"id":"E","x":2,"y":5,"len":2,"dir":"H"},  # bottom H2 (can slide left to free C)
		{"id":"G","x":5,"y":3,"len":2,"dir":"V"}   # far-right V2 (doesn't block the exit row)
	]
}

func _ready() -> void:
	_build_board()

	# Validate the level definition BEFORE we spawn anything
	if not _validate_level(level):
		push_error("Level has overlapping or out-of-bounds cars. Fix the 'level' dictionary.")
		return

	_spawn_cars()
	_rebuild_occupancy()

# ===================================================
# Board creation (cars, grid lines and exit all use
# the SAME coordinate space: board-local pixels)
# ===================================================
func _build_board() -> void:
	board_rect = ColorRect.new()
	board_rect.color = Color(0,0,0,0)                     # transparent; background is a texture child
	board_rect.position = Vector2(PADDING, 120)
	board_rect.size     = Vector2(CELL * GRID_SIZE, CELL * GRID_SIZE)
	add_child(board_rect)

	# >>> Road background image
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(Image.load_from_file("res://assets/board/board_bg.png"))
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.anchor_left = 0; bg.anchor_top = 0; bg.anchor_right = 0; bg.anchor_bottom = 0
	bg.position = Vector2(0, 0)                           # board-local
	bg.size     = board_rect.size                         # fill the board
	board_rect.add_child(bg)

	# (Remove this block if your background already draws the exit)
	var exit_rect := ColorRect.new()
	exit_rect.color = Color.from_string("#4caf50", Color(0,1,0))
	exit_rect.position = Vector2(board_rect.size.x, CELL * 2 + 16)
	exit_rect.size = Vector2(10, CELL - 32)
	board_rect.add_child(exit_rect)

# ===================================================
# Level validation (no overlaps, inside bounds)
# ===================================================
func _validate_level(L:Dictionary) -> bool:
	# build a temporary occupancy to check all cars
	var tmp : Array = []
	for _y in range(GRID_SIZE):
		var row : Array = []
		for _x in range(GRID_SIZE):
			row.append(null)
		tmp.append(row)

	for cd in L["cars"]:
		var id : String = cd["id"]
		var x  : int = int(cd["x"])
		var y  : int = int(cd["y"])
		var l  : int = int(cd["len"])
		var dir: String = cd["dir"]

		if dir == "H":
			# bounds
			if x < 0 or x + l - 1 >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
				return false
			# overlap
			for dx in range(l):
				if tmp[y][x + dx] != null:
					return false
				tmp[y][x + dx] = id
		else:
			if y < 0 or y + l - 1 >= GRID_SIZE or x < 0 or x >= GRID_SIZE:
				return false
			for dy in range(l):
				if tmp[y + dy][x] != null:
					return false
				tmp[y + dy][x] = id

	return true

# ===================================================
# Spawn cars (TextureRect) and set up drag handlers
# ===================================================
func _spawn_cars() -> void:
	cars.clear()
	car_defs.clear()

	for cd in level["cars"]:
		var id : String = cd["id"]
		car_defs[id] = cd.duplicate(true)

		var dir : String = cd["dir"]
		var path : String = "res://assets/cars/%s_%s.png" % [id, dir]
		var tex := ImageTexture.create_from_image(Image.load_from_file(path))

		var car := TextureRect.new()
		car.name = id
		car.texture = tex
		car.stretch_mode = TextureRect.STRETCH_SCALE
		car.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		car.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		car.anchor_left = 0; car.anchor_top = 0
		car.anchor_right = 0; car.anchor_bottom = 0

		var w_cells : int = int(cd["len"]) if dir == "H" else 1
		var h_cells : int = int(cd["len"]) if dir == "V" else 1
		car.custom_minimum_size = Vector2(w_cells * CELL, h_cells * CELL)
		car.size = car.custom_minimum_size

		car.position = _grid_to_px(Vector2i(int(cd["x"]), int(cd["y"]))).floor()
		board_rect.add_child(car)
		cars[id] = car

		# --- axis-locked drag, live clamp, bump on block, snap on release ---
		car.gui_input.connect(func (event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					var off : Vector2 = car.get_local_mouse_position()
					car.set_meta("drag_offset", off)
					car.set_meta("dragging", true)
				else:
					car.set_meta("dragging", false)
					_snap_to_grid_with_collisions(car)
			elif event is InputEventMouseMotion:
				if car.get_meta("dragging", false):
					var off2 : Vector2 = car.get_meta("drag_offset")
					var desired_local : Vector2 = car.get_parent().get_local_mouse_position() - off2

					var id2 : String = car.name
					var d  : Dictionary = car_defs[id2]
					var dir_str : String = d["dir"]

					var bounds : Dictionary = _get_move_bounds(id2)  # {"min":..,"max":..} in GRID CELLS

					if dir_str == "H":
						var min_px : float = float(bounds["min"] * CELL)
						var max_px : float = float(bounds["max"] * CELL)
						var clamped_x : float = clamp(desired_local.x, min_px, max_px)
						car.position.x = floor(clamped_x)
						if desired_local.x < min_px - 0.5: _bump(car, "x", -1)
						elif desired_local.x > max_px + 0.5: _bump(car, "x", +1)
					else:
						var min_py : float = float(bounds["min"] * CELL)
						var max_py : float = float(bounds["max"] * CELL)
						var clamped_y : float = clamp(desired_local.y, min_py, max_py)
						car.position.y = floor(clamped_y)
						if desired_local.y < min_py - 0.5: _bump(car, "y", -1)
						elif desired_local.y > max_py + 0.5: _bump(car, "y", +1)
		)

# ===================================================
# Occupancy grid (for collisions)
# ===================================================
func _rebuild_occupancy(except_id:String = "") -> void:
	occ = []
	for _y in range(GRID_SIZE):
		var row : Array = []
		for _x in range(GRID_SIZE):
			row.append(null)
		occ.append(row)

	for id in cars.keys():
		if id == except_id:
			continue
		var d : Dictionary = car_defs[id]
		var x : int = int(d["x"])
		var y : int = int(d["y"])
		var l : int = int(d["len"])
		if d["dir"] == "H":
			for dx in range(l):
				occ[y][x + dx] = id
		else:
			for dy in range(l):
				occ[y + dy][x] = id

# ===================================================
# Snap to nearest cell and validate collisions
# ===================================================
func _snap_to_grid_with_collisions(car: Control) -> void:
	var id : String = car.name
	var def : Dictionary = car_defs[id]
	var dir : String = def["dir"]

	var pos_px : Vector2 = car.position
	var grid : Vector2i = Vector2i(int(round(pos_px.x / CELL)), int(round(pos_px.y / CELL)))

	var new_x : int = int(def["x"])
	var new_y : int = int(def["y"])
	var length : int = int(def["len"])

	if dir == "H":
		new_x = clampi(grid.x, 0, GRID_SIZE - length)
	else:
		new_y = clampi(grid.y, 0, GRID_SIZE - length)

	_rebuild_occupancy(id)

	var blocked := false
	if dir == "H":
		for dx in range(length):
			if _cell_occ(new_x + dx, new_y):
				blocked = true
				break
	else:
		for dy in range(length):
			if _cell_occ(new_x, new_y + dy):
				blocked = true
				break

	if blocked:
		car.position = _grid_to_px(Vector2i(int(def["x"]), int(def["y"]))).floor()
	else:
		def["x"] = new_x
		def["y"] = new_y
		car.position = _grid_to_px(Vector2i(new_x, new_y)).floor()
		_rebuild_occupancy("")

# ---------------------------------------------------
# Helpers: occupancy checks, coords, live-bounds, bump
# ---------------------------------------------------
func _cell_occ(x:int, y:int) -> bool:
	if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
		return true
	return occ[y][x] != null

func _grid_to_px(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL, cell.y * CELL)

# Legal movement range (in GRID CELLS) along the car axis, excluding itself
func _get_move_bounds(id:String) -> Dictionary:
	var d : Dictionary = car_defs[id]
	var x : int = int(d["x"])
	var y : int = int(d["y"])
	var l : int = int(d["len"])

	_rebuild_occupancy(id)  # ignore this car while scanning

	if d["dir"] == "H":
		var left : int = x
		while left - 1 >= 0 and not _cell_occ(left - 1, y):
			left -= 1
		var right : int = x
		while right + l <= GRID_SIZE - 1 and not _cell_occ(right + l, y):
			right += 1
		return {"min": left, "max": right}
	else:
		var up : int = y
		while up - 1 >= 0 and not _cell_occ(x, up - 1):
			up -= 1
		var down : int = y
		while down + l <= GRID_SIZE - 1 and not _cell_occ(x, down + l):
			down += 1
		return {"min": up, "max": down}

# Tiny vibration when pushing into a car/wall
# axis = "x" or "y", dir = -1 or +1
func _bump(car: Control, axis:String, dir:int) -> void:
	if car.get_meta("bumping", false):
		return
	car.set_meta("bumping", true)

	var t := create_tween()
	var amt := 6.0 * dir
	if axis == "x":
		t.tween_property(car, "position:x", car.position.x + amt, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(car, "position:x", car.position.x, 0.06)
	else:
		t.tween_property(car, "position:y", car.position.y + amt, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(car, "position:y", car.position.y, 0.06)
	t.finished.connect(func(): car.set_meta("bumping", false))
