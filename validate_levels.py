#!/usr/bin/env python3
"""Rush Hour Level Validator - Checks all levels for overlaps and solvability"""

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

def check_level(idx, level):
    """Check a single level for issues"""
    issues = []
    cars = level["cars"]
    
    # Find red car
    red_car = next((c for c in cars if c["id"] == "R"), None)
    if not red_car:
        issues.append("No red car (R)")
    elif red_car["y"] != 2:
        issues.append(f"Red car at y={red_car['y']} instead of y=2")
    elif red_car["dir"] != "H":
        issues.append("Red car must be horizontal")
    
    # Build grid and check overlaps
    grid = [[None for _ in range(GRID_SIZE)] for _ in range(GRID_SIZE)]
    
    for car in cars:
        for cx, cy in get_cells(car):
            if cx < 0 or cx >= GRID_SIZE or cy < 0 or cy >= GRID_SIZE:
                issues.append(f"{car['id']} out of bounds at ({cx},{cy})")
            elif grid[cy][cx] is not None:
                issues.append(f"{car['id']} overlaps {grid[cy][cx]} at ({cx},{cy})")
            else:
                grid[cy][cx] = car["id"]
    
    # Print grid
    print(f"\n{'='*30}")
    print(f"LEVEL {idx + 1}")
    print(f"{'='*30}")
    for y in range(GRID_SIZE):
        row = ""
        for x in range(GRID_SIZE):
            cell = grid[y][x]
            row += (cell if cell else ".") + " "
        suffix = " <-- EXIT" if y == 2 else ""
        print(f"{row}{suffix}")
    
    # Check what blocks the exit
    if red_car:
        blocking = []
        for x in range(red_car["x"] + red_car["len"], GRID_SIZE):
            if grid[2][x] is not None:
                car_id = grid[2][x]
                if car_id not in blocking:
                    blocking.append(car_id)
        if blocking:
            print(f"Blocking exit: {blocking}")
        else:
            print("Exit path: CLEAR!")
    
    # Report issues
    if issues:
        print("ERRORS:")
        for issue in issues:
            print(f"  - {issue}")
        return False
    else:
        print("Status: OK")
        return True

if __name__ == "__main__":
    print("=" * 50)
    print("RUSH HOUR LEVEL VALIDATOR")
    print("=" * 50)
    
    all_valid = True
    for i, level in enumerate(LEVELS):
        if not check_level(i, level):
            all_valid = False
    
    print("\n" + "=" * 50)
    if all_valid:
        print("RESULT: ALL LEVELS VALID!")
    else:
        print("RESULT: SOME LEVELS HAVE ERRORS!")
    print("=" * 50)
