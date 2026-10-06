extends "res://addons/hh_agent/runtime/hh_agent_runtime.gd"

# compiled from live job.plan + PROJECT_BRIEF
# engine: memory-tileflip
# output: res://scripts/memory/board.gd
# art: res://art/memory/tile.png
# board: 2x2 pairs=2 win_at=2
# acc: keyboard cursor plus accept flips a tile
# acc: matching pair increments matches
# acc: two matching pairs set won on the 2x2 board
# acc: Play session uses hh_agent_runtime

var matches: int = 0
var flips: int = 0
var won: bool = false
var cursor: int = 0
var first_pick: int = -1
var last_key: String = ""
var cols: int = 2
var rows: int = 2
var tiles: PackedInt32Array = PackedInt32Array([1, 0, 1, 0])
var revealed: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var hold_left: bool = false
var hold_right: bool = false
var hold_up: bool = false
var hold_down: bool = false
var hold_accept: bool = false


func _ready() -> void:
	super._ready()
	_draw_tiles()


func _process(_delta: float) -> void:
	super._process(_delta)
	hold_left = _edge_move("ui_left", "left", -1, hold_left)
	hold_right = _edge_move("ui_right", "right", 1, hold_right)
	hold_up = _edge_move("ui_up", "up", -cols, hold_up)
	hold_down = _edge_move("ui_down", "down", cols, hold_down)
	var acc: bool = Input.is_action_pressed("ui_accept")
	if acc and not hold_accept:
		last_key = "accept"
		_flip(cursor)
	hold_accept = acc


func agent_observe() -> Dictionary:
	var faces: Array = []
	var wrap: Node = get_node_or_null("Tiles")
	if wrap != null:
		var fi: int = 0
		while fi < wrap.get_child_count():
			var child: Node = wrap.get_child(fi)
			if child is ColorRect:
				var c: Color = (child as ColorRect).color
				faces.append({"r": c.r, "g": c.g, "b": c.b})
			fi += 1
	return {
		"matches": matches,
		"flips": flips,
		"won": won,
		"cursor": cursor,
		"faces": faces,
	}


func _edge_move(action_name: String, label: String, delta: int, was: bool) -> bool:
	var down: bool = Input.is_action_pressed(action_name)
	if down and not was:
		last_key = label
		_nudge(delta)
	return down


func _nudge(delta: int) -> void:
	var next: int = cursor + delta
	var max_i: int = cols * rows - 1
	if next < 0 or next > max_i:
		return
	cursor = next
	_draw_tiles()


func _flip(index: int) -> void:
	if index < 0 or index > 3:
		return
	if revealed[index] == 1:
		return
	revealed[index] = 1
	flips += 1
	if first_pick < 0:
		first_pick = index
		_draw_tiles()
		return
	var same: bool = tiles[first_pick] == tiles[index]
	if same:
		matches += 1
		won = matches >= 2
	else:
		revealed[first_pick] = 0
		revealed[index] = 0
	first_pick = -1
	_draw_tiles()


func _color_of(kind: int) -> Color:
	match kind:
		0: return Color(0.2, 0.7, 0.9, 1)
		1: return Color(0.9, 0.6, 0.2, 1)
		_:
			return Color(0.55, 0.55, 0.6, 1)


func _draw_tiles() -> void:
	var existing: Node = get_node_or_null("Tiles")
	if existing != null:
		existing.free()
	var wrap: Node2D = Node2D.new()
	wrap.name = "Tiles"
	add_child(wrap)
	var i: int = 0
	while i < 4:
		var cell: ColorRect = ColorRect.new()
		cell.name = "Tile%d" % i
		cell.focus_mode = Control.FOCUS_NONE
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.size = Vector2(120, 120)
		var col_i: int = i % cols
		var row_i: int = int(i / cols)
		cell.position = Vector2(360.0 + float(col_i) * 140.0, 200.0 + float(row_i) * 140.0)
		var on: bool = revealed[i] == 1
		if on:
			cell.color = _color_of(tiles[i])
		elif i == cursor:
			cell.color = Color(0.35, 0.35, 0.45, 1)
		else:
			cell.color = Color(0.15, 0.15, 0.2, 1)
		wrap.add_child(cell)
		i += 1
