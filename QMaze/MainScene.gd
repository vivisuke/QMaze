extends Node2D


enum {
	FLOOR1 = 0,
	FLOOR2 = 1,
	TRAP = 5,
	GOAL = 8,
}

const ALPHA = 0.1
const GAMMA = 0.1
const REWARD_GOAL = 100.0
const REWARD_TRAP = -100.0

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
#var qMaxLabel = []			# Q値最大値表示用ラベル
#var qMinLabel = []			# Q値最小値表示用ラベル
var qUpLabel = []			# 上移動Q値最表示用ラベル
var qLeftLabel = []			# 左移動Q値最表示用ラベル
var qRightLabel = []		# 右移動Q値最表示用ラベル
var qDownLabel = []			# 下移動Q値最表示用ラベル


var rng = RandomNumberGenerator.new()

var QValueLabel = load("res://QValueLabel.tscn")

func xyToIX(x, y): return x + y * MAZE_WIDTH
func canMoveTo(ix : int):
	var x = ix % MAZE_WIDTH
	var y = ix / MAZE_WIDTH
	var c = $TileMap.get_cell(x, y)
	return c < FLOOR2 || c == GOAL || c == TRAP
func moveTo(to : int):
	playerPos.x = to % MAZE_WIDTH
	playerPos.y = to / MAZE_WIDTH
	$Player.position = (playerPos + Vector2(0.5, 0.5)) * CELL_WIDTH
func updateStepsLabel():
	$StepLabel.text = "%d steps" % nSteps
func updateQValueLabel(ix):
	#print(qvalue[ix])
	#qMaxLabel[ix].text = "%.3f" % qvalue[ix].max()
	#qMinLabel[ix].text = "%.3f" % qvalue[ix].min()
	qUpLabel[ix].text = "%.2f" % qvalue[ix][0]
	qLeftLabel[ix].text = "%.2f" % qvalue[ix][1]
	qRightLabel[ix].text = "%.2f" % qvalue[ix][2]
	qDownLabel[ix].text = "%.2f" % qvalue[ix][3]
func _ready():
	rng.randomize()
	qvalue.resize(MAZE_SIZE)
	#qMaxLabel.resize(MAZE_SIZE)
	#qMinLabel.resize(MAZE_SIZE)
	qUpLabel.resize(MAZE_SIZE)
	qLeftLabel.resize(MAZE_SIZE)
	qRightLabel.resize(MAZE_SIZE)
	qDownLabel.resize(MAZE_SIZE)
	for y in range(MAZE_HEIGHT):
		var txt = ""
		for x in range(MAZE_WIDTH):
			if $TileMap.get_cell(x, y) <= FLOOR2:
				var ix = xyToIX(x, y)
				qvalue[ix] = [0.0, 0.0, 0.0, 0.0]		# 上、左、右、下方向に移動Q値
				var label = QValueLabel.instance()
				label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH)
				qUpLabel[ix] = label
				add_child(label)
				label = QValueLabel.instance()
				label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH+CELL_WIDTH*0.23)
				qLeftLabel[ix] = label
				add_child(label)
				label = QValueLabel.instance()
				label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH+CELL_WIDTH*0.23*2)
				qRightLabel[ix] = label
				add_child(label)
				label = QValueLabel.instance()
				label.rect_position = Vector2(x*CELL_WIDTH, y*CELL_WIDTH+CELL_WIDTH*0.23*3)
				qDownLabel[ix] = label
				add_child(label)
				if !canMoveTo(ix - MAZE_WIDTH): qvalue[ix][0] = REWARD_TRAP
				if !canMoveTo(ix - 1): qvalue[ix][1] = REWARD_TRAP
				if !canMoveTo(ix + 1): qvalue[ix][2] = REWARD_TRAP
				if !canMoveTo(ix + MAZE_WIDTH): qvalue[ix][3] = REWARD_TRAP
				updateQValueLabel(ix)
			txt += String($TileMap.get_cell(x, y))
			txt += " "
		print(txt)
	pass

func _process(delta):
	if !started: return
	# ランダムウォーク
	var ix = xyToIX(playerPos.x, playerPos.y)	# 現在位置
	var dir		# 移動方向 0:上、1：左、2:右、3:下
	var to		# 移動先IX
	while true:
		dir = rng.randi_range(0, 3)		# [0, 4)
		to = ix + [-MAZE_WIDTH, -1, +1, +MAZE_WIDTH][dir]
		if canMoveTo(to):
			moveTo(to)
			break;
	nSteps += 1
	updateStepsLabel()
	#var c = $TileMap.get_cell(playerPos.x, playerPos.y)
	#if $TileMap.get_cell(playerPos.x, playerPos.y) > FLOOR2:
	#	started = false
	var reward = 0		# 報酬
	var maxQ = 0		# 最大Q値
	match $TileMap.get_cell(playerPos.x, playerPos.y):
		GOAL:
			reward = REWARD_GOAL
			started = false
		TRAP:
			reward = REWARD_TRAP
			started = false
		_:		# FLOOR1, FLOOR2
			maxQ = qvalue[to].max()
	qvalue[ix][dir] += ALPHA * (reward * GAMMA + maxQ - qvalue[ix][dir])
	updateQValueLabel(ix)
func _on_StartButton_pressed():
	if started: return
	moveTo(xyToIX(START_X, START_Y))
	nSteps = 0
	updateStepsLabel()
	started = true
	pass
