extends Node2D


enum {
	FLOOR1 = 0,
	FLOOR2 = 1,
	HOLE = 5,
	GOAL = 8,
}

const CELL_WIDTH = 64
const MAZE_WIDTH = 12
const MAZE_HEIGHT = 10
const MAZE_SIZE = MAZE_WIDTH * MAZE_HEIGHT

var qlTable = []

var QValueLabel = load("res://QValueLabel.tscn")

func xyToIX(x, y): return x + y * MAZE_WIDTH

func _ready():
	qlTable.resize(MAZE_SIZE)
	for y in range(MAZE_HEIGHT):
		var txt = ""
		for x in range(MAZE_WIDTH):
			if $TileMap.get_cell(x, y) <= FLOOR2:
				var label = QValueLabel.instance()
				label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH)
				qlTable[xyToIX(x, y)] = label
				add_child(label)
			txt += String($TileMap.get_cell(x, y))
			txt += " "
		print(txt)
	pass
