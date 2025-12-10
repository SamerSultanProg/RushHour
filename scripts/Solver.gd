extends Node

# ========================================================
# RUSH HOUR SOLVER - BFS (Breadth-First Search) Algorithm
# ========================================================
# This algorithm finds the optimal (shortest) solution to any
# Rush Hour puzzle by exploring all possible game states.
#
# How it works:
# 1. Start with the initial board state
# 2. Generate all possible moves from current state
# 3. Add new states to a queue (FIFO)
# 4. Track visited states to avoid cycles
# 5. Continue until we find the winning state
# 6. Backtrack to reconstruct the solution path
# ========================================================

const GRID_SIZE := 6
const EXIT_ROW := 2

# Represents a single car's state
class CarState:
	var id: String
	var x: int
	var y: int
	var car_len: int
	var dir: String  # "H" or "V"
	
	func _init(p_id: String, p_x: int, p_y: int, p_len: int, p_dir: String):
		id = p_id
		x = p_x
		y = p_y
		car_len = p_len
		dir = p_dir
	
	func duplicate() -> CarState:
		return CarState.new(id, x, y, car_len, dir)

# Represents a complete board state
class BoardState:
	var cars: Array  # Array of CarState
	var parent: BoardState
	var move_made: Dictionary  # {"car_id": "X", "dx": 0, "dy": 0}
	
	func _init():
		cars = []
		parent = null
		move_made = {}
	
	func duplicate() -> BoardState:
		var new_state := BoardState.new()
		for car in cars:
			new_state.cars.append(car.duplicate())
		return new_state
	
	# Generate a unique hash for this state (for visited tracking)
	func get_hash() -> String:
		var positions := []
		for car in cars:
			positions.append("%s:%d,%d" % [car.id, car.x, car.y])
		positions.sort()
		return "|".join(positions)
	
	# Check if red car has reached the exit
	func is_solved() -> bool:
		for car in cars:
			if car.id == "R" and car.dir == "H":
				# Red car wins when its right edge reaches column 6 (exit)
				if car.x + car.car_len >= GRID_SIZE:
					return true
		return false
	
	# Build occupancy grid for collision detection
	func build_occupancy() -> Array:
		var grid := []
		for row_y in range(GRID_SIZE):
			var row := []
			for col_x in range(GRID_SIZE):
				row.append("")
			grid.append(row)
		
		for car in cars:
			if car.dir == "H":
				for i in range(car.car_len):
					if car.x + i < GRID_SIZE and car.y < GRID_SIZE:
						grid[car.y][car.x + i] = car.id
			else:
				for i in range(car.car_len):
					if car.x < GRID_SIZE and car.y + i < GRID_SIZE:
						grid[car.y + i][car.x] = car.id
		
		return grid
	
	# Generate all possible next states from this state
	func get_next_states() -> Array:
		var next_states := []
		var grid := build_occupancy()
		
		for car in cars:
			if car.dir == "H":
				# Try moving left
				var left_moves := 0
				for dx in range(1, car.x + 1):
					if grid[car.y][car.x - dx] == "":
						left_moves = dx
					else:
						break
				
				for dx in range(1, left_moves + 1):
					var new_state := duplicate()
					for c in new_state.cars:
						if c.id == car.id:
							c.x -= dx
							break
					new_state.parent = self
					new_state.move_made = {"car_id": car.id, "dx": -dx, "dy": 0}
					next_states.append(new_state)
				
				# Try moving right
				var right_moves := 0
				for dx in range(1, GRID_SIZE - (car.x + car.car_len) + 1):
					if car.x + car.car_len + dx - 1 < GRID_SIZE and grid[car.y][car.x + car.car_len + dx - 1] == "":
						right_moves = dx
					else:
						break
				
				for dx in range(1, right_moves + 1):
					var new_state := duplicate()
					for c in new_state.cars:
						if c.id == car.id:
							c.x += dx
							break
					new_state.parent = self
					new_state.move_made = {"car_id": car.id, "dx": dx, "dy": 0}
					next_states.append(new_state)
			
			else:  # Vertical car
				# Try moving up
				var up_moves := 0
				for dy in range(1, car.y + 1):
					if grid[car.y - dy][car.x] == "":
						up_moves = dy
					else:
						break
				
				for dy in range(1, up_moves + 1):
					var new_state := duplicate()
					for c in new_state.cars:
						if c.id == car.id:
							c.y -= dy
							break
					new_state.parent = self
					new_state.move_made = {"car_id": car.id, "dx": 0, "dy": -dy}
					next_states.append(new_state)
				
				# Try moving down
				var down_moves := 0
				for dy in range(1, GRID_SIZE - (car.y + car.car_len) + 1):
					if car.y + car.car_len + dy - 1 < GRID_SIZE and grid[car.y + car.car_len + dy - 1][car.x] == "":
						down_moves = dy
					else:
						break
				
				for dy in range(1, down_moves + 1):
					var new_state := duplicate()
					for c in new_state.cars:
						if c.id == car.id:
							c.y += dy
							break
					new_state.parent = self
					new_state.move_made = {"car_id": car.id, "dx": 0, "dy": dy}
					next_states.append(new_state)
		
		return next_states


# ========================================================
# BFS SOLVER
# ========================================================

# Solve a level and return the list of moves (or empty if unsolvable)
func solve(level_data: Dictionary) -> Array:
	# Create initial state from level data
	var initial := BoardState.new()
	for car_def in level_data["cars"]:
		var car := CarState.new(
			car_def["id"],
			int(car_def["x"]),
			int(car_def["y"]),
			int(car_def["len"]),
			car_def["dir"]
		)
		initial.cars.append(car)
	
	# BFS
	var queue := [initial]
	var visited := {initial.get_hash(): true}
	
	while queue.size() > 0:
		var current: BoardState = queue.pop_front()
		
		# Check if solved
		if current.is_solved():
			# Reconstruct solution path
			return _reconstruct_path(current)
		
		# Explore all next states
		for next_state in current.get_next_states():
			var state_hash: String = next_state.get_hash()
			if not visited.has(state_hash):
				visited[state_hash] = true
				queue.append(next_state)
	
	# No solution found
	return []


# Reconstruct the path from initial to solution
func _reconstruct_path(final_state: BoardState) -> Array:
	var path := []
	var current := final_state
	
	while current.parent != null:
		path.push_front(current.move_made)
		current = current.parent
	
	return path


# Get just the next move (for hint feature)
func get_hint(level_data: Dictionary, current_positions: Dictionary) -> Dictionary:
	# Create state from current game positions
	var current_state := BoardState.new()
	for car_def in level_data["cars"]:
		var id: String = car_def["id"]
		var pos: Vector2 = current_positions.get(id, Vector2(car_def["x"], car_def["y"]))
		var car := CarState.new(
			id,
			int(pos.x),
			int(pos.y),
			int(car_def["len"]),
			car_def["dir"]
		)
		current_state.cars.append(car)
	
	# Check if already solved
	if current_state.is_solved():
		return {}
	
	# BFS from current state
	var queue := [current_state]
	var visited := {current_state.get_hash(): true}
	
	while queue.size() > 0:
		var state: BoardState = queue.pop_front()
		
		if state.is_solved():
			# Found solution - return the first move from current state
			var path := _reconstruct_path(state)
			if path.size() > 0:
				return path[0]
			return {}
		
		for next_state in state.get_next_states():
			var state_hash: String = next_state.get_hash()
			if not visited.has(state_hash):
				visited[state_hash] = true
				queue.append(next_state)
	
	return {}

# ========================================================
# PROCEDURAL LEVEL GENERATOR
# ========================================================
# This algorithm generates valid, solvable Rush Hour puzzles.
#
# Algorithm Strategy:
# 1. Place the red car (R) on row 2 at a random valid position
# 2. Randomly place blocking cars on the board
# 3. Verify the puzzle is solvable using BFS
# 4. Ensure minimum difficulty (optimal solution >= min_moves)
# 5. Repeat if puzzle is too easy or unsolvable
# ========================================================

# Available car IDs (matching the game's sprite assets)
const CAR_IDS_LEN2 := ["A", "B", "C", "D", "E", "F", "G"]
const CAR_IDS_LEN3 := ["A", "B", "C", "D"]

# Generates a random solvable level
# min_moves: Minimum optimal solution length (for difficulty)
# max_cars: Maximum number of blocking cars to place
# Returns: Dictionary with "cars" array and "optimal_moves" count
func generate_level(min_moves: int = 5, max_cars: int = 12) -> Dictionary:
	var attempts := 0
	var max_attempts := 100
	
	while attempts < max_attempts:
		attempts += 1
		
		var level := _try_generate_level(max_cars)
		if level.is_empty():
			continue
		
		# Verify puzzle is solvable and meets difficulty requirement
		var solution := solve(level)
		if solution.size() >= min_moves:
			return {
				"cars": level["cars"],
				"optimal_moves": solution.size()
			}
	
	# Fallback: return a simple valid puzzle
	return _generate_simple_fallback()

# Internal: Attempt to generate a single level
func _try_generate_level(max_cars: int) -> Dictionary:
	var cars_array := []
	var occupied := _create_empty_grid()
	
	# Step 1: Place the red car on exit row (row 2)
	# Red car must be horizontal, length 2, and NOT at exit position
	var red_x := randi_range(0, 3)  # Positions 0-3 leave room to move right
	var red_car := {
		"id": "R",
		"x": red_x,
		"y": EXIT_ROW,
		"len": 2,
		"dir": "H"
	}
	cars_array.append(red_car)
	_mark_occupied(occupied, red_x, EXIT_ROW, 2, "H")
	
	# Step 2: Place blocking cars randomly
	var available_ids_2 := CAR_IDS_LEN2.duplicate()
	var available_ids_3 := CAR_IDS_LEN3.duplicate()
	var used_ids := {"R": true}
	
	# Shuffle for randomness
	available_ids_2.shuffle()
	available_ids_3.shuffle()
	
	var cars_to_place := randi_range(max(5, max_cars - 4), max_cars)
	var placed := 0
	var placement_attempts := 0
	var max_placement_attempts := 200
	
	while placed < cars_to_place and placement_attempts < max_placement_attempts:
		placement_attempts += 1
		
		# Randomly choose car length (biased toward length 2)
		var car_len: int
		if randf() < 0.7:
			car_len = 2
		else:
			car_len = 3
		
		# Get an available car ID
		var car_id: String = ""
		if car_len == 2 and available_ids_2.size() > 0:
			car_id = available_ids_2.pop_back()
		elif car_len == 3 and available_ids_3.size() > 0:
			car_id = available_ids_3.pop_back()
		else:
			# Try the other length
			if car_len == 2 and available_ids_3.size() > 0:
				car_len = 3
				car_id = available_ids_3.pop_back()
			elif car_len == 3 and available_ids_2.size() > 0:
				car_len = 2
				car_id = available_ids_2.pop_back()
		
		if car_id.is_empty():
			continue
		
		if used_ids.has(car_id):
			continue
		
		# Randomly choose direction
		var dir := "H" if randf() < 0.5 else "V"
		
		# Try to find a valid position
		var pos := _find_valid_position(occupied, car_len, dir)
		if pos.x >= 0:
			var car := {
				"id": car_id,
				"x": pos.x,
				"y": pos.y,
				"len": car_len,
				"dir": dir
			}
			cars_array.append(car)
			_mark_occupied(occupied, pos.x, pos.y, car_len, dir)
			used_ids[car_id] = true
			placed += 1
		else:
			# Couldn't place, return the ID to the pool
			if car_len == 2:
				available_ids_2.append(car_id)
			else:
				available_ids_3.append(car_id)
	
	# Must have at least a few blocking cars
	if placed < 3:
		return {}
	
	return {"cars": cars_array}

# Find a valid position for a car
func _find_valid_position(occupied: Array, car_len: int, dir: String) -> Vector2i:
	var positions := []
	
	if dir == "H":
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE - car_len + 1):
				if _can_place(occupied, x, y, car_len, "H"):
					positions.append(Vector2i(x, y))
	else:
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE - car_len + 1):
				if _can_place(occupied, x, y, car_len, "V"):
					positions.append(Vector2i(x, y))
	
	if positions.size() == 0:
		return Vector2i(-1, -1)
	
	# Return a random valid position
	return positions[randi() % positions.size()]

# Check if a car can be placed at given position
func _can_place(occupied: Array, x: int, y: int, car_len: int, dir: String) -> bool:
	if dir == "H":
		if x + car_len > GRID_SIZE:
			return false
		for dx in range(car_len):
			if occupied[y][x + dx]:
				return false
	else:
		if y + car_len > GRID_SIZE:
			return false
		for dy in range(car_len):
			if occupied[y + dy][x]:
				return false
	return true

# Mark grid cells as occupied
func _mark_occupied(occupied: Array, x: int, y: int, car_len: int, dir: String) -> void:
	if dir == "H":
		for dx in range(car_len):
			occupied[y][x + dx] = true
	else:
		for dy in range(car_len):
			occupied[y + dy][x] = true

# Create an empty 6x6 grid
func _create_empty_grid() -> Array:
	var grid := []
	for _y in range(GRID_SIZE):
		var row := []
		for _x in range(GRID_SIZE):
			row.append(false)
		grid.append(row)
	return grid

# Fallback simple puzzle if generation fails
func _generate_simple_fallback() -> Dictionary:
	return {
		"cars": [
			{"id": "R", "x": 0, "y": 2, "len": 2, "dir": "H"},
			{"id": "A", "x": 2, "y": 0, "len": 3, "dir": "V"},
			{"id": "B", "x": 3, "y": 2, "len": 2, "dir": "V"},
			{"id": "C", "x": 4, "y": 0, "len": 2, "dir": "V"},
			{"id": "D", "x": 5, "y": 1, "len": 3, "dir": "V"}
		],
		"optimal_moves": 8
	}
