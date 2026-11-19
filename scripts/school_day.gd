extends Control

signal leave_requested
signal sound_requested(cue: String)

const D = preload("res://scripts/school_data.gd")
const BOARD := Color("#233f3d")
const BOARD_DARK := Color("#192e31")
const PAPER := Color("#f4edda")
const INK := Color("#253b46")
const BLUE := Color("#275879")
const RED := Color("#a24942")
const MUTED := Color("#526568")
const GOLD := Color("#eed29a")
const START := 8 * 60 + 30
const LESSON_MIN := 45
const BREAK_MIN := 10
const RUN_SECONDS := 20.0
const SUNNY_WINDOW_FILE := "res://assets/art/backgrounds/school_sunny_window.png"
const PACE_NAMES := ["Отдышаться", "Держать темп", "Ускориться"]
const PACE_SPEED := [1.5, 3.4, 5.5]
const PACE_STAMINA := [20.0, -5.0, -14.0]
const PORTRAIT_REGIONS := [
	Rect2(0, 0, 417, 793), Rect2(417, 0, 377, 793), Rect2(794, 0, 383, 793),
	Rect2(1177, 0, 393, 793), Rect2(1570, 0, 413, 793),
]

var stage := "catalog"
var lesson := 0
var minutes := START
var grades: Array[int] = []
var energy := 2
var used_bun := false
var energy_before_mark := 2
var bun_energy_before := 0
var chat_messages: Array = []
var chat_narration := ""
var round_index := 0
var round_correct := false
var mistakes := 0
var hinted_rounds: Array[int] = []
var cards: Array = []
var selected := 0
var feedback := ""
var ending := ""
var time_left := 0.0
var battery := false
var wire := false
var closed_switch := false
var experiment := 0
var timeline: Array[int] = []
var history_cards: Array[int] = []
var knowledge: Array[int] = []
var pace := 1
var run_distance := 0.0
var stamina := 65.0

var page := Control.new()
var shortcuts: Array[Button] = []
var counter: Label
var timer_label: Label
var activity_hint: Label
var stamina_bar: ProgressBar
var scroll: ScrollContainer
var joke: Label
var joke_left := 0.0
var swipe_start := Vector2.ZERO
var swipe_finger := -1
var portrait_atlas: Texture2D
var sunny_window: Texture2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(D.PORTRAIT_ATLAS):
		portrait_atlas = load(D.PORTRAIT_ATLAS) as Texture2D
	if ResourceLoader.exists(SUNNY_WINDOW_FILE):
		sunny_window = load(SUNNY_WINDOW_FILE) as Texture2D
	_render()

func _change(next: String) -> void:
	stage = next
	swipe_finger = -1
	_render()

func _start_day() -> void:
	lesson = 0
	minutes = START
	grades.clear()
	energy = 2
	used_bun = false
	energy_before_mark = 2
	bun_energy_before = 0
	chat_messages.clear()
	chat_narration = ""
	knowledge.clear()
	timeline.clear()
	hinted_rounds.clear()
	mistakes = 0
	round_index = 0
	feedback = ""
	ending = ""
	joke_left = 0.0
	time_left = 0.0
	sound_requested.emit("school_bell")
	_change("schedule")

func _lesson_start() -> int:
	return START + lesson * (LESSON_MIN + BREAK_MIN)

func _briefing() -> void:
	minutes = _lesson_start()
	feedback = ""
	mistakes = 0
	hinted_rounds.clear()
	sound_requested.emit(["school_bell", "school_door", "school_ruler", "school_chair", "school_whistle"][lesson])
	_change("briefing")

func _begin_lesson() -> void:
	if stage != "briefing":
		return
	match lesson:
		0, 1:
			round_index = 0
			_next_cards()
		2:
			battery = false
			wire = false
			closed_switch = false
			experiment = 0
			_change("circuit")
		3:
			timeline.clear()
			knowledge.clear()
			history_cards.assign([0, 1, 2])
			history_cards.shuffle()
			_change("timeline")
		4:
			pace = 1
			stamina = 50.0 + energy * 15.0
			run_distance = 0.0
			time_left = RUN_SECONDS
			_change("pace")

func _rounds() -> Array:
	return D.ALGEBRA if lesson == 0 else D.RUSSIAN

func _next_cards() -> void:
	cards = _rounds()[round_index]["answers"].duplicate()
	cards.shuffle()
	selected = 0
	feedback = ""
	_change("cards")

func _cycle(direction: int) -> void:
	if stage != "cards":
		return
	selected = wrapi(selected + direction, 0, cards.size())
	_render()

func _spend(cost: int) -> bool:
	minutes += cost
	if minutes > _lesson_start() + LESSON_MIN:
		_finish_lesson(2, "Звонок. Время на работу закончилось. Незаконченную работу придётся исправлять дома.")
		return false
	return true

func _answer() -> void:
	if stage != "cards":
		return
	round_correct = cards[selected] == _rounds()[round_index]["answers"][0]
	if not _spend(3 if round_correct else 5):
		return
	if not round_correct:
		mistakes += 1
	var rule: String = _rounds()[round_index]["rule"]
	feedback = ("Верно. " if round_correct else "Попробуйте ещё раз. Ошибка стоит 5 минут.\n") + rule
	_change("answer")

func _after_answer() -> void:
	if stage != "answer":
		return
	if round_correct:
		round_index += 1
		if round_index == _rounds().size():
			_finish_lesson(_work_grade(), "Решение проверено: 3 × (6 − 2) = 12." if lesson == 0 else "Записка исправлена. Сдаём. Проверю выборочно.")
			return
	_next_cards()

func _hint() -> void:
	if stage != "cards" or lesson != 0:
		return
	if not hinted_rounds.has(round_index):
		if not _spend(3):
			return
		hinted_rounds.append(round_index)
		mistakes += 1
	feedback = _rounds()[round_index]["hint"]
	_render()

func _work_grade() -> int:
	return maxi(2, 5 - mistakes)

func _toggle_component(index: int) -> void:
	if stage != "circuit" or not _spend(2):
		return
	match index:
		0: battery = not battery
		1: closed_switch = not closed_switch
		2: wire = not wire
	feedback = "Лампа светится." if _lamp_on() else "Лампа не горит. Ток идёт только по замкнутой цепи с источником."
	_render()

func _lamp_on() -> bool:
	return battery and wire and closed_switch

func _check_circuit() -> void:
	if stage != "circuit":
		return
	var solved := _lamp_on() if experiment == 0 else battery and wire and not closed_switch
	if not solved:
		mistakes += 1
		if not _spend(5):
			return
		if experiment == 0:
			feedback = "Проверьте источник, целый провод и замкнутый ключ. Все три нужны, чтобы пошёл ток."
		else:
			feedback = "Разомкните ключ. Батарейку и провод оставьте на месте: ключ управляет током."
		_render()
		return
	if experiment == 0:
		experiment = 1
		feedback = "Цепь замкнута, ток идёт. Теперь выключите лампу только ключом."
		_render()
	else:
		_finish_lesson(_work_grade(), "Оба опыта записаны. Замкнутый ключ пропускает ток, разомкнутый прерывает цепь.")

func _history_clue(index: int) -> void:
	if stage != "timeline":
		return
	if not knowledge.has(index):
		if not _spend(2):
			return
		knowledge.append(index)
	feedback = D.HISTORY_CLUES[index][1]
	_render()

func _timeline_choose(index: int) -> void:
	if stage != "timeline" or not _spend(1):
		return
	if timeline.has(index):
		timeline.erase(index)
	else:
		timeline.append(index)
	feedback = "Выбрано %d из 3. Нажмите выбранное событие, чтобы снять его." % timeline.size()
	_render()

func _check_timeline() -> void:
	if stage != "timeline":
		return
	if timeline.size() != 3:
		feedback = "Нужны все три события. Нажимайте их от самого раннего к самому позднему."
		_render()
		return
	if timeline == [0, 1, 2]:
		_finish_lesson(_work_grade(), "Верно. Сначала вторжение, затем Бородино, потом армия Наполеона оставляет Москву.")
	else:
		mistakes += 1
		if not _spend(5):
			return
		feedback = "Порядок нарушен. Бородино было после вторжения и до ухода из Москвы. Переложите события."
		_render()

func _set_pace(index: int) -> void:
	if stage != "pace":
		return
	pace = index
	_update_run_labels()

func _run_tick(delta: float) -> void:
	var remaining := minf(delta, time_left)
	while remaining > 0.0:
		var step := minf(remaining, 0.1)
		var speed: float = PACE_SPEED[pace]
		if stamina < 12.0 and pace != 0:
			speed = 1.2
		run_distance = minf(60.0, run_distance + speed * step)
		stamina = clampf(stamina + PACE_STAMINA[pace] * step, 0.0, 100.0)
		remaining -= step
		time_left = maxf(0.0, time_left - step)
		if run_distance >= 60.0:
			time_left = 0.0
			break
	if time_left <= 0.0:
		var distance_tenths := roundi(run_distance * 10.0)
		run_distance = distance_tenths / 10.0
		var grade := 5 if distance_tenths >= 600 else (4 if distance_tenths >= 450 else (3 if distance_tenths >= 300 else 2))
		_finish_lesson(grade, "Время. Следующий.\nДистанция: %s м. Вы распределяли силы, пока часы шли сами." % _decimal(run_distance))
		sound_requested.emit("school_whistle")
	else:
		_update_run_labels()
		queue_redraw()

func _finish_lesson(grade: int, line: String) -> void:
	if grades.size() != lesson:
		return
	grades.append(grade)
	energy_before_mark = energy
	energy = maxi(0, energy - 1)
	minutes = _lesson_start() + LESSON_MIN
	feedback = line
	if lesson != 4:
		sound_requested.emit("school_bell")
	_change("mark")

func _next_lesson() -> void:
	lesson += 1
	_briefing()

func _after_mark() -> void:
	match lesson:
		0: _change("break_chat")
		3: _change("break_bun")
		4: _change("afternoon")
		_: _change("break_calm")

func _after_wait() -> void:
	minutes = 15 * 60
	_change("homework")

func _eat_bun() -> void:
	if stage != "break_bun" or used_bun:
		return
	used_bun = true
	bun_energy_before = energy
	energy = mini(2, energy + 1)
	_render()

func _average() -> float:
	if grades.is_empty():
		return 0.0
	return float(grades.reduce(func(a, b): return a + b)) / grades.size()

func _total_tasks() -> int:
	return D.HOMEWORK_BASE + grades.count(5) + grades.count(2)

func _after_school(index: int) -> void:
	chat_messages.clear()
	chat_narration = ""
	match index:
		0: feedback = "Сеанс уже начался, пока вы разбирались со списком.\nСделано: 1/%d. Осталось: %d." % [_total_tasks(), _total_tasks() - 1]
		1: feedback = "Классная: «Куда? А ДЗ?»\nВыход закрыт до выполнения заданий. Выход откроется после 11 класса.\nНачало сеанса уже пропущено из-за задержки у списка."
		2:
			chat_messages = D.AFTER_MESSAGES["messages"].duplicate(true)
			chat_narration = D.AFTER_MESSAGES["narration"]
	_change("after_reply")

func _show_ending() -> void:
	var average := _average()
	ending = "human" if average >= 4.5 else ("formal" if average >= 3.0 else "burnout")
	sound_requested.emit("win" if ending == "human" else "late")
	_change("ending")

func _process(delta: float) -> void:
	if joke_left > 0.0:
		joke_left -= delta
		if joke_left <= 0.0 and is_instance_valid(joke):
			joke.hide()
	if stage == "pace":
		_run_tick(delta)

func _decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")

func _clock() -> String:
	return _format_time(minutes)

func _format_time(value: int) -> String:
	return "%02d:%02d" % [floori(value / 60.0), value % 60]

func _break_period() -> String:
	return "%s–%s" % [_format_time(minutes), _format_time(minutes + BREAK_MIN)]

func _show_exit_joke() -> void:
	joke_left = 3.5
	joke.show()

func _chat_visible() -> bool:
	return stage in ["intro", "intro_reply", "break_chat", "chat_reply"] or (stage == "after_reply" and not chat_messages.is_empty())

func _input(event: InputEvent) -> void:
	if is_queued_for_deletion() or not is_visible_in_tree():
		return
	if stage == "homework":
		if event is InputEventScreenTouch:
			if event.pressed and scroll.get_global_rect().has_point(event.position):
				swipe_finger = event.index
				get_viewport().set_input_as_handled()
			elif not event.pressed and event.index == swipe_finger:
				swipe_finger = -1
				get_viewport().set_input_as_handled()
			return
		if event is InputEventScreenDrag and event.index == swipe_finger:
			scroll.scroll_vertical -= roundi(event.relative.y)
			get_viewport().set_input_as_handled()
			return
	if stage == "cards" and event is InputEventScreenTouch:
		if event.pressed and event.position.y > 260 and event.position.y < 470:
			swipe_finger = event.index
			swipe_start = event.position
		elif not event.pressed and event.index == swipe_finger:
			swipe_finger = -1
			var travel: float = event.position.x - swipe_start.x
			if absf(travel) > 45.0:
				_cycle(-1 if travel > 0.0 else 1)
				get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey:
		return
	var key: int = event.keycode
	if not event.pressed or event.echo:
		if key in [KEY_SPACE, KEY_ENTER]:
			get_viewport().set_input_as_handled()
		return
	if key == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		leave_requested.emit()
		return
	var focused := get_viewport().gui_get_focus_owner()
	if key in [KEY_SPACE, KEY_ENTER] and focused is Button:
		if not focused.disabled:
			focused.pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if stage == "cards" and key in [KEY_LEFT, KEY_RIGHT]:
		_cycle(-1 if key == KEY_LEFT else 1)
	elif stage == "cards" and key in [KEY_SPACE, KEY_ENTER]:
		_answer()
	elif stage == "homework" and key in [KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN, KEY_END, KEY_HOME]:
		var move := -80 if key in [KEY_UP, KEY_PAGEUP, KEY_HOME] else 80
		if key in [KEY_PAGEUP, KEY_PAGEDOWN]: move *= 4
		if key in [KEY_HOME, KEY_END]: move *= 100
		scroll.scroll_vertical += move
	elif key >= KEY_1 and key <= KEY_9 and key - KEY_1 < shortcuts.size():
		var button := shortcuts[key - KEY_1]
		if not button.disabled:
			button.pressed.emit()
	elif key in [KEY_ENTER, KEY_SPACE] and shortcuts.size() == 1:
		shortcuts[0].pressed.emit()
	else:
		return
	get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), BOARD_DARK)
	draw_rect(Rect2(0, 0, 1280, 90), BOARD)
	draw_line(Vector2(46, 90), Vector2(1234, 90), Color("#8eaa93"), 2)
	draw_rect(Rect2(56, 126, 843, 490), Color("#101f23"))
	draw_rect(Rect2(48, 118, 843, 490), PAPER)
	if _chat_visible():
		draw_style_box(_style(Color("#d5e3dd"), Color("#abc3b6"), 14), Rect2(84, 132, 772, 163 if stage == "break_chat" else 333))
	else:
		for y in range(217, 606, 28):
			draw_line(Vector2(49, y), Vector2(890, y), Color("#d8dace"))
		draw_line(Vector2(78, 118), Vector2(78, 608), Color("#d6a89a"))
	draw_rect(Rect2(916, 118, 317, 490), BOARD)
	if stage in ["catalog", "ending"]:
		draw_ticket(self, Rect2(100, 354 if stage == "catalog" else 433, 735, 76))
	elif stage == "circuit":
		_draw_circuit()
	elif stage == "pace":
		_draw_runner()

static func draw_ticket(canvas: CanvasItem, rect: Rect2) -> void:
	var edge := Color("#9a7050")
	canvas.draw_rect(rect, Color("#e7bd88"))
	canvas.draw_rect(rect.grow(-4), edge, false, 1.5)
	var seam := rect.end.x - rect.size.x * 0.18
	canvas.draw_dashed_line(Vector2(seam, rect.position.y + 6), Vector2(seam, rect.end.y - 6), edge, 2, 5)
	for i in range(12):
		var x := seam + 11 + i * rect.size.x * 0.011
		canvas.draw_line(Vector2(x, rect.position.y + rect.size.y * 0.23), Vector2(x, rect.end.y - rect.size.y * 0.23), INK, 1 + i % 3)

func _draw_circuit() -> void:
	var tint := BLUE if _lamp_on() else MUTED
	draw_line(Vector2(202, 338), Vector2(414, 338), tint, 4)
	draw_line(Vector2(512, 338), Vector2(730, 338), tint, 4)
	draw_polyline(PackedVector2Array([Vector2(730, 338), Vector2(802, 338), Vector2(802, 391), Vector2(560, 391)]), tint, 4)
	draw_polyline(PackedVector2Array([Vector2(430, 391), Vector2(132, 391), Vector2(132, 338), Vector2(175, 338)]), tint, 4)
	draw_line(Vector2(430, 391), Vector2(560, 391) if wire else Vector2(480, 371), tint, 4)
	if battery:
		draw_line(Vector2(183, 313), Vector2(183, 363), INK, 5)
		draw_line(Vector2(201, 322), Vector2(201, 355), INK, 4)
	else:
		draw_arc(Vector2(190, 338), 23, 0, TAU, 24, MUTED, 2)
	draw_circle(Vector2(422, 338), 5, INK)
	draw_circle(Vector2(505, 338), 5, INK)
	draw_line(Vector2(422, 338), Vector2(505, 338) if closed_switch else Vector2(490, 308), INK, 4)
	draw_circle(Vector2(730, 338), 28, GOLD if _lamp_on() else Color("#d5d7c9"))
	draw_arc(Vector2(730, 338), 28, 0, TAU, 32, INK, 3)
	draw_line(Vector2(714, 322), Vector2(746, 354), INK, 3)
	draw_line(Vector2(714, 354), Vector2(746, 322), INK, 3)

func _draw_runner() -> void:
	for y in [330, 355, 380]:
		draw_line(Vector2(100, y), Vector2(835, y), Color("#b39882"), 2)
	var x := 115 + run_distance / 60.0 * 690
	draw_circle(Vector2(x, 318), 8, BLUE)
	draw_line(Vector2(x, 326), Vector2(x, 348), BLUE, 4)
	draw_line(Vector2(x, 335), Vector2(x - 12, 343), BLUE, 4)
	draw_line(Vector2(x, 335), Vector2(x + 12, 330), BLUE, 4)
	draw_line(Vector2(x, 348), Vector2(x - 12, 362), BLUE, 4)
	draw_line(Vector2(x, 348), Vector2(x + 12, 358), BLUE, 4)
	draw_line(Vector2(825, 310), Vector2(825, 386), RED, 4)

func _style(fill: Color, border: Color, radius := 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box

func _label(rect: Rect2, words: String, font_size: int, color := INK) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(label)
	return label

func _button(rect: Rect2, words: String, action: Callable, primary := false, numbered := true, font_size := 18) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = ("%d   " % (shortcuts.size() + 1) if numbered else "") + words
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(BLUE if primary else Color("#eee8d3"), BLUE))
	button.add_theme_stylebox_override("hover", _style(Color("#356f8f") if primary else Color("#f9edbc"), BLUE))
	button.add_theme_stylebox_override("pressed", _style(BOARD, BOARD))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	page.add_child(button)
	if numbered:
		shortcuts.append(button)
	return button

func _heading(kicker: String, title: String) -> void:
	_label(Rect2(99, 142, 745, 28), kicker.to_upper(), 16, MUTED)
	_label(Rect2(97, 173, 754, 61), title, 36)

func _body(words: String, y := 251, font_size := 25) -> void:
	_label(Rect2(100, y, 741, 524 - y), words, font_size)

func _main_button(words: String, action: Callable) -> void:
	_button(Rect2(100, 529, 735, 53), words, action, true)

func _choices(words: Array, action: Callable, top: int) -> void:
	for i in words.size():
		_button(Rect2(100, top + i * 56, 735, 48), words[i], action.bind(i), i == 0)

func _sidebar() -> void:
	if stage == "catalog":
		_label(Rect2(940, 146, 269, 38), "Образование", 26, PAPER)
		_label(Rect2(940, 200, 270, 42), "Остальные темы", 18, GOLD)
		for i in D.OTHER_TOPICS.size():
			_label(Rect2(940, 240 + i * 88, 269, 82), D.OTHER_TOPICS[i], 17, Color("#a5afac"))
		return
	var at_lesson := stage in ["briefing", "cards", "answer", "circuit", "timeline", "pace", "mark"]
	if at_lesson and portrait_atlas != null:
		var portrait := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = portrait_atlas
		atlas.region = PORTRAIT_REGIONS[lesson]
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = atlas
		portrait.position = Vector2(936, 127)
		portrait.size = Vector2(277, 209)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(portrait)
	if at_lesson:
		_label(Rect2(940, 338, 270, 34), D.TEACHERS[lesson], 22, GOLD)
	else:
		_label(Rect2(940, 146, 270, 42), "Дневник", 29, PAPER)
	var row_top := 381 if at_lesson else 205
	for i in D.SUBJECTS.size():
		var y := row_top + i * 29
		var col := GOLD if i == lesson else Color("#d0d9ce")
		_label(Rect2(940, y, 218, 29), D.SUBJECTS[i], 17, col)
		_label(Rect2(1178, y, 35, 29), str(grades[i]) if i < grades.size() else "·", 18, col)
	var summary_y := 536 if at_lesson else 380
	_label(Rect2(940, summary_y, 270, 29), "Средний   " + (_decimal(_average()) if not grades.is_empty() else "—"), 18, PAPER)
	_label(Rect2(940, summary_y + 30, 270, 29), "Силы %d/3 · %s" % [energy + 1, D.ENERGY[energy]], 18, GOLD)
	for i in 3:
		var segment := ColorRect.new()
		segment.position = Vector2(940 + i * 90, summary_y + 61)
		segment.size = Vector2(79, 9)
		segment.color = GOLD if i <= energy else Color("#405b57")
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(segment)
	if not at_lesson:
		_label(Rect2(940, 505, 269, 78), "Сеанс с Максом\n15:30", 21, GOLD)

func _render() -> void:
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	shortcuts.clear()
	queue_redraw()
	_label(Rect2(48, 15, 876, 32), "ОБРАЗОВАНИЕ    /    СДАТЬ ПЯТЬ УРОКОВ    /    %d ИЗ 5" % grades.size(), 16, GOLD)
	_label(Rect2(47, 40, 850, 45), D.TITLE, 31, PAPER)
	_label(Rect2(1024, 22, 190, 58), _clock(), 36, PAPER).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sidebar()
	_button(Rect2(48, 651, 195, 45), "К сериям   Esc", func(): leave_requested.emit(), false, false, 16)
	_button(Rect2(1102, 651, 131, 45), "Выход", _show_exit_joke, false, false, 16)
	joke = _label(Rect2(262, 663, 825, 47), D.EXIT_JOKE, 18, GOLD)
	joke.visible = joke_left > 0.0
	match stage:
		"catalog":
			_heading("Серия 01  /  Вы школьник", "Сдать пять уроков")
			_body("Решите задания по пяти предметам и получите оценки в дневник. Ошибки можно исправлять. Макс ждёт в кино к 15:30.", 243, 24)
			_label(Rect2(124, 372, 553, 45), "КИНО    /    СЕАНС 15:30    /    2 БИЛЕТА", 21)
			_label(Rect2(100, 451, 735, 65), "Оценки определят итог дня. Каждый урок отнимает силы — перед бегом будет одна булочка.", 19, MUTED)
			_main_button("Войти в школу", _start_day)
		"schedule":
			_heading("Расписание на доске", "Сегодня лёгкий день")
			_body("Пять уроков — пять работ. Сдача каждой работы записывает оценку и открывает следующий урок.\n\nАлгебра, русский, физика, история, физкультура.", 249, 24)
			_main_button("Проверить телефон", func(): _change("intro"))
		"intro":
			_draw_chat([{"speaker": "Макс", "text": D.INTRO}], "")
			_choices(D.INTRO_OPTIONS, _intro_choice, 391)
		"intro_reply", "chat_reply", "after_reply":
			if _chat_visible():
				_draw_chat(chat_messages, chat_narration)
			else:
				_heading("После списка", "Начало сеанса пропущено")
				_body(feedback, 247, 23)
			if stage == "intro_reply": _main_button("На алгебру", _briefing)
			elif stage == "chat_reply": _main_button("На русский", _next_lesson)
			else: _main_button("Итог дня", _show_ending)
		"briefing":
			_heading("Урок %d  /  %s" % [lesson + 1, D.CLASSES[lesson]], D.SUBJECTS[lesson])
			_body("«%s»" % D.TEACHER_LINES[lesson], 239, 22)
			_label(Rect2(100, 351, 731, 150), D.TASKS[lesson], 21, MUTED)
			_label(Rect2(100, 483, 735, 40), "60 м — 5 · от 45 м — 4 · от 30 м — 3 · меньше 30 м — 2" if lesson == 4 else "Оценка от 5 до 2. Ошибочная проверка снижает её на 1. Лимит 45 минут.", 16, BLUE)
			_main_button("Приступить", _begin_lesson)
		"cards": _draw_cards_page()
		"answer":
			_heading(D.TEACHERS[lesson], "Разберём ответ")
			_body(feedback, 247, 24)
			_main_button("Следующий шаг" if round_correct else "Исправить ответ", _after_answer)
		"circuit": _draw_circuit_page()
		"timeline": _draw_timeline_page()
		"pace": _draw_run_page()
		"mark":
			_heading("Дневник  /  " + D.SUBJECTS[lesson], "Оценка за урок: %d" % grades.back())
			_body("%s\n\nСилы после урока: было %d/3, стало %d/3." % [feedback, energy_before_mark + 1, energy + 1], 249, 22)
			_main_button("В раздевалку" if lesson == 4 else "На перемену", _after_mark)
		"afternoon":
			_heading("После пятого урока", "Школа продолжается")
			_body(D.AFTER_LESSONS)
			_main_button("К выходу   ·   15:00", _after_wait)
		"break_chat":
			_draw_chat([{"speaker": "Макс", "text": "Ну как?"}], D.BREAK_LINES[lesson], "Перемена 10 минут  /  " + _break_period())
			_choices(["Нормально", "Не спрашивай"], _chat_choice, 380)
		"break_calm":
			_heading("Перемена  /  10 минут  /  " + _break_period(), "Передышка в коридоре")
			_label(Rect2(100, 239, 735, 59), D.BREAK_LINES[lesson], 20)
			_window_photo(Rect2(100, 300, 735, 210))
			_main_button("Следующий урок   ·   " + _format_time(minutes + BREAK_MIN), _next_lesson)
		"break_bun":
			_heading("Перемена  /  10 минут  /  " + _break_period(), "Перед физкультурой")
			if used_bun:
				_body("Булочка съедена: +1 ступень сил.\nСилы выросли с %d/3 до %d/3.\nВыносливость перед бегом выросла с %d до %d." % [bun_energy_before + 1, energy + 1, 50 + bun_energy_before * 15, 50 + energy * 15], 239, 22)
				_window_photo(Rect2(100, 365, 735, 147))
			else:
				_label(Rect2(100, 239, 735, 71), "Перекусите и переведите дух. Булочка даст +1 ступень сил и +15 выносливости на старте бега.", 21)
				_window_photo(Rect2(100, 316, 735, 120))
				_button(Rect2(100, 451, 735, 49), "Съесть булочку   ·   +1 ступень сил", _eat_bun)
			_main_button("На физкультуру   ·   " + _format_time(minutes + BREAK_MIN), _next_lesson)
		"homework": _draw_homework_page()
		"choice":
			_heading("У выхода  /  Классная", "Домашнее задание")
			_body("%s\nЗадано: %d. Кино уже начинается." % [D.AFTER_READING, _total_tasks()], 249, 23)
			_choices(D.AFTER_OPTIONS, _after_school, 391)
		"ending": _draw_ending_page()

func _intro_choice(index: int) -> void:
	chat_messages = D.INTRO_REPLIES[index]["messages"].duplicate(true)
	chat_narration = D.INTRO_REPLIES[index]["narration"]
	_change("intro_reply")

func _chat_choice(index: int) -> void:
	chat_messages = [
		{"speaker": "Макс", "text": "Ну как?"},
		{"speaker": "Вы", "text": "Нормально" if index == 0 else "Не спрашивай"},
	]
	chat_narration = D.BREAK_LINES[0]
	_change("chat_reply")

func _draw_chat(messages: Array, narration: String, kicker := "Сообщения") -> void:
	_label(Rect2(100, 142, 735, 27), kicker.to_upper(), 16, MUTED)
	_label(Rect2(100, 174, 735, 40), "Макс", 28)
	var font := ThemeDB.fallback_font
	var y := 218.0
	for message in messages:
		var yours: bool = message["speaker"] == "Вы"
		var text: String = message["text"]
		var text_height := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, 616, 18).y
		var height := text_height + 29.0
		var x := 195.0 if yours else 100.0
		var bubble := Panel.new()
		bubble.position = Vector2(x, y)
		bubble.size = Vector2(640, height)
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble.add_theme_stylebox_override("panel", _style(Color("#bed7c5") if yours else Color("#f9faf5"), Color("#adc3b4"), 12))
		page.add_child(bubble)
		_label(Rect2(x + 12, y + 5, 616, 17), message["speaker"], 11, MUTED)
		_label(Rect2(x + 12, y + 22, 616, text_height + 4), text, 18)
		y += height + 8.0
	if narration != "":
		_label(Rect2(100, 307 if stage == "break_chat" else 475, 735, 62 if stage == "break_chat" else 48), narration, 18 if stage == "break_chat" else 16, MUTED)

func _window_photo(rect: Rect2) -> void:
	if sunny_window == null:
		return
	var frame := Panel.new()
	frame.position = rect.position - Vector2(2, 2)
	frame.size = rect.size + Vector2(4, 4)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _style(PAPER, MUTED, 1))
	page.add_child(frame)
	var photo := TextureRect.new()
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.texture = sunny_window
	photo.position = rect.position
	photo.size = rect.size
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(photo)

func _draw_cards_page() -> void:
	_heading("%s  /  Шаг %d из 3" % [D.SUBJECTS[lesson], round_index + 1], "Решите уравнение" if lesson == 0 else "Исправьте записку")
	_label(Rect2(100, 239, 735, 92), _rounds()[round_index]["text"], 26)
	_button(Rect2(100, 345, 106, 75), "Назад", _cycle.bind(-1), false, false)
	_button(Rect2(729, 345, 106, 75), "Вперёд", _cycle.bind(1), false, false)
	var word := _label(Rect2(219, 353, 495, 69), cards[selected], 30, BLUE)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(Rect2(100, 435, 735, 48), feedback if feedback != "" else "Стрелки или свайп выбирают строку. Ошибка стоит 5 минут.", 18, MUTED)
	if lesson == 0:
		_button(Rect2(100, 484, 735, 34), "Подсказка   ·   3 мин и одна ступень оценки" if not hinted_rounds.has(round_index) else "Прочитать подсказку ещё раз   ·   бесплатно", _hint, false, false, 17)
	_main_button("Проверить строку", _answer)

func _draw_circuit_page() -> void:
	_heading("Физика  /  Опыт %d из 2" % (experiment + 1), "Электрическая цепь")
	_label(Rect2(100, 235, 735, 65), "Зажгите лампу: нужен источник и замкнутая цепь." if experiment == 0 else "Выключите лампу ключом. Батарейку и провод оставьте на месте.", 22)
	for i in 3:
		var states := ["Батарейка: " + ("есть" if battery else "нет"), "Ключ: " + ("замкнут" if closed_switch else "разомкнут"), "Провод: " + ("целый" if wire else "разрыв")]
		_button(Rect2(100 + i * 247, 415, 237, 48), states[i], _toggle_component.bind(i), false, true, 17)
	_label(Rect2(100, 473, 735, 45), feedback if feedback != "" else "Кнопки меняют элементы за 2 минуты. Ошибочная проверка стоит 5 минут.", 18, MUTED)
	_main_button("Записать результат опыта", _check_circuit)

func _draw_timeline_page() -> void:
	_heading("История  /  От раннего к позднему", "Хронология 1812 года")
	_label(Rect2(100, 237, 735, 54), feedback if feedback != "" else "Выберите события по порядку. Повторное нажатие снимает выбор. Ошибка при проверке стоит 5 минут.", 18, MUTED)
	for i in 2:
		_button(Rect2(100 + i * 373, 293, 362, 36), D.HISTORY_CLUES[i][0] + ("   ·   2 мин" if not knowledge.has(i) else "   ·   прочитано"), _history_clue.bind(i), false, true, 16)
	for i in history_cards.size():
		var event: int = history_cards[i]
		var order := timeline.find(event)
		var title: String = ("[%d]  " % (order + 1) if order >= 0 else "") + D.HISTORY_EVENTS[event]
		_button(Rect2(100, 341 + i * 57, 735, 48), title, _timeline_choose.bind(event), order >= 0, true, 18)
	_main_button("Проверить порядок", _check_timeline)

func _bar(rect: Rect2, maximum: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.max_value = maximum
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color("#d4d2c4"), Color("#b6baad")))
	bar.add_theme_stylebox_override("fill", _style(color, color))
	page.add_child(bar)
	return bar

func _draw_run_page() -> void:
	_heading("Физкультура  /  Норматив", "Распределите силы")
	counter = _label(Rect2(100, 238, 735, 52), "", 28, BLUE)
	timer_label = _label(Rect2(100, 283, 735, 35), "", 20)
	stamina_bar = _bar(Rect2(100, 399, 735, 13), 100, Color("#637f52"))
	activity_hint = _label(Rect2(100, 422, 735, 49), "", 19, MUTED)
	for i in 3:
		_button(Rect2(100 + i * 247, 484, 237, 50), PACE_NAMES[i], _set_pace.bind(i), i == pace, true, 18)
	_update_run_labels()

func _update_run_labels() -> void:
	counter.text = "Дистанция: %s / 60 м" % _decimal(run_distance)
	timer_label.text = "До свистка: %.1f с   ·   Темп: %s" % [time_left, PACE_NAMES[pace].to_lower()]
	stamina_bar.value = stamina
	activity_hint.text = "Выносливость: %d/100. %s" % [roundi(stamina), "Силы кончаются. Передохните, чтобы снова ускориться." if stamina < 18 else ("Передышка восстанавливает силы." if pace == 0 else "Можно держать темп или рискнуть ускориться.")]
	for i in shortcuts.size():
		shortcuts[i].add_theme_stylebox_override("normal", _style(BLUE if i == pace else Color("#eee8d3"), BLUE))
		shortcuts[i].add_theme_color_override("font_color", Color.WHITE if i == pace else INK)

func _draw_homework_page() -> void:
	_heading("15:00  /  После школы", "У дверей раздевалки")
	_label(Rect2(100, 235, 741, 65), "Классная: «Подождите. Домашнее задание на завтра.»", 22)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(100, 295)
	scroll.size = Vector2(735, 225)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	var entries := D.HOMEWORK.duplicate()
	entries.append("Задано: 214 заданий.")
	entries.append("Повышенной сложности: %d. На исправление: %d. Всего: %d." % [grades.count(5), grades.count(2), _total_tasks()])
	for line in entries:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", INK)
		label.add_theme_font_size_override("font_size", 21)
		list.add_child(label)
	_main_button("Дочитать до конца", _read_list)
	var next_button := shortcuts.back() as Button
	scroll.get_v_scroll_bar().value_changed.connect(func(_value): next_button.text = "1   Что делать?" if _at_list_end() else "1   Дочитать до конца")

func _at_list_end() -> bool:
	var bar := scroll.get_v_scroll_bar()
	return bar.value + bar.page >= bar.max_value - 2.0

func _read_list() -> void:
	if not _at_list_end():
		scroll.scroll_vertical = ceili(scroll.get_v_scroll_bar().max_value)
		return
	minutes = 15 * 60 + 30
	_change("choice")

func _draw_ending_page() -> void:
	var result: Array = D.RESULTS[ending]
	_heading(result[2], result[0])
	_label(Rect2(100, 239, 735, 60), "Классная: «%s»" % result[1], 20)
	_label(Rect2(100, 303, 735, 29), "Дополнительно к домашнему заданию", 18, BLUE)
	var fives := grades.count(5)
	var twos := grades.count(2)
	var tasks := ["заданий", "задание", "задания", "задания", "задания", "заданий"]
	var five_names := ["пятёрок", "пятёрку", "пятёрки", "пятёрки", "пятёрки", "пятёрок"]
	var two_names := ["двоек", "двойку", "двойки", "двойки", "двойки", "двоек"]
	_label(Rect2(100, 333, 735, 57), "%d %s повышенной сложности за %d %s.\n%d %s на исправление за %d %s." % [fives, tasks[fives], fives, five_names[fives], twos, tasks[twos], twos, two_names[twos]], 18)
	_label(Rect2(100, 398, 740, 32), "Всего заданий: 214 + %d + %d = %d. Средний балл: %s." % [fives, twos, _total_tasks(), _decimal(_average())], 18, BLUE)
	_label(Rect2(124, 446, 555, 31), "НАЧАЛО СЕАНСА ПРОПУЩЕНО", 21, RED)
	_label(Rect2(124, 479, 555, 26), "15:30 · Задержка за списком домашнего задания", 15, INK)
	_main_button("Сыграть ещё раз", _start_day)
