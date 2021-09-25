extends Node2D


enum {
	FLOOR1 = 0,		# 灰色床
	FLOOR2 = 1,		# 茶色床
	TRAP = 5,
	GOAL = 8,
}

const ALPHA = 0.1
#const GAMMA = 0.1
#const GAMMA = 0.2
const GAMMA = 0.99
const REWARD_GOAL = 1.0
const REWARD_TRAP = -1.0
const EPSILON = 0.05			# この確率でランダム行動

const CELL_WIDTH = 64
const MAZE_WIDTH = 12
const MAZE_HEIGHT = 10
const MAZE_SIZE = MAZE_WIDTH * MAZE_HEIGHT
const START_X = 1
const START_Y = 1
const START_POS = Vector2(START_X, START_Y)

var nRound = 0
var nRoundRemain = 0		# 残りラウンド数
var started = false
var playerPos = START_POS
var goalPos = Vector2(-1, -1)
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
	var mxv = qvalue[ix].max()
	#print(qvalue[ix])
	#qMaxLabel[ix].text = "%.3f" % qvalue[ix].max()
	#qMinLabel[ix].text = "%.3f" % qvalue[ix].min()
	qUpLabel[ix].text = "%7.4f" % qvalue[ix][0]
	qLeftLabel[ix].text = "%7.4f" % qvalue[ix][1]
	qRightLabel[ix].text = "%7.4f" % qvalue[ix][2]
	qDownLabel[ix].text = "%7.4f" % qvalue[ix][3]
	# 最大値を与えるラベル色：緑
	qUpLabel[ix].set("custom_colors/font_color", Color.green if qvalue[ix][0] == mxv else Color.white)
	qLeftLabel[ix].set("custom_colors/font_color", Color.green if qvalue[ix][1] == mxv else Color.white)
	qRightLabel[ix].set("custom_colors/font_color", Color.green if qvalue[ix][2] == mxv else Color.white)
	qDownLabel[ix].set("custom_colors/font_color", Color.green if qvalue[ix][3] == mxv else Color.white)
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
			elif $TileMap.get_cell(x, y) == GOAL:
				goalPos = Vector2(x, y)
			txt += String($TileMap.get_cell(x, y))
			txt += " "
		print(txt)
	pass

func _process(delta):
	if !started: return
	var ix = xyToIX(playerPos.x, playerPos.y)	# 現在位置
	var dir		# 移動方向 0:上、1：左、2:右、3:下
	var to		# 移動先IX
	if rng.randf_range(0, 1.0) < EPSILON:		# ランダムウォーク
		while true:
			dir = rng.randi_range(0, 3)		# [0, 4)
			to = ix + [-MAZE_WIDTH, -1, +1, +MAZE_WIDTH][dir]
			if canMoveTo(to):
				break;
	else:		# 最大Q値の行動を選択、同じ値がある場合はその中から選択
		var mx = REWARD_TRAP - 1
		var lst = []
		for i in range(qvalue[ix].size()):
			if qvalue[ix][i] != REWARD_TRAP:
				if qvalue[ix][i] > mx:
					mx = qvalue[ix][i]
					lst = [i]
				elif qvalue[ix][i] == mx:
					lst.push_back(i)
		if lst.size() > 1:
			dir = lst[rng.randi_range(0, lst.size() - 1)]
		else:
			dir = lst[0]
		to = ix + [-MAZE_WIDTH, -1, +1, +MAZE_WIDTH][dir]
	moveTo(to)
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
			reward = -0.01		# 長くさまようのはマイナス報酬
			if qvalue[to] != null:
				maxQ = qvalue[to].max()
	qvalue[ix][dir] += ALPHA * (reward + GAMMA * maxQ - qvalue[ix][dir])
	updateQValueLabel(ix)
	if !started && nRoundRemain != 0:
		nRoundRemain -= 1
		if nRoundRemain != 0: doStart()
func doStart():
	nRound += 1
	$RoundLabel.text = "#%d Round:" % nRound
	moveTo(xyToIX(START_X, START_Y))
	nSteps = 0
	updateStepsLabel()
	started = true
func _on_StartButton_pressed():
	if started: return
	doStart()
	pass


func _on_Round100Button_pressed():
	nRoundRemain = 100
	doStart()
	pass

func backprop(ix, v):
	pass

func _on_BackpropButton_pressed():
	var lst = [goalPos]
	while lst.size() != 0:
		var lst2 = []
		for i in range(lst.size()):
			var ix = xyToIX(lst[i].x, lst[i].y)
			var v = 1.0 if lst[i] == goalPos else qvalue[ix].max() * 0.99
			backprop(ix-MAZE_WIDTH, v)
			backprop(ix-1, v)
			backprop(ix+1, v)
			backprop(ix+MAZE_WIDTH, v)
	pass # Replace with function body.
