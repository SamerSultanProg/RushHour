#!/usr/bin/env python3
"""Rush Hour Level Solver - Uses BFS to verify all levels are solvable"""
from collections import deque

GRID_SIZE = 6

LEVELS = [
    {"cars": [{"id":"R","x":0,"y":2,"len":2,"dir":"H"},{"id":"A","x":2,"y":0,"len":2,"dir":"V"},{"id":"B","x":3,"y":2,"len":3,"dir":"V"},{"id":"C","x":4,"y":0,"len":2,"dir":"V"}]},
    {"cars": [{"id":"R","x":0,"y":2,"len":2,"dir":"H"},{"id":"A","x":1,"y":1,"len":3,"dir":"H"},{"id":"B","x":2,"y":3,"len":3,"dir":"V"},{"id":"C","x":0,"y":3,"len":3,"dir":"V"},{"id":"D","x":5,"y":3,"len":3,"dir":"V"},{"id":"E","x":5,"y":1,"len":2,"dir":"V"}]},
    {"cars": [{"id":"R","x":1,"y":2,"len":2,"dir":"H"},{"id":"A","x":0,"y":2,"len":2,"dir":"V"},{"id":"B","x":2,"y":4,"len":2,"dir":"V"},{"id":"C","x":4,"y":2,"len":2,"dir":"V"},{"id":"D","x":5,"y":1,"len":3,"dir":"V"}]},
    {"cars": [{"id":"R","x":0,"y":2,"len":2,"dir":"H"},{"id":"A","x":3,"y":1,"len":3,"dir":"V"},{"id":"B","x":0,"y":4,"len":3,"dir":"H"},{"id":"C","x":2,"y":5,"len":3,"dir":"H"},{"id":"D","x":5,"y":1,"len":2,"dir":"V"},{"id":"E","x":1,"y":0,"len":2,"dir":"H"}]},
    {"cars": [{"id":"R","x":0,"y":2,"len":2,"dir":"H"},{"id":"A","x":4,"y":4,"len":2,"dir":"H"},{"id":"B","x":3,"y":0,"len":2,"dir":"H"},{"id":"C","x":5,"y":1,"len":3,"dir":"V"},{"id":"D","x":1,"y":4,"len":3,"dir":"H"},{"id":"E","x":4,"y":2,"len":2,"dir":"V"}]},
    {"cars": [{"id":"R","x":1,"y":2,"len":2,"dir":"H"},{"id":"A","x":3,"y":3,"len":3,"dir":"V"},{"id":"B","x":0,"y":5,"len":3,"dir":"H"},{"id":"C","x":4,"y":0,"len":3,"dir":"V"},{"id":"D","x":4,"y":4,"len":2,"dir":"H"},{"id":"E","x":0,"y":1,"len":2,"dir":"V"},{"id":"G","x":1,"y":0,"len":2,"dir":"V"}]},
    {"cars": [{"id":"R","x":0,"y":2,"len":2,"dir":"H"},{"id":"A","x":5,"y":0,"len":2,"dir":"V"},{"id":"B","x":0,"y":0,"len":2,"dir":"H"},{"id":"C","x":3,"y":2,"len":3,"dir":"V"},{"id":"D","x":2,"y":1,"len":2,"dir":"V"},{"id":"E","x":2,"y":0,"len":2,"dir":"H"},{"id":"F","x":0,"y":3,"len":2,"dir":"V"},{"id":"G","x":1,"y":5,"len":2,"dir":"H"}]},
    {"cars": [{"id":"R","x":0,"y":2,"len":2,"dir":"H"},{"id":"A","x":0,"y":1,"len":2,"dir":"H"},{"id":"B","x":3,"y":0,"len":3,"dir":"V"},{"id":"C","x":4,"y":3,"len":2,"dir":"V"},{"id":"D","x":0,"y":3,"len":3,"dir":"H"},{"id":"E","x":0,"y":0,"len":2,"dir":"H"},{"id":"F","x":0,"y":4,"len":2,"dir":"V"},{"id":"G","x":4,"y":0,"len":2,"dir":"H"}]},
    {"cars": [{"id":"R","x":2,"y":2,"len":2,"dir":"H"},{"id":"A","x":4,"y":4,"len":2,"dir":"H"},{"id":"B","x":2,"y":3,"len":3,"dir":"V"},{"id":"C","x":0,"y":5,"len":2,"dir":"H"},{"id":"D","x":4,"y":1,"len":3,"dir":"V"},{"id":"E","x":5,"y":1,"len":2,"dir":"V"},{"id":"F","x":3,"y":0,"len":2,"dir":"H"}]},
    {"cars": [{"id":"R","x":0,"y":2,"len":2,"dir":"H"},{"id":"A","x":0,"y":5,"len":2,"dir":"H"},{"id":"B","x":2,"y":1,"len":2,"dir":"V"},{"id":"C","x":1,"y":4,"len":3,"dir":"H"},{"id":"D","x":4,"y":3,"len":2,"dir":"H"},{"id":"E","x":5,"y":0,"len":2,"dir":"V"},{"id":"F","x":0,"y":3,"len":2,"dir":"V"},{"id":"G","x":1,"y":0,"len":2,"dir":"H"}]}
]

def state_to_tuple(cars_state):
    """Convert car state to a hashable tuple for visited set"""
    return tuple(sorted((c["id"], c["x"], c["y"]) for c in cars_state))

def get_cells(car):
    """Get all cells occupied by a car"""
    cells = []
    x, y, length, direction = car["x"], car["y"], car["len"], car["dir"]
    if direction == "H":
        for dx in range(length):
            cells.append((x + dx, y))
    else:
        for dy in range(length):
            cells.append((x, y + dy))
    return cells

def build_grid(cars_state):
    """Build occupancy grid from car state"""
    grid = [[None for _ in range(GRID_SIZE)] for _ in range(GRID_SIZE)]
    for car in cars_state:
        for cx, cy in get_cells(car):
            if 0 <= cx < GRID_SIZE and 0 <= cy < GRID_SIZE:
                grid[cy][cx] = car["id"]
    return grid

def is_won(cars_state):
    """Check if red car has reached the exit (x + len == 6)"""
    for car in cars_state:
        if car["id"] == "R":
            return car["x"] + car["len"] == GRID_SIZE
    return False

def get_moves(cars_state):
    """Generate all possible moves from current state"""
    grid = build_grid(cars_state)
    moves = []
    
    for i, car in enumerate(cars_state):
        car_id = car["id"]
        x, y = car["x"], car["y"]
        length = car["len"]
        direction = car["dir"]
        
        if direction == "H":
            # Try moving left
            if x > 0 and grid[y][x - 1] is None:
                new_cars = [c.copy() for c in cars_state]
                new_cars[i]["x"] = x - 1
                moves.append(new_cars)
            
            # Try moving right
            if x + length < GRID_SIZE and grid[y][x + length] is None:
                new_cars = [c.copy() for c in cars_state]
                new_cars[i]["x"] = x + 1
                moves.append(new_cars)
        else:  # Vertical
            # Try moving up
            if y > 0 and grid[y - 1][x] is None:
                new_cars = [c.copy() for c in cars_state]
                new_cars[i]["y"] = y - 1
                moves.append(new_cars)
            
            # Try moving down
            if y + length < GRID_SIZE and grid[y + length][x] is None:
                new_cars = [c.copy() for c in cars_state]
                new_cars[i]["y"] = y + 1
                moves.append(new_cars)
    
    return moves

def solve_level(level_data):
    """BFS solver - returns (is_solvable, min_moves) or (False, -1)"""
    initial = [c.copy() for c in level_data["cars"]]
    
    if is_won(initial):
        return True, 0
    
    visited = set()
    queue = deque([(initial, 0)])
    visited.add(state_to_tuple(initial))
    
    while queue:
        state, depth = queue.popleft()
        
        for next_state in get_moves(state):
            state_tuple = state_to_tuple(next_state)
            
            if state_tuple in visited:
                continue
            
            visited.add(state_tuple)
            
            if is_won(next_state):
                return True, depth + 1
            
            queue.append((next_state, depth + 1))
    
    return False, -1

def main():
    print("=" * 50)
    print("RUSH HOUR LEVEL SOLVER (BFS)")
    print("=" * 50)
    
    all_solvable = True
    
    for i, level in enumerate(LEVELS):
        print(f"\nLevel {i + 1}: ", end="", flush=True)
        solvable, moves = solve_level(level)
        
        if solvable:
            print(f"SOLVABLE in {moves} moves")
        else:
            print(f"NOT SOLVABLE!")
            all_solvable = False
    
    print("\n" + "=" * 50)
    if all_solvable:
        print("RESULT: ALL LEVELS ARE SOLVABLE!")
    else:
        print("RESULT: SOME LEVELS ARE NOT SOLVABLE!")
    print("=" * 50)

if __name__ == "__main__":
    main()
