extends Control

signal leave_requested
signal sound_requested(cue: String)

const D = preload("res://scripts/patient_data.gd")
const PAPER := Color("#f4edde")
const INK := Color("#25393c")
const MUTED := Color("#607171")
const NIGHT := Color("#17272a")
const ACCENT := Color("#7864a0")
const GOLD := Color("#ebd29b")
const GOOD := Color("#9cdeb1")
const BAD := Color("#f2aaa2")
const DIALOGUE_CHOICES := ["terminal", "window", "hub", "final", "doctor", "options"]

var stage := "title"
var clock := D.CLOCK_START
var relationship := D.RELATIONSHIP_START
var flags: Dictionary = {}
var inspected: Dictionary = {}
var clues: Dictionary = {}
var items: Array[String] = []
var route: Array[String] = []
var title_page := 0
var ending := ""
var final_kind := ""
var referral_arrival := 0
var formal_path := ""
var return_stage := "hub"
var look_text := ""
var look_focus := -1
var dialogue: Array = []
var dialogue_index := 0
var dialogue_next := ""
var dialogue_heading := ""
var docs_cards: Array = []
var docs_t := 0.0
var docs_penalty := 0.0
var docs_feedback := ""
var listen_i := 0
var listen_good_count := 0
var listen_interrupts := 0
var listen_pause_left := 0.0
var listen_nodded := false
var listen_interrupted := false
var listen_feedback := ""
var tickets: Array = []
var ticket_offset := 0.0
var carousel_paid := false
var background: Texture2D
var cast: Texture2D
var ending_art: Dictionary = {}

var page := Control.new()
var buttons: Array[Button] = []
var timer_label: Label
var activity_label: Label
var listen_status: Label
var countdown: ProgressBar
var scroll_targets: Array[ScrollContainer] = []
var touch_scroll: ScrollContainer
var touch_finger := -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background = _load_texture(D.BACKGROUND)
	cast = _load_texture(D.CAST)
	for kind in D.ENDING_ART:
		ending_art[kind] = _load_texture(D.ENDING_ART[kind])
	_reset_state()
	_render()

func _load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _reset_state() -> void:
	clock = D.CLOCK_START
	relationship = D.RELATIONSHIP_START
	flags.clear()
	for flag in D.FLAGS:
		flags[flag] = false
	inspected.clear()
	clues.clear()
	items.assign(D.START_ITEMS)
	route.clear()
	ending = ""
	final_kind = ""
	referral_arrival = 0
	formal_path = ""
	dialogue.clear()
	docs_cards.clear()
	tickets.clear()
	carousel_paid = false

func _start() -> void:
	_reset_state()
	_dialogue(["terminal_intro"], "terminal", "Терминал записи")

func _next_title() -> void:
	if title_page < D.INTRO.size() - 1:
		title_page += 1
		_render()
	else:
		_start()

func _change(next: String) -> void:
	stage = next
	match stage:
		"window_intro":
			_dialogue(["window_intro"], "window", "Первое окно")
			return
		"referral_ready":
			_change("walk")
			return
		"formal_end":
			_end_game("formal")
			return
		"human_end":
			_end_game("human")
			return
	_render()

func _dialogue(keys: Array, next: String, heading := "") -> void:
	var lines: Array = []
	for key in keys:
		lines.append_array(D.BEATS[key])
	_say(lines, next, heading)

func _say(lines: Array, next: String, heading := "") -> void:
	dialogue = lines.duplicate(true)
	dialogue_index = 0
	dialogue_next = next
	dialogue_heading = heading
	_change("dialogue")

func _next_dialogue() -> void:
	if stage != "dialogue":
		return
	if dialogue_index == dialogue.size() - 1 and dialogue_next in DIALOGUE_CHOICES:
		return
	dialogue_index += 1
	if dialogue_index < dialogue.size():
		_render()
	else:
		_change(dialogue_next)

func _in_options_menu() -> bool:
	return stage == "options" or (stage == "dialogue" and dialogue_next == "options" and dialogue_index == dialogue.size() - 1)

func _pay(minutes: int) -> bool:
	clock += minutes
	if clock >= D.CLOCK_END and not flags["has_temp_referral"]:
		clock = D.CLOCK_END
		_end_game("burnout")
		return false
	return true

func _rel(delta: int) -> void:
	relationship = clampi(relationship + delta, 0, 10)

func _terminal(index: int) -> void:
	if stage != "terminal" or not _pay(D.COST["terminal"]):
		return
	route.append(["Терминал: человек", "Терминал: животное", "Терминал: другое"][index])
	_dialogue([["terminal_human", "terminal_animal", "terminal_other"][index], "terminal_receipt"], "window_intro", "Терминал записи")

func _window(index: int) -> void:
	if stage != "window":
		return
	if not _pay(D.COST["demand"] if index == 1 else D.COST["kind"]):
		return
	_rel(-1 if index == 1 else 1)
	flags["saw_failure"] = true
	flags["patient_spoke"] = index == 2
	route.append(["Вежливая просьба", "Требование", "Ника объясняет сама"][index])
	_dialogue([["window_kind", "window_demand", "window_nika"][index], "window_refusal", "hub_intro"], "hub", "Регистрация невозможна")

func _hub_action(action: String) -> void:
	if stage not in ["hub", "final", "options"]:
		return
	match action:
		"look":
			return_stage = "final" if flags["has_reserve_ticket"] else "hub"
			look_focus = -1
			look_text = "Нажмите на предмет или его цифру: 1-9, 0. Стрелки выбирают, Enter осматривает. Первый осмотр стоит 1 минуту, повторный бесплатен."
			_change("look")
		"records":
			return_stage = "final" if flags["has_reserve_ticket"] else "hub"
			_change("records")
		"options": _change("options")
		"back": _change("final" if flags["has_reserve_ticket"] else "hub")
		"wait":
			var next := "final" if flags["has_reserve_ticket"] else "hub"
			if _pay(D.COST["wait"]): _dialogue(["wait"], next, "Ожидание")
		"request":
			if flags["has_reserve_ticket"]:
				_change("final")
			elif flags["listened"]:
				_dialogue(["carousel_intro"], "carousel_ready", "Бумажный резерв")
			elif flags["has_refusal_act"]:
				_dialogue(["listen_intro"], "listen_ready", "Обход системы")
			elif _pay(D.COST["request"]):
				route.append("Оформить ошибку регистрации")
				_dialogue(["request_ticket", "docs_intro"], "docs_ready", "Найти служебный бланк")
		"insurance", "vet", "triton", "show_act": _optional(action)
		"early": _early_referral()
		"formal":
			formal_path = "Официальное разъяснение" if stage == "final" else "Обращение в комиссию"
			_change("formal_confirm")
		"referral": _issue_referral()

func _optional(action: String) -> void:
	var flag: String = {"insurance": "called_insurance", "vet": "called_vet", "triton": "talked_triton", "show_act": "showed_act"}[action]
	if flags[flag]:
		return
	if not _pay(D.COST[action]):
		return
	flags[flag] = true
	if action == "insurance":
		clues["insurance"] = "Полис не получить без регистрации рождения."
	elif action == "vet":
		items.append("Официальный ответ ветслужбы: к животным не отнесена")
	elif action == "triton":
		clues["bk"] = "У регистратора есть резервный талон «БК», без карты."
	route.append({"insurance": "Страховая", "vet": "Ветслужба", "triton": "Господин Тритон", "show_act": "Акт выращивания"}[action])
	_dialogue([action], "options", "Вопросы и звонки")

func _early_referral() -> void:
	if flags["has_refusal_act"] and flags["has_reserve_ticket"]:
		_issue_referral()
		return
	if not _pay(D.COST["early"]):
		return
	var missing := "акта технической невозможности регистрации" if not flags["has_refusal_act"] else "талона «БК», без карты"
	_say([["МП", "Пока не хватает %s. Давайте сначала найдём его." % missing]], "hub", "Что требуется для записи")

func _confirm_formal() -> void:
	if stage != "formal_confirm" or not _pay(D.COST["formal"]):
		return
	items.append("Уведомление о рассмотрении обращения: 30 рабочих дней")
	route.append(formal_path)
	_dialogue(["formal_intro"], "formal_end", "Обращение зарегистрировано")

func _inspect(id: String) -> void:
	if stage != "look":
		return
	for spot in D.HOTSPOTS:
		if spot["id"] != id:
			continue
		look_focus = D.HOTSPOTS.find(spot)
		if not inspected.has(id):
			inspected[id] = true
			if spot.has("clue"):
				clues[spot["clue"]] = spot["note"]
			if not _pay(D.COST["look"]):
				return
		look_text = str(spot["name"]) + ". " + str(spot["text"])
		_render()
		return

func _spot_rect(spot: Dictionary) -> Rect2:
	var area: Array = spot["area"]
	return Rect2(area[0], area[1], area[2], area[3])

func _docs_begin() -> void:
	if stage != "docs_ready":
		return
	docs_t = 0.0
	docs_penalty = 0.0
	docs_feedback = ""
	docs_cards.clear()
	for i in D.DOCS.size():
		docs_cards.append({"spec": D.DOCS[i].duplicate(), "valid": i == 0, "wrong": false})
	docs_cards.shuffle()
	_change("docs")

func _docs_spent() -> float:
	return minf(D.DOCS_TIME, docs_t + docs_penalty)

func _pick_doc(index: int) -> void:
	if stage != "docs" or index < 0 or index >= docs_cards.size():
		return
	var card: Dictionary = docs_cards[index]
	if card["wrong"]:
		return
	if card["valid"]:
		_docs_finish(true)
		return
	card["wrong"] = true
	docs_penalty += D.DOCS_WRONG
	var spec: Array = card["spec"]
	if spec[0] != D.DOCS[0][0]:
		docs_feedback = "По этому бланку можно пожаловаться. Но не доказать ошибку."
	elif spec[1] != 2044:
		docs_feedback = "Эта версия ещё не вышла." if spec[1] > 2044 else "Эта версия уже отменена."
	else:
		docs_feedback = "Это пустой. Система любит пустые, но сейчас нужен заполненный."
	if _docs_spent() >= D.DOCS_TIME:
		_docs_finish(false)
	else:
		_render()

func _docs_finish(success: bool) -> void:
	if stage != "docs":
		return
	var minutes := 2 + maxi(1, ceili(_docs_spent() / 10.0))
	flags["has_refusal_act"] = true
	items.append("Акт технической невозможности регистрации")
	_rel(1 if success else -1)
	route.append("Акт найден" if success else "Акт найден сотрудницей")
	if not _pay(minutes):
		return
	_dialogue(["docs_good" if success else "docs_timeout", "docs_after", "listen_intro"], "listen_ready", "Ошибка регистрации подтверждена")

func _listen_begin() -> void:
	if stage != "listen_ready" or not _pay(D.COST["listen"]):
		return
	listen_i = 0
	listen_good_count = 0
	listen_interrupts = 0
	listen_interrupted = false
	listen_feedback = ""
	_change("listen_talk")

func _listen_continue() -> void:
	if stage != "listen_talk":
		return
	if listen_i == D.LISTEN_CHUNKS.size() - 1:
		_listen_finish()
	else:
		listen_pause_left = D.LISTEN_PAUSE
		listen_nodded = false
		listen_feedback = "Пауза. Сейчас можно кивнуть."
		_change("listen_pause")

func _nod() -> void:
	if stage not in ["listen_talk", "listen_pause"]:
		return
	if stage == "listen_pause":
		if not listen_nodded:
			listen_nodded = true
			listen_good_count += 1
			listen_feedback = "Вы кивнули вовремя."
			activity_label.text = listen_feedback
			sound_requested.emit("up")
	elif stage == "listen_talk" and not listen_interrupted:
		listen_interrupted = true
		listen_interrupts += 1
		listen_feedback = "Фраза ещё не закончилась. Дайте Марине Петровне договорить."
		activity_label.text = listen_feedback
		sound_requested.emit("down")
	listen_status.text = "Вовремя: %d/4   ·   перебивания: %d" % [listen_good_count, listen_interrupts]

func _listen_finish() -> void:
	if stage != "listen_talk" or flags["listened"]:
		return
	var good := listen_good_count >= 3 and listen_interrupts <= 1
	flags["listened"] = true
	flags["listen_good"] = good
	_rel(3 if good else 1)
	clues["bk"] = "Для первичного осмотра нужен резервный талон «БК», без карты."
	route.append("Выслушали Марину Петровну")
	_dialogue(["listen_good" if good else "listen_poor", "listen_after", "carousel_intro"], "carousel_ready", "Бумажный резерв")

func _carousel_begin() -> void:
	if stage != "carousel_ready":
		return
	if not carousel_paid:
		if not _pay(D.COST["carousel"]):
			return
		carousel_paid = true
		tickets = D.TICKETS.duplicate(true)
		ticket_offset = randf() * tickets.size() * D.TICKET_SPACING
	_change("carousel")

func _ticket_x(index: int) -> float:
	var ring: float = tickets.size() * D.TICKET_SPACING
	return wrapf(index * D.TICKET_SPACING - ticket_offset + ring * 0.5, 0.0, ring) - ring * 0.5

func _nearest_ticket() -> int:
	var best := 0
	for i in tickets.size():
		if absf(_ticket_x(i)) < absf(_ticket_x(best)):
			best = i
	return best

func _grab_ticket() -> void:
	if stage != "carousel":
		return
	var index := _nearest_ticket()
	var ticket: Array = tickets[index]
	if ticket[0] == "БК":
		flags["has_reserve_ticket"] = true
		items.append("Талон БК № 000, без карты")
		_rel(2)
		route.append("Резервный талон БК")
		_dialogue(["carousel_good", "final_intro"], "final", "Последнее окно")
	else:
		tickets.remove_at(index)
		_rel(-1)
		if not _pay(D.COST["ticket_wrong"]):
			return
		_say([["МП", ticket[3], "angry"], ["МП", "Вам нужен «без карты», БК. Остальные требуют номер пациента."]], "carousel", "Талон не подходит")

func _referral_projection() -> Dictionary:
	var cost: int = D.COST["referral"] + (D.COST["verify"] if relationship < D.RELATIONSHIP_HIGH else 0)
	var issued := clock + cost
	var arrival: int = issued + D.COST["walk"]
	return {"cost": cost, "issued": issued, "arrival": arrival, "kind": "burnout" if issued >= D.CLOCK_END else ("human" if arrival <= D.DEADLINE else "late")}

func _issue_referral() -> void:
	if stage not in ["hub", "final", "options"]:
		return
	if not flags["has_refusal_act"] or not flags["has_reserve_ticket"]:
		_early_referral()
		return
	var projection := _referral_projection()
	if not _pay(projection["cost"]):
		return
	flags["has_temp_referral"] = true
	items.append("Временная бумажная запись к врачу")
	referral_arrival = projection["arrival"]
	final_kind = projection["kind"]
	route.append("Временная запись")
	if relationship >= D.RELATIONSHIP_HIGH:
		_dialogue(["referral_high"], "walk", "Временная запись выдана")
	else:
		_say([["СИС", "Дополнительная сверка закончена. Временная бумажная запись к врачу выдана."]], "walk", "Временная запись выдана")

func _go_doctor() -> void:
	if stage != "walk":
		return
	clock = referral_arrival
	if final_kind == "human":
		_dialogue(["doctor_intro"], "doctor", "Кабинет врача")
	else:
		_end_game("late")

func _doctor_choice(index: int) -> void:
	if stage != "doctor":
		return
	if index == 1:
		flags["patient_spoke"] = true
	route.append("Ника рассказывает о симптомах" if index == 1 else "Передали талон")
	_dialogue(["doctor_after"], "human_end", "Первичный осмотр")

func _end_game(kind: String) -> void:
	if ending != "":
		return
	ending = kind
	_change("ending_banner")
	sound_requested.emit("win" if kind == "human" else "late" if kind in ["late", "formal"] else "lose")

func _ending_scene() -> void:
	if stage == "ending_banner":
		_dialogue(["end_" + ending], "ending", D.ENDINGS[ending]["title"])

func _process(delta: float) -> void:
	if stage == "docs":
		docs_t += delta
		if _docs_spent() >= D.DOCS_TIME:
			_docs_finish(false)
		else:
			timer_label.text = "Осталось %d с" % ceili(D.DOCS_TIME - _docs_spent())
			countdown.value = D.DOCS_TIME - _docs_spent()
	elif stage == "listen_pause":
		listen_pause_left = maxf(0.0, listen_pause_left - delta)
		countdown.value = listen_pause_left
		countdown.modulate.a = 0.8 + 0.2 * sin(Time.get_ticks_msec() / 250.0)
		timer_label.text = "Пауза: %.1f с" % listen_pause_left
		if listen_pause_left <= 0.0:
			listen_i += 1
			listen_interrupted = false
			listen_feedback = ""
			_change("listen_talk")
	elif stage == "carousel":
		ticket_offset += D.TICKET_SPEED * delta
		queue_redraw()

func _input(event: InputEvent) -> void:
	if is_queued_for_deletion() or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			for scroll in scroll_targets:
				if scroll.get_global_rect().has_point(event.position):
					touch_scroll = scroll
					touch_finger = event.index
					get_viewport().set_input_as_handled()
					return
		elif event.index == touch_finger:
			touch_scroll = null
			touch_finger = -1
			get_viewport().set_input_as_handled()
			return
	if event is InputEventScreenDrag and event.index == touch_finger and is_instance_valid(touch_scroll):
		touch_scroll.scroll_vertical -= roundi(event.relative.y)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if stage == "look" and event.position.y >= 100 and event.position.y < 480:
			for spot in D.HOTSPOTS:
				if _spot_rect(spot).has_point(event.position):
					_inspect(spot["id"])
					get_viewport().set_input_as_handled()
					return
		elif stage == "carousel" and Rect2(32, 130, 1216, 345).has_point(event.position):
			_grab_ticket()
			get_viewport().set_input_as_handled()
			return
	if not event is InputEventKey:
		return
	var key: int = event.keycode
	if not event.pressed or event.echo:
		if key in [KEY_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
		return
	if key == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if stage in ["look", "records", "formal_confirm"] or _in_options_menu():
			_change(return_stage if stage in ["look", "records"] else ("final" if flags["has_reserve_ticket"] else "hub"))
		else:
			leave_requested.emit()
		return
	if not scroll_targets.is_empty() and key in [KEY_PAGEUP, KEY_PAGEDOWN, KEY_HOME, KEY_END]:
		var movement := -280 if key in [KEY_PAGEUP, KEY_HOME] else 280
		if key in [KEY_HOME, KEY_END]: movement *= 100
		scroll_targets[0].scroll_vertical += movement
	elif stage in ["listen_talk", "listen_pause"]:
		if key in [KEY_SPACE, KEY_1]:
			_nod()
		elif key == KEY_ENTER:
			_listen_continue()
		else:
			return
	elif stage == "look" and key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		look_focus = wrapi(look_focus + (-1 if key in [KEY_LEFT, KEY_UP] else 1), 0, D.HOTSPOTS.size())
		look_text = "Выбран предмет: %s. Нажмите Enter для осмотра." % D.HOTSPOTS[look_focus]["name"]
		_render()
	elif stage == "look" and key == KEY_ENTER and look_focus >= 0:
		_inspect(D.HOTSPOTS[look_focus]["id"])
	elif stage == "look" and key >= KEY_1 and key <= KEY_9:
		_inspect(D.HOTSPOTS[key - KEY_1]["id"])
	elif stage == "look" and key == KEY_0:
		_inspect(D.HOTSPOTS[9]["id"])
	elif stage == "carousel" and key in [KEY_SPACE, KEY_1, KEY_ENTER]:
		_grab_ticket()
	elif stage == "docs" and key >= KEY_1 and key <= KEY_9:
		_pick_doc(key - KEY_1)
	elif stage == "docs" and key == KEY_0:
		_pick_doc(9)
	elif key >= KEY_1 and key <= KEY_9 and key - KEY_1 < buttons.size():
		var button := buttons[key - KEY_1]
		if not button.disabled:
			button.pressed.emit()
	elif key in [KEY_ENTER, KEY_SPACE]:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.pressed.emit()
		elif stage == "dialogue":
			_next_dialogue()
		elif buttons.size() == 1:
			buttons[0].pressed.emit()
		else:
			return
	else:
		return
	get_viewport().set_input_as_handled()

func _draw() -> void:
	if background != null:
		draw_texture_rect(background, Rect2(0, 0, 1280, 720), false)
	else:
		draw_rect(Rect2(0, 0, 1280, 720), NIGHT)
	if stage != "look":
		draw_rect(Rect2(0, 90, 1280, 630), Color(0.04, 0.09, 0.10, 0.76))
	draw_rect(Rect2(0, 0, 1280, 94), Color(0.06, 0.12, 0.14, 0.96))
	draw_rect(Rect2(645, 56, 260, 8), Color("#425455"))
	draw_rect(Rect2(645, 56, 26 * relationship, 8), Color("#b2a4d2"))
	if stage == "look":
		for i in D.HOTSPOTS.size():
			var spot: Dictionary = D.HOTSPOTS[i]
			var rect := _spot_rect(spot)
			draw_rect(rect, Color(0.90, 0.83, 0.65, 0.17 if inspected.has(spot["id"]) else 0.08))
			draw_rect(rect, Color(GOLD, 0.95 if i == look_focus else 0.55), false, 3.0 if i == look_focus else 1.5)
			var badge := Rect2(rect.position + Vector2(2, 2), Vector2(23, 23))
			draw_rect(badge, PAPER)
			draw_string(ThemeDB.fallback_font, badge.position + Vector2(7, 17), str(i + 1) if i < 9 else "0", HORIZONTAL_ALIGNMENT_LEFT, 20, 15, INK)
	elif stage == "carousel":
		_draw_tickets()

func _draw_tickets() -> void:
	var font := ThemeDB.fallback_font
	for i in tickets.size():
		var x := 640.0 + _ticket_x(i)
		if x < -100 or x > 1380:
			continue
		var rect := Rect2(x - 76, 265, 152, 150)
		draw_rect(rect, PAPER)
		draw_rect(rect, Color("#a396bb"), false, 3)
		draw_string(font, Vector2(x - 61, 302), tickets[i][0], HORIZONTAL_ALIGNMENT_CENTER, 122, 31, ACCENT)
		draw_multiline_string(font, Vector2(x - 64, 338), tickets[i][1], HORIZONTAL_ALIGNMENT_CENTER, 128, 20, -1, INK)
		draw_string(font, Vector2(x - 66, 393), tickets[i][2], HORIZONTAL_ALIGNMENT_CENTER, 132, 13, MUTED)
	draw_rect(Rect2(552, 253, 176, 176), GOLD, false, 4)
	draw_line(Vector2(640, 434), Vector2(640, 459), GOLD, 4)

func _style(fill: Color, border: Color, radius := 6) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box

func _panel(rect: Rect2, fill := PAPER, border := Color("#a297ac")) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, border))
	page.add_child(panel)
	return panel

func _label(rect: Rect2, text: String, size := 22, color := INK) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(label)
	return label

func _button(rect: Rect2, text: String, action: Callable, primary := false, numbered := true, size := 17) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = ("%d   " % (buttons.size() + 1) if numbered else "") + text
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(ACCENT if primary else PAPER, ACCENT))
	button.add_theme_stylebox_override("hover", _style(Color("#8d79b2") if primary else Color("#ffefc2"), ACCENT))
	button.add_theme_stylebox_override("pressed", _style(NIGHT, ACCENT))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	page.add_child(button)
	if numbered:
		buttons.append(button)
	return button

func _actions(actions: Array, top := 478.0, available_width := 952.0) -> void:
	var columns := 1 if actions.size() <= 3 else 2
	var width := available_width if columns == 1 else 470.0
	for i in actions.size():
		var entry: Array = actions[i]
		_button(Rect2(296 + (i % columns) * 482, top + (i / columns) * 57, width, 50), entry[0], entry[1], actions.size() == 1, true, 16)

func _portrait(who: String, rect: Rect2) -> void:
	if cast == null or not D.CAST_REGIONS.has(who):
		return
	var portrait := TextureRect.new()
	var region := AtlasTexture.new()
	region.atlas = cast
	region.region = D.CAST_REGIONS[who]
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = region
	portrait.position = rect.position
	portrait.size = rect.size
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(portrait)

func _picture(texture: Texture2D, rect: Rect2) -> void:
	if texture == null:
		return
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.texture = texture
	picture.position = rect.position
	picture.size = rect.size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(picture)

func _scroll_text(rect: Rect2, text: String, size := 18, color := INK) -> void:
	var scroll := ScrollContainer.new()
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	scroll_targets.append(scroll)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	scroll.add_child(label)

func _bar(rect: Rect2, maximum: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.max_value = maximum
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color("#d5d0c7"), Color("#b7b1ba")))
	bar.add_theme_stylebox_override("fill", _style(ACCENT, ACCENT))
	page.add_child(bar)
	return bar

func _time(value: int) -> String:
	return "%02d:%02d" % [floori(value / 60.0), value % 60]

func _header() -> void:
	_label(Rect2(32, 14, 600, 39), D.TITLE, 30, PAPER)
	_label(Rect2(32, 56, 600, 29), "Поликлиника № 404   ·   2044 год", 15, Color("#c2d3cc"))
	_label(Rect2(645, 18, 310, 33), "Готовность помочь: %d/10" % relationship, 20, PAPER)
	_label(Rect2(1060, 10, 185, 45), _time(clock), 33, PAPER).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(Rect2(946, 57, 300, 29), "Врач до 10:20   ·   регистратура до 11:00", 13, Color("#c2d3cc"))

func _footer() -> void:
	_button(Rect2(32, 651, 217, 30), "К сериалу" if stage in ["look", "records", "formal_confirm"] or _in_options_menu() else "К сериалу   Esc", func(): leave_requested.emit(), false, false, 14)

func _nika() -> void:
	_panel(Rect2(32, 118, 238, 347), Color("#243b3b"), Color("#829996"))
	_portrait("НИКА", Rect2(42, 128, 218, 270))
	_label(Rect2(50, 404, 202, 37), "Ника", 25, PAPER)
	_label(Rect2(50, 438, 202, 24), "Температура 38,2 °C", 15, GOLD)

func _main_panel(kicker: String, title: String) -> void:
	_panel(Rect2(296, 118, 952, 347))
	_label(Rect2(320, 140, 902, 27), kicker.to_upper(), 15, MUTED)
	_label(Rect2(318, 174, 902, 74), title, 31)

func _notes_text() -> String:
	var notes := PackedStringArray()
	for clue in clues.values():
		notes.append("- " + str(clue))
	return "\n\n".join(notes) if not notes.is_empty() else "Пока нет заметок."

func _render() -> void:
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	buttons.clear()
	scroll_targets.clear()
	touch_scroll = null
	touch_finger = -1
	queue_redraw()
	_header()
	_footer()
	if stage in ["ending_banner", "ending"]:
		_ending_page()
		return
	if stage == "look":
		_look_page()
		return
	if stage == "docs":
		_docs_page()
		return
	if stage in ["listen_talk", "listen_pause"]:
		_listen_page()
		return
	if stage == "carousel":
		_label(Rect2(32, 132, 1216, 43), "Бумажные талоны. Поймайте «БК, без карты» в рамке", 28, PAPER)
		_label(Rect2(110, 184, 1060, 50), "Пробел, 1 или клик в барабане. Ошибка: +3 минуты и готовность помочь минус 1.", 19, GOLD)
		_button(Rect2(412, 506, 456, 60), "Поймать талон   ·   Пробел / 1", _grab_ticket, true, false, 21)
		return
	_nika()
	match stage:
		"title":
			_main_panel("Серия 5  /  Права новых форм жизни", "В регистратуре нет графы «существует».")
			_label(Rect2(320, 258, 898, 194), D.INTRO[title_page], 21)
			_actions([["Дальше" if title_page < D.INTRO.size() - 1 else "Войти в поликлинику   ·   09:20", _next_title]])
		"dialogue": _dialogue_page()
		"terminal":
			_main_panel("Терминал записи", "Выберите категорию для записи")
			_label(Rect2(320, 272, 882, 144), "Любая категория ведёт к регистратуре. Каждая попытка занимает 2 минуты.", 23)
			_actions(_stage_actions("terminal"))
		"window":
			_main_panel("Марина Петровна", "Как начать разговор?")
			_label(Rect2(320, 268, 880, 141), "Ника уже назвала своё имя и симптомы. Вы сопровождаете её и можете попросить помощь или дать ей самой объяснить.", 23)
			_actions(_stage_actions("window"))
		"hub": _hub_page()
		"options": _options_page()
		"records":
			_main_panel("При себе", "Документы и заметки")
			_scroll_text(Rect2(320, 257, 890, 187), "\n".join(PackedStringArray(items)) + "\n\nЗАМЕТКИ\n" + _notes_text() + "\n\nДоговор находится у сопровождающего. Ника принимает решения о себе сама.", 17)
			_actions([["Вернуться", func(): _change(return_stage)]])
		"docs_ready":
			_main_panel("Найти документ", "Один верный акт среди десяти")
			_label(Rect2(320, 252, 886, 113), "ТРЕБУЕТСЯ: " + D.DOCS_RULE, 23, ACCENT)
			_label(Rect2(320, 365, 886, 81), "Таймер начнётся после нажатия. 60 секунд, ошибка отнимает 8 секунд. Неверная карточка выбывает. Поиск займёт от 3 до 8 игровых минут.", 18)
			_actions([["Начать поиск   ·   60 секунд", _docs_begin]])
		"listen_ready":
			_main_panel("Объяснение Марины Петровны", "Выслушать и узнать обход")
			_label(Rect2(320, 253, 880, 174), "Читайте каждый фрагмент без спешки. Enter или «Продолжить слушать» открывает паузу на 1,8 секунды. В паузе кивните Пробелом, 1 или кнопкой.\n\nНужно 3 кивка из 4 и не больше 1 перебивания. После любого результата маршрут останется доступным.", 21)
			_actions([["Начать слушать   ·   10 мин", _listen_begin]])
		"carousel_ready":
			_main_panel("Резервный маршрут", "Барабан из восьми талонов")
			_label(Rect2(320, 253, 880, 171), "Нужен талон «БК, без карты». Ловите его в центральной рамке Пробелом, 1 или кликом.\n\nКарусель стоит 5 минут. Ошибка добавляет 3 минуты и снижает готовность на 1. Неверный талон исчезнет, БК всегда останется.", 22)
			_actions([["К барабану   ·   5 мин", _carousel_begin]])
		"final": _final_page()
		"formal_confirm":
			_main_panel("Бумажный результат", "Подать обращение в комиссию?")
			_label(Rect2(320, 254, 886, 160), "Будет зарегистрировано обращение. Ответ придёт в течение 30 рабочих дней. Сегодня Ника не попадёт на приём по этому маршруту.\n\nОформление занимает 5 минут и завершает историю.", 22)
			_actions([["Подать обращение   ·   5 мин", _confirm_formal], ["Вернуться к поиску врача", func(): _change("final" if flags["has_reserve_ticket"] else "hub")]])
		"walk":
			_main_panel("Временная запись выдана", "Дойти до кабинета врача")
			_label(Rect2(320, 254, 886, 151), "До кабинета 4 минуты. Прибудете в %s. Приём без записи заканчивается в 10:20.\n\nЧтение этих реплик не сдвигает время прибытия." % _time(referral_arrival), 23)
			_actions([["К кабинету   ·   4 мин", _go_doctor]])
		"doctor":
			_main_panel("Первичный осмотр", "Врач ждёт ответа")
			_label(Rect2(320, 263, 886, 150), "Документы довели Нику до кабинета. Теперь важны её симптомы.", 24)
			_actions(_stage_actions("doctor"))

func _dialogue_page() -> void:
	var beat: Array = dialogue[dialogue_index]
	var who: String = beat[0]
	_panel(Rect2(296, 118, 952, 347))
	_label(Rect2(320, 139, 880, 26), dialogue_heading, 15, MUTED)
	_label(Rect2(320, 175, 880, 43), D.SPEAKERS.get(who, who), 25, ACCENT if who != "НИКА" else Color("#35675b"))
	var with_portrait: bool = who in ["МП", "ТРИТОН", "ВРАЧ"]
	if with_portrait:
		_portrait(who, Rect2(1040, 192, 180, 255))
	_label(Rect2(320, 232, 694 if with_portrait else 895, 216), beat[1], 22, MUTED if who == "СИС" else INK)
	if dialogue_index == dialogue.size() - 1 and dialogue_next in DIALOGUE_CHOICES:
		var choices := _stage_actions(dialogue_next)
		var wrapped: Array = []
		for choice in choices:
			wrapped.append([choice[0], _reply_from_dialogue.bind(dialogue_next, choice[1])])
		var width := 694.0 if with_portrait else 895.0
		var text_height := ThemeDB.fallback_font.get_multiline_string_size(beat[1], HORIZONTAL_ALIGNMENT_LEFT, width, 22).y
		var top := maxf(312.0, 252.0 + text_height)
		if dialogue_next == "hub":
			_label(Rect2(320, top, 895, 54), "До врача нужны акт сбоя, бумажный обход и талон БК. Выберите, с чего начать.", 17, MUTED)
			top += 67.0
		elif dialogue_next == "final":
			var projection := _referral_projection()
			var setup := "Оформление 6 мин." if relationship >= D.RELATIONSHIP_HIGH else "Оформление 6 мин и 8 мин сверки из-за готовности ниже 7."
			var warning := "Успеваете до 10:20."
			if projection["kind"] == "late":
				warning = "Врач успеет уехать."
			elif projection["kind"] == "burnout":
				warning = "Регистратура закроется в 11:00, запись не будет выдана."
			_label(Rect2(320, top, 895, 84), "%s Дорога 4 мин. Прибытие в %s. %s" % [setup, _time(projection["arrival"]), warning], 18, ACCENT)
			top += 97.0
		if with_portrait and choices.size() > 3:
			top = 478.0
		_actions(wrapped, minf(top, 478.0), 716.0 if with_portrait else 952.0)
		_label(Rect2(320, 652, 690, 29), "Выберите ответ: цифры 1-%d или клик." % choices.size(), 16, GOLD)
	else:
		_actions([["К регистратуре" if dialogue_next == "window_intro" and dialogue_index == dialogue.size() - 1 else "Дальше   ·   Enter / Пробел", _next_dialogue]])

func _reply_from_dialogue(next: String, action: Callable) -> void:
	if stage != "dialogue" or dialogue_index != dialogue.size() - 1 or dialogue_next != next:
		return
	stage = next
	action.call()

func _stage_actions(choice_stage: String) -> Array:
	match choice_stage:
		"terminal":
			return [["Человек   ·   2 мин", _terminal.bind(0)], ["Животное   ·   2 мин", _terminal.bind(1)], ["Другое   ·   2 мин", _terminal.bind(2)]]
		"window":
			return [
				["Она пришла к врачу. Подскажите, что можно сделать?\n2 мин · готовность помочь +1", _window.bind(0)],
				["Вы обязаны её принять, это дискриминация!\n1 мин + 5 мин ожидания · готовность минус 1", _window.bind(1)],
				["Пусть Ника сама объяснит.\n2 мин · готовность помочь +1", _window.bind(2)],
			]
		"doctor":
			return [["Передать талон", _doctor_choice.bind(0)], ["Попросить Нику самой рассказать о симптомах", _doctor_choice.bind(1)]]
		"hub":
			var main := "Попросить талон без полиса\n3 мин · затем поиск акта"
			if flags["has_refusal_act"]:
				main = "Спросить про обход системы\n10 мин · выслушать Марину Петровну"
			if flags["listened"]:
				main = "Найти резервный талон\n5 мин · бумажный барабан"
			return [
				[main, _hub_action.bind("request")],
				["Осмотреть зал\n1 мин за новый предмет", _hub_action.bind("look")],
				["Вопросы и звонки\nСтраховая, ветслужба, Тритон", _hub_action.bind("options")],
				["Попросить временную запись раньше\n2 мин · сотрудница назовёт, чего не хватает", _hub_action.bind("early")],
				["Подать обращение в комиссию\n5 мин · ответ через 30 рабочих дней", _hub_action.bind("formal")],
				["Ждать\n5 мин", _hub_action.bind("wait")],
			]
		"options":
			var options: Array = []
			if not flags["showed_act"]:
				options.append(["Показать акт выращивания   ·   3 мин", _hub_action.bind("show_act")])
			if not flags["called_insurance"]:
				options.append(["Позвонить в страховую   ·   5 мин", _hub_action.bind("insurance")])
			if not flags["called_vet"]:
				options.append(["Позвонить в ветслужбу   ·   7 мин", _hub_action.bind("vet")])
			if not flags["talked_triton"]:
				options.append(["Поговорить с господином Тритоном   ·   2 мин", _hub_action.bind("triton")])
			options.append(["Документы и заметки", _hub_action.bind("records")])
			options.append(["Вернуться к окну", _hub_action.bind("back")])
			return options
		"final":
			var projection := _referral_projection()
			return [
				["Оформить запись и идти к врачу\n%d мин на запись + 4 мин дороги" % projection["cost"], _hub_action.bind("referral")],
				["Требовать официальное разъяснение\n5 мин · ответ через 30 рабочих дней", _hub_action.bind("formal")],
				["Осмотреть зал", _hub_action.bind("look")],
				["Вопросы и звонки", _hub_action.bind("options")],
				["Документы и заметки", _hub_action.bind("records")],
				["Ждать   ·   5 мин", _hub_action.bind("wait")],
			]
	return []

func _hub_page() -> void:
	_main_panel("Зал ожидания", "Все документы при вас. Документов нет.")
	_label(Rect2(320, 260, 880, 89), "Чтобы попасть к врачу, оформите ошибку регистрации, узнайте бумажный обход и получите талон без карты.", 23)
	var progress := [
		["Акт сбоя", flags["has_refusal_act"]],
		["Обход", flags["listened"]],
		["Талон БК", flags["has_reserve_ticket"]],
		["Запись", flags["has_temp_referral"]],
	]
	for i in progress.size():
		_label(Rect2(320 + i * 221, 374, 204, 66), progress[i][0] + "\n" + ("есть" if progress[i][1] else "нужен"), 20, ACCENT if progress[i][1] else MUTED)
	_actions(_stage_actions("hub"))

func _options_page() -> void:
	_main_panel("Зал ожидания", "Вопросы и звонки")
	_label(Rect2(320, 257, 886, 150), "Можно проверить обходные пути и узнать, что происходило с другими посетителями. Эти действия необязательны, время до ухода врача общее.", 23)
	_actions(_stage_actions("options"))

func _final_page() -> void:
	_main_panel("Последнее окно", "Оформить временную запись")
	var projection := _referral_projection()
	var extra := "Дополнительная сверка не требуется." if relationship >= D.RELATIONSHIP_HIGH else "Готовность ниже 7: дополнительная сверка займёт 8 минут."
	var outcome := "Успеваете к дежурному врачу." if projection["kind"] == "human" else ("Врач уже успеет уехать." if projection["kind"] == "late" else "Регистратура закроется раньше выдачи.")
	_label(Rect2(320, 252, 890, 181), "Акт невозможности и талон БК получены.\n%s\nОформление: %d мин. До кабинета ещё 4 мин.\nВыдача в %s, прибытие в %s. %s" % [extra, projection["cost"], _time(projection["issued"]), _time(projection["arrival"]), outcome], 21)
	_actions(_stage_actions("final"))

func _look_page() -> void:
	_panel(Rect2(32, 488, 735, 153))
	_label(Rect2(50, 502, 700, 122), look_text, 19)
	_panel(Rect2(790, 488, 458, 153))
	_label(Rect2(808, 500, 420, 28), "ЗАМЕТКИ", 16, ACCENT)
	_scroll_text(Rect2(808, 532, 420, 97), _notes_text(), 16)
	_button(Rect2(790, 651, 220, 30), "К разговору   ·   Esc", func(): _change(return_stage), true, false, 14)

func _docs_page() -> void:
	_panel(Rect2(32, 112, 1216, 533))
	_label(Rect2(50, 128, 1170, 35), "ТРЕБУЕТСЯ: " + D.DOCS_RULE, 21, ACCENT)
	timer_label = _label(Rect2(52, 169, 250, 30), "Осталось %d с" % ceili(D.DOCS_TIME - _docs_spent()), 21)
	countdown = _bar(Rect2(310, 175, 901, 11), D.DOCS_TIME)
	countdown.value = D.DOCS_TIME - _docs_spent()
	for i in docs_cards.size():
		var card: Dictionary = docs_cards[i]
		var spec: Array = card["spec"]
		var prefix := "%d" % (i + 1) if i < 9 else "0"
		var words := "%s   %s\n%d   ·   %s%s" % [prefix, spec[0], spec[1], spec[2], "   ·   НЕ ПОДХОДИТ" if card["wrong"] else ""]
		var button := _button(Rect2(51 + (i % 2) * 596, 217 + (i / 2) * 70, 580, 62), words, _pick_doc.bind(i), false, false, 16)
		button.disabled = card["wrong"]
	_label(Rect2(52, 575, 1160, 58), docs_feedback if docs_feedback != "" else "Клик по бланку или клавиши 1–9, 0. Неверный бланк отнимает 8 секунд.", 18, MUTED)

func _listen_page() -> void:
	_nika()
	_main_panel("Марина Петровна  /  Фрагмент %d из 5" % (listen_i + 1), "Послушать, как работает обход")
	_portrait("МП", Rect2(1057, 251, 160, 195))
	_label(Rect2(320, 253, 708, 114), D.LISTEN_CHUNKS[listen_i], 23)
	activity_label = _label(Rect2(320, 377, 708, 65), listen_feedback if listen_feedback != "" else "Пока читаете, пауза не идёт. Продолжить слушать — Enter.", 19, MUTED)
	if stage == "listen_pause":
		timer_label = _label(Rect2(320, 484, 615, 41), "Пауза: %.1f с" % listen_pause_left, 23, PAPER)
		countdown = _bar(Rect2(320, 537, 895, 18), D.LISTEN_PAUSE)
		countdown.value = listen_pause_left
		_button(Rect2(320, 582, 895, 50), "Кивнуть   ·   Пробел / 1", _nod, true, false, 21).action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	else:
		_button(Rect2(320, 490, 895, 53), "Дослушать" if listen_i == 4 else "Продолжить слушать   ·   Enter", _listen_continue, true, false, 21)
		_button(Rect2(320, 568, 895, 50), "Кивнуть   ·   Пробел / 1", _nod, false, false, 20).action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	listen_status = _label(Rect2(320, 652, 690, 29), "Вовремя: %d/4   ·   перебивания: %d" % [listen_good_count, listen_interrupts], 16, GOLD)

func _ending_page() -> void:
	var info: Dictionary = D.ENDINGS[ending]
	var tint := GOOD if ending == "human" else BAD
	_panel(Rect2(32, 118, 560, 322), Color("#243b3b"))
	_picture(ending_art.get(ending), Rect2(35, 121, 554, 316))
	_panel(Rect2(620, 118, 628, 491))
	_label(Rect2(644, 135, 578, 80), info["title"], 28, ACCENT)
	_label(Rect2(644, 224, 578, 62), info["banner"], 18, Color("#386c50") if ending == "human" else Color("#974c48"))
	_label(Rect2(644, 300, 578, 69), info["sub"], 19)
	_label(Rect2(644, 379, 578, 36), "Время: %s   ·   Готовность помочь: %d/10" % [_time(clock), relationship], 19)
	_scroll_text(Rect2(644, 428, 578, 158), "\n".join(PackedStringArray(items)), 16)
	_label(Rect2(34, 465, 554, 39), "Выбранный путь", 19, GOLD)
	_scroll_text(Rect2(34, 510, 554, 95), " / ".join(PackedStringArray(route)), 17, PAPER)
	_label(Rect2(32, 615, 1216, 29), "Приз: " + info["prize"], 18, tint)
	if stage == "ending_banner":
		_button(Rect2(620, 650, 628, 32), "Что произошло", _ending_scene, true, true, 18)
	else:
		_button(Rect2(620, 650, 628, 32), "Переиграть", _start, true, true, 18)
