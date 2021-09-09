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
const START_X = 1
const START_Y = 1
const START_POS = Vector2(START_X, START_Y)

var started = false
var playerPos = START_POS
var nSteps = 0				# ステップ数
var qvalue = []				# Q値リスト
var qlTable = []			# Q値最大値表示用ラベル


var rng = RandomNumberGenerator.new()

var QValueLabel = load("res://QValueLabel.tscn")

func xyToIX(x, y): return x + y * MAZE_WIDTH
func canMoveTo(ix : int):
	var x = ix % MAZE_WIDTH
	var y = ix / MAZE_WIDTH
	var c = $TileMap.get_cell(x, y)
	return c < FLOOR2 || c == GOAL || c == HOLE
func moveTo(to : int):
	playerPos.x = to % MAZE_WIDTH
	playerPos.y = to / MAZE_WIDTH
	$Player.position = (playerPos + Vector2(0.5, 0.5)) * CELL_WIDTH
func updateStepsLabel():
	$StepLabel.text = "%d steps" % nSteps
func _ready():
	rng.randomize()
	qvalue.resize(MAZE_SIZE)
	qlTable.resize(MAZE_SIZE)
	for y in range(MAZE_HEIGHT):
		var txt = ""
		for x in range(MAZE_WIDTH):
			if $TileMap.get_cell(x, y) <= FLOOR2:
				var ix = xyToIX(x, y)
				qvalue[ix] = [0.0, 0.0, 0.0, 0.0]		# 上、左、右、下方向に移動Q値
				var label = QValueLabel.instance()
				label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH)
				qlTable[ix] = label
				add_child(label)
			txt += String($TileMap.get_cell(x, y))
			txt += " "
		print(txt)
	pass

func _process(delta):
	if !started: return
	# ランダムウォーク
	var r		# 移動方向 0:上、1：左、2:右、3:下
	var to		# 移動先IX
	while true:
		r = rng.randi_range(0, 3)		# [0, 4)
		to = xyToIX(playerPos.x, playerPos.y) + [-MAZE_WIDTH, -1, +1, +MAZE_WIDTH][r]
		if canMoveTo(to):
			moveTo(to)
			break;
	nSteps += 1
	updateStepsLabel()
	if $TileMap.get_cell(playerPos.x, playerPos.y) > FLOOR2:
		started = false

func _on_StartButton_pressed():
	if started: return
	moveTo(xyToIX(START_X, START_Y))
	nSteps = 0
	updateStepsLabel()
	started = true
	pass
