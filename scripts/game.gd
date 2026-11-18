extends Control
## «Крестная мать организации» — уровень в бухгалтерии.
## Нужно за час с небольшим получить справку о доходах у Любови Генриховны (ЛГ).
## Каждое действие стоит минут, на экране часы и шкала «Уважение ЛГ».
## Умасливание — ритуал, а не платёж: шоколадка работает только после 1С и чая.
## Данные бухгалтерии лежат в scripts/rounds_data.gd.
## Школьная серия использует scripts/school_day.gd и scripts/school_data.gd.

const Data = preload("res://scripts/rounds_data.gd")
const SchoolDay = preload("res://scripts/school_day.gd")

const PANEL := Rect2(300, 136, 930, 396)
const PORTRAIT_BOX := Rect2(36, 130, 243, 300)   # подложка и место портрета ЛГ
const INV := Rect2(36, 438, 243, 100)            # сетка иконок «карманы»
const ICON := 44.0
const ART := "res://assets/art/"
const PORTRAIT_FILES := {
	"down": "portraits/lg_down.png", "neutral": "portraits/lg_neutral.png",
	"angry": "portraits/lg_angry.png", "happy": "portraits/lg_happy.png",
	"melt": "portraits/lg_melt.png", "whisper": "portraits/lg_whisper.png",
}
const ENDING_FILES := {
	"human": "endings/ending_human.png", "formal": "endings/ending_formal.png",
	"late": "endings/ending_bank_closed.png", "burnout": "endings/ending_burnout.png",
}
const ITEM_FILES := {
	"choc": "items/item_choc.png", "passport": "items/item_passport.png",
	"pass": "items/item_pass.png", "mug": "items/item_mug_empty.png",
	"doc_2025": "items/doc_2025.png", "doc_2026": "items/doc_2026.png",
	"doc_stamped": "items/doc_stamped.png", "doc_copy": "items/doc_copy.png",
}
const BACKGROUND_FILE := "backgrounds/accounting_office.png"
const MENU_X := 50.0
const MENU_Y := 548.0
const MENU_W := 1180.0
const BTN_H := 46.0
const TEA_SPACING := 150.0
const LOOK_BACK_RECT := Rect2(960, 652, 270, 40)
const LOOK_CAPTION := Rect2(50, 548, 560, 152)
const LOOK_NOTES := Rect2(626, 548, 320, 152)
const BTN_GAP_X := 20.0
const BTN_GAP_Y := 6.0

const IDLE_LIMIT := 25.0     # секунд молчания реального времени = один [ЖДАТЬ]
const TYPE_SPEED := 75.0     # символов в секунду
const CLOCK_SPEED := 30.0    # минут в секунду, как бегут часы
const KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9]

const BG := Color("#1d2a2b")
const BG_LINE := Color("#243436")
const HEADER := Color("#14201f")
const PAPER := Color("#f5ecd5")
const INK := Color("#1b1f2a")
const GOOD := Color("#7fe3a1")
const BAD := Color("#ff8a80")
const GOLD := Color("#ffd479")
const MUTED := Color("#9db3b0")
const YOU := Color("#8ec8ff")
const SKIN := Color("#f1c9a5")

var phase := "menu"           # menu / title / play / end / school
var school: SchoolDay
var menu_sel := 1             # выбранная карточка серии
var menu_toast := ""
var menu_toast_t := 0.0
var episode := 1              # открытая серия
var step := "enter"           # enter / request / hub / docs / tea
var looking := false           # открыт режим «осмотреться»
var seen: Dictionary = {}      # осмотренные предметы
var clues: Dictionary = {}     # найденные улики
var look_text := ""
# карусель с чаем
var tea_pending := false
var tea_delay := 0.0
var tea_active := false
var tea_offset := 0.0
var tea_bags: Array = []       # пакетики, которые ещё крутятся
# минутная игра «найти нужную справку»
var docs_pending := false
var docs_delay := 0.0
var docs_active := false
var docs_cards: Array[Dictionary] = []
var docs_t := 0.0
var docs_wrongs := 0
var docs_msg := ""
var docs_msg_t := 0.0
# слушание рассказа про 1С
var listen_pending := false
var listen_delay := 0.0
var listen_active := false
var listen_i := 0
var listen_state := "talk"     # talk / pause
var listen_t := 0.0
var listen_nodded := false
var listen_interrupted := false
var listen_good := 0
var listen_interrupts := 0
var ending := ""
var end_t := 0.0

var clock := Data.CLOCK_START
var clock_shown := float(Data.CLOCK_START)
var respect := Data.RESPECT_START
var respect_shown := float(Data.RESPECT_START)
var mood := "down"

var has_choc := true
var mug := "empty"            # empty / given
var docs: Array[String] = []
var did_c1 := false
var did_tea := false
var did_year := false
var idle_said := false
var deadline_noted := false
var actions := 0

var log: Array[Dictionary] = []
var queue: Array[Dictionary] = []
var pending_end := ""
var menu: Array[Dictionary] = []
var idle_t := 0.0
var calc_t := 0.3
var popups: Array[Dictionary] = []

var font: Font
var box_style := StyleBoxFlat.new()
var bar_style := StyleBoxFlat.new()
var tones: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var portraits: Dictionary = {}
var endings_art: Dictionary = {}
var items_art: Dictionary = {}
var background: Texture2D


func _ready() -> void:
	font = ThemeDB.fallback_font
	# картинки необязательны: нет файла, рисуем кодом
	background = _load_tex(BACKGROUND_FILE)
	for key in PORTRAIT_FILES:
		portraits[key] = _load_tex(str(PORTRAIT_FILES[key]))
	for key in ENDING_FILES:
		endings_art[key] = _load_tex(str(ENDING_FILES[key]))
	for key in ITEM_FILES:
		items_art[key] = _load_tex(str(ITEM_FILES[key]))
	box_style.set_corner_radius_all(8)
	box_style.set_border_width_all(2)
	bar_style.set_corner_radius_all(6)
	for i in 3:
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		players.append(player)
	tones = {
		"up": _make_tone([660.0, 880.0], 0.16),
		"down": _make_tone([220.0, 170.0], 0.22),
		"win": _make_tone([523.0, 659.0, 784.0, 1046.0], 0.5),
		"late": _make_tone([523.0, 440.0, 349.0], 0.5),
		"lose": _make_tone([330.0, 262.0, 196.0], 0.6),
		"click": _make_click(),
		"school_bell": _make_tone([880.0, 1318.5, 1760.0], 0.36),
		"school_door": _make_melody([262.0, 294.0, 246.9], 0.10),
		"school_chair": _make_melody([196.0, 208.0, 185.0], 0.08),
		"school_ruler": _make_click(),
		"school_whistle": _make_tone([1760.0, 2070.0], 0.22),
		"wait": _make_melody([523.0, 659.0, 784.0, 659.0, 523.0, 659.0, 784.0, 880.0], 0.28),
	}


func _load_tex(file: String) -> Texture2D:
	var path := ART + file
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _start() -> void:
	phase = "play"
	step = "enter"
	ending = ""
	pending_end = ""
	clock = Data.CLOCK_START
	clock_shown = float(clock)
	respect = Data.RESPECT_START
	respect_shown = float(respect)
	mood = "down"
	has_choc = true
	mug = "empty"
	docs.clear()
	did_c1 = false
	did_tea = false
	did_year = false
	idle_said = false
	deadline_noted = false
	actions = 0
	looking = false
	seen.clear()
	clues.clear()
	look_text = ""
	tea_bags = Data.TEA_BAGS.duplicate()
	tea_pending = false
	tea_active = false
	docs_pending = false
	docs_active = false
	listen_pending = false
	listen_active = false
	log.clear()
	queue.clear()
	popups.clear()
	idle_t = 0.0
	calc_t = 0.3
	_queue([["СИС", Data.SYS_CALC], Data.ENTER_LG])
	_flush()
	_build_menu()


# ---------------------------------------------------------------- диалог

func _queue(beats: Array) -> void:
	for b in beats:
		var beat: Array = b
		queue.append({
			"who": str(beat[0]), "text": str(beat[1]),
			"mood": str(beat[2]) if beat.size() > 2 else "", "chars": 0.0,
		})


func _flush() -> void:
	if not _typing():
		_push_next()


func _push_next() -> void:
	if queue.is_empty():
		return
	var beat: Dictionary = queue.pop_front()
	if str(beat["mood"]) != "":
		mood = str(beat["mood"])
	log.append(beat)
	if log.size() > 40:
		log.pop_front()


func _typing() -> bool:
	if log.is_empty():
		return false
	var last: Dictionary = log.back()
	return float(last["chars"]) < float(str(last["text"]).length())


func _busy() -> bool:
	return _typing() or not queue.is_empty() or listen_active or listen_pending 		or tea_active or tea_pending or docs_active or docs_pending


func _advance() -> void:
	if listen_active:
		_nod()
		return
	if tea_active:
		_grab_tea()
		return
	if docs_active:
		return
	if _typing():
		log.back()["chars"] = 99999.0
	elif not queue.is_empty():
		_push_next()
	elif pending_end != "":
		_finish(pending_end)


func _menu_visible() -> bool:
	return phase == "play" and not _busy() and pending_end == "" and not looking


# ---------------------------------------------------------------- действия

func _c(key: String) -> int:
	return int(Data.COST[key])


func _add_time(minutes: int) -> void:
	clock += minutes
	popups.append({"text": "+%d мин" % minutes, "pos": Vector2(1090, 200), "t": 0.0, "color": GOLD})


func _add_respect(delta: int) -> void:
	if delta == 0:
		return
	respect = clampi(respect + delta, 0, Data.RESPECT_MAX)
	_respect_popup("Уважение %s%d" % ["+" if delta > 0 else "−", absi(delta)], GOOD if delta > 0 else BAD)
	_play("up" if delta > 0 else "down")


func _set_respect_max() -> void:
	respect = Data.RESPECT_MAX
	_respect_popup("Уважение: максимум", GOOD)
	_play("up")


func _respect_popup(text: String, color: Color) -> void:
	popups.append({"text": text, "pos": Vector2(1090, 236), "t": 0.0, "color": color})


func _choose(id: String) -> void:
	if phase != "play" or _busy() or pending_end != "" or looking:
		return
	idle_t = 0.0
	actions += 1
	match id:
		"look": _open_look()
		"enter_a": _enter_a()
		"enter_b": _enter_b()
		"wait": _wait()
		"req": _request()
		"year": _request_year()
		"docs": step = "docs"
		"back": step = "hub"
		"c1": _ask_1c()
		"tea": _tea()
		"choc": _chocolate()
		"stamp": _stamp()
	_check_time()
	_flush()
	_build_menu()


func _enter_a() -> void:
	_queue([Data.ENTER_A_YOU])
	_queue(Data.ENTER_A)
	_add_time(_c("enter_a") + _c("enter_a_wait"))
	_add_respect(int(Data.RESPECT_DELTA["enter_a"]))
	step = "request"


func _enter_b() -> void:
	_queue([Data.ENTER_B_YOU])
	_queue(Data.ENTER_B)
	_add_time(_c("enter_b"))
	_add_respect(int(Data.RESPECT_DELTA["enter_b"]))
	step = "request"


func _wait() -> void:
	if not idle_said:
		idle_said = true
		_queue(Data.ENTER_WAIT if step == "enter" else Data.IDLE_FIRST)
	else:
		_queue(Data.IDLE_NEXT)
		_play("wait")
	_add_time(_c("wait"))


func _request() -> void:
	_queue([Data.REQ_YOU])
	if docs.has("Справка о доходах за 2025"):
		_queue(Data.REQ_REPEAT)
		_add_time(_c("doc_repeat"))
		return
	_queue(Data.REQ)
	_queue(Data.DOCS_INTRO)
	docs_pending = true        # игра со стопкой бланков начнётся после реплик
	docs_delay = 0.6


func _request_year() -> void:
	_queue([Data.REQ_YEAR_YOU])
	if did_year:
		_queue(Data.REQ_REPEAT)
		_add_time(_c("doc_repeat"))
		return
	_queue(Data.REQ_YEAR)
	did_year = true
	docs.append("Справка за 2026 (неполный год)")
	_add_time(_c("doc_2026"))


func _ask_1c() -> void:
	did_c1 = true
	_queue([Data.C1_YOU, Data.C1_INTRO])
	_add_time(_c("ask_1c"))
	mood = "happy"
	listen_pending = true      # слушание начнётся, когда игрок дочитает вступление
	listen_delay = 0.9
	listen_good = 0
	listen_interrupts = 0


# ---------------------------------------------------------------- «кивать вовремя»

func _listen_begin() -> void:
	listen_pending = false
	listen_active = true
	listen_i = -1
	log.append({"who": "ЛГ", "text": "", "mood": "", "chars": 0.0})
	_listen_next_chunk()


func _listen_next_chunk() -> void:
	listen_i += 1
	var chunks: Array = Data.C1_CHUNKS
	var entry: Dictionary = log.back()
	var text := str(entry["text"])
	entry["text"] = (text + " " if text != "" else "") + str(chunks[listen_i])
	listen_state = "talk"
	listen_interrupted = false


func _nod() -> void:
	if listen_state == "pause":
		if not listen_nodded:
			listen_nodded = true
			listen_good += 1
			_note_popup("угу", GOOD)
			_play("up")
	elif not listen_interrupted:
		listen_interrupted = true
		listen_interrupts += 1
		_note_popup("перебили", BAD)
		_play("down")


func _listen_update(delta: float) -> void:
	if listen_state == "talk":
		if _typing():
			return
		if listen_i >= Data.C1_CHUNKS.size() - 1:
			_listen_end()
			return
		listen_state = "pause"
		listen_t = 0.0
		listen_nodded = false
		return
	listen_t += delta
	if listen_nodded and listen_t >= 0.3:
		_listen_next_chunk()
	elif listen_t >= Data.LISTEN_PAUSE:
		if not listen_nodded:
			_note_popup("не кивнули", BAD)
		_listen_next_chunk()


func _listen_end() -> void:
	listen_active = false
	var total := Data.C1_CHUNKS.size() - 1
	var good := listen_good >= Data.LISTEN_NEEDED and listen_interrupts <= Data.LISTEN_MAX_INTERRUPTS
	_queue([Data.C1_OUTRO, ["СИС", (Data.C1_RESULT_GOOD % [listen_good, total]) if good else (Data.C1_RESULT_POOR % [listen_good, total, listen_interrupts])]])
	_add_respect(int(Data.RESPECT_DELTA["ask_1c" if good else "ask_1c_poor"]))
	_check_time()
	_flush()
	_build_menu()


func _note_popup(text: String, color: Color) -> void:
	popups.append({"text": text, "pos": Vector2(420 if looking else 640, 536 if looking else 600), "t": 0.0, "color": color})


# ---------------------------------------------------------------- чай

func _tea() -> void:
	_queue(Data.TEA_KITCHEN)
	_add_time(_c("tea"))
	step = "tea"
	tea_pending = true         # карусель включится, когда игрок дочитает реплики
	tea_delay = 0.6


func _tea_ring() -> float:
	return tea_bags.size() * TEA_SPACING


## Положение пакетика относительно рамки в центре: от -ring/2 до +ring/2.
func _tea_x(i: int) -> float:
	var ring := _tea_ring()
	return wrapf(i * TEA_SPACING - tea_offset + ring * 0.5, 0.0, ring) - ring * 0.5


func _tea_nearest() -> int:
	var best := 0
	for i in tea_bags.size():
		if absf(_tea_x(i)) < absf(_tea_x(best)):
			best = i
	return best


func _grab_tea() -> void:
	if not tea_active:
		return
	tea_active = false
	var bag: Dictionary = tea_bags[_tea_nearest()]
	_queue([["СИС", Data.TEA_BRING % str(bag["name"])]])
	if str(bag["name"]) == Data.TEA_RIGHT:
		did_tea = true
		mug = "given"
		_queue(Data.TEA_OK)
		_add_respect(int(Data.RESPECT_DELTA["tea"]))
		step = "hub"
	else:
		tea_bags.erase(bag)
		_queue([["ЛГ", str(bag["reply"]), "angry"]])
		_add_time(_c("tea_wrong"))
		_add_respect(int(Data.RESPECT_DELTA["tea_wrong"]))
		tea_pending = true     # снова идём на кухню и ловим пакетик
		tea_delay = 0.8
	_check_time()
	_flush()
	_build_menu()


# ---------------------------------------------------------------- справки: найти за минуту

func _docs_begin() -> void:
	popups.clear()
	docs_pending = false
	docs_active = true
	docs_t = 0.0
	docs_wrongs = 0
	docs_msg = ""
	docs_cards = _docs_make_cards()


func _docs_make_cards() -> Array[Dictionary]:
	var ok_t: String = Data.DOC_TITLE_OK
	var ok_y: int = Data.DOC_YEAR_OK
	var ok_s: String = Data.DOC_STATE_OK
	var bad_t: Array = Data.DOC_TITLES_BAD
	var bad_y: Array = Data.DOC_YEARS_BAD
	var bad_s: Array = Data.DOC_STATES_BAD
	var specs: Array = [[ok_t, ok_y, ok_s]]
	for y in bad_y:
		specs.append([ok_t, y, ok_s])                       # отличается только годом
	for t in bad_t:
		specs.append([t, ok_y, ok_s])                       # только названием
	for st in bad_s:
		specs.append([ok_t, ok_y, st])                      # только заполнением
	specs.append([bad_t.pick_random(), bad_y.pick_random(), ok_s])   # название и год
	specs.append([ok_t, bad_y.pick_random(), bad_s.pick_random()])   # год и заполнение
	specs.shuffle()
	var cards: Array[Dictionary] = []
	for spec in specs:
		var reason := ""
		if str(spec[0]) != ok_t:
			reason = "title"
		elif int(spec[1]) != ok_y:
			reason = "year"
		elif str(spec[2]) != ok_s:
			reason = "state"
		cards.append({
			"title": str(spec[0]), "year": int(spec[1]), "state": str(spec[2]),
			"serial": randi_range(100000, 999999), "valid": reason == "", "reason": reason, "bad": false,
		})
	return cards


func _docs_spent() -> float:
	return minf(Data.DOCS_TIME, docs_t + docs_wrongs * Data.DOCS_WRONG_PENALTY)


func _docs_left() -> float:
	return maxf(0.0, Data.DOCS_TIME - _docs_spent())


func _docs_update(delta: float) -> void:
	docs_t += delta
	docs_msg_t += delta
	if _docs_left() <= 0.0:
		_docs_end(false)


func _pick_doc(index: int) -> void:
	if not docs_active or index < 0 or index >= docs_cards.size():
		return
	var card: Dictionary = docs_cards[index]
	if bool(card["bad"]):
		return
	if bool(card["valid"]):
		_docs_end(true)
		return
	card["bad"] = true
	docs_wrongs += 1
	docs_msg = str(Data.DOCS_REASON[str(card["reason"])]) + "  −%d с" % int(Data.DOCS_WRONG_PENALTY)
	docs_msg_t = 0.0
	_play("down")


func _docs_end(success: bool) -> void:
	docs_active = false
	var spent := _docs_spent()
	var minutes := Data.DOCS_BASE_MIN + maxi(1, ceili(spent / 10.0))
	docs.append("Справка о доходах за 2025")
	if success:
		_queue(Data.DOCS_OK_BEATS)
		_queue([["СИС", Data.DOCS_FOUND % [int(round(spent)), minutes]]])
	else:
		_queue(Data.DOCS_TIMEOUT_BEATS)
		_add_respect(-1)
	_add_time(minutes)
	step = "hub"
	_check_time()
	_flush()
	_build_menu()


# ---------------------------------------------------------------- осмотр кабинета

func _open_look() -> void:
	looking = true
	look_text = ""


func _leave_look() -> void:
	looking = false
	_flush()
	_build_menu()


func _inspect(spot: Dictionary) -> void:
	var id := str(spot["id"])
	var text := str(spot["text"]).replace("{time}", _fmt(clock)).replace("{bank}", _fmt(Data.BANK_AT))
	look_text = "%s. %s" % [str(spot["name"]), text]
	if not seen.has(id):
		seen[id] = true
		_add_time(_c("look"))
		if spot.has("clue"):
			clues[str(spot["clue"])] = str(spot["note"])
			_note_popup("заметка добавлена", GOLD)
		_check_time()
		if pending_end != "":
			_leave_look()


func _chocolate() -> void:
	_queue([Data.CHOC_YOU])
	if did_c1 and did_tea:
		has_choc = false
		_queue(Data.CHOC_OK)
		_add_time(_c("choc_ok"))
		_set_respect_max()
	else:
		_queue(Data.CHOC_EARLY)
		_add_time(_c("choc_early"))
		_add_respect(int(Data.RESPECT_DELTA["choc_early"]))


func _stamp() -> void:
	var high := respect >= Data.RESPECT_MAX
	var cost := _c("stamp_talk") + (_c("stamp_ok") if high else _c("stamp_copy"))
	var after := clock + cost
	var kind := "burnout"
	if after < Data.CLOCK_END:
		if high:
			kind = "human" if after <= Data.DEADLINE else "late"
		elif after <= Data.COPY_WINDOW:
			kind = "formal"
	_queue([Data.STAMP_YOU])
	_queue(Data.STAMP_TALK)
	match kind:
		"human", "late":
			_queue(Data.STAMP_HIGH)
			_queue(Data.END_HUMAN_LG if kind == "human" else Data.END_LATE_LG)
			docs.append("Справка о доходах с синей печатью")
		"formal":
			_queue(Data.STAMP_LOW)
			_queue(Data.END_FORMAL_LG)
			docs.append("Копия справки без печати")
		_:
			_queue(Data.END_BURNOUT)
	_add_time(cost)
	if kind == "burnout":
		clock = maxi(clock, Data.CLOCK_END)
	pending_end = kind
	step = "hub"


func _check_time() -> void:
	if pending_end != "":
		return
	if clock >= Data.CLOCK_END:
		_queue(Data.END_BURNOUT)
		pending_end = "burnout"
	elif clock > Data.DEADLINE and not deadline_noted:
		deadline_noted = true
		_queue([Data.DEADLINE_PASSED])


func _finish(kind: String) -> void:
	phase = "end"
	ending = kind
	end_t = 0.0
	menu.clear()
	popups.clear()
	_play("win" if kind == "human" else ("late" if kind == "late" or kind == "formal" else "lose"))


func _build_menu() -> void:
	menu.clear()
	match step:
		"enter":
			menu.append({"id": "enter_a", "label": "«%s»" % Data.ENTER_A_YOU[1]})
			menu.append({"id": "enter_b", "label": "«%s»" % Data.ENTER_B_YOU[1]})
			menu.append({"id": "wait", "label": Data.MENU["wait"]})
			menu.append({"id": "look", "label": Data.MENU["look"]})
		"request":
			menu.append({"id": "req", "label": "«%s»" % Data.REQ_YOU[1]})
			menu.append({"id": "wait", "label": Data.MENU["wait"]})
			menu.append({"id": "look", "label": Data.MENU["look"]})
		"docs":
			menu.append({"id": "req", "label": "«%s»" % Data.REQ_YOU[1]})
			menu.append({"id": "year", "label": "«%s»" % Data.REQ_YEAR_YOU[1]})
			menu.append({"id": "back", "label": Data.MENU["back"]})
		"hub":
			menu.append({"id": "docs", "label": Data.MENU["docs"]})
			if not did_c1:
				menu.append({"id": "c1", "label": Data.MENU["c1"]})
			if mug == "empty":
				menu.append({"id": "tea", "label": Data.MENU["tea"]})
			if has_choc:
				menu.append({"id": "choc", "label": Data.MENU["choc"]})
			menu.append({"id": "stamp", "label": Data.MENU["stamp"]})
			menu.append({"id": "wait", "label": Data.MENU["wait"]})
			menu.append({"id": "look", "label": Data.MENU["look"]})


func _tier(value: float) -> String:
	for t in Data.RESPECT_TIERS:
		if value >= float(t[0]) - 0.001:
			return str(t[1])
	return str(Data.RESPECT_TIERS.back()[1])


func _fmt(minutes: int) -> String:
	return "%d:%02d" % [minutes / 60, minutes % 60]


# ---------------------------------------------------------------- ход времени

func _process(delta: float) -> void:
	if phase == "school":
		return
	menu_toast_t = maxf(0.0, menu_toast_t - delta)
	clock_shown = move_toward(clock_shown, float(mini(clock, Data.CLOCK_END)), delta * CLOCK_SPEED)
	respect_shown = move_toward(respect_shown, float(respect), delta * 6.0)
	for p in popups:
		p["t"] = float(p["t"]) + delta
	popups = popups.filter(func(p: Dictionary) -> bool: return float(p["t"]) < 1.5)
	if phase == "end":
		end_t += delta
	if phase == "play":
		if step == "enter":
			calc_t -= delta
			if calc_t <= 0.0:
				calc_t = randf_range(0.12, 0.42)
				_play("click")
		if _typing():
			log.back()["chars"] = float(log.back()["chars"]) + delta * TYPE_SPEED
		if listen_pending and not _typing() and queue.is_empty():
			listen_delay -= delta
			if listen_delay <= 0.0:
				_listen_begin()
		if listen_active:
			_listen_update(delta)
		if tea_pending and not _typing() and queue.is_empty():
			tea_delay -= delta
			if tea_delay <= 0.0:
				tea_pending = false
				tea_active = true
				tea_offset = randf() * _tea_ring()
		if tea_active:
			tea_offset += Data.TEA_SPEED * delta
		if docs_pending and not _typing() and queue.is_empty():
			docs_delay -= delta
			if docs_delay <= 0.0:
				_docs_begin()
		if docs_active:
			_docs_update(delta)
		if _menu_visible():
			idle_t += delta
			if idle_t >= IDLE_LIMIT:
				_choose("wait")
		else:
			idle_t = 0.0
	queue_redraw()


# ---------------------------------------------------------------- ввод

func _input(event: InputEvent) -> void:
	if phase == "school":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.keycode
		if code == KEY_ESCAPE:
			if looking:
				_leave_look()
			elif phase == "menu":
				get_tree().quit()
			else:
				_to_menu()
			return
		if phase == "play":
			var index := KEYS.find(code)
			if looking:
				if code == KEY_SPACE or code == KEY_ENTER or code == KEY_BACKSPACE or code == KEY_TAB:
					_leave_look()
			elif docs_active:
				if code == KEY_0:
					_pick_doc(9)
				elif index >= 0:
					_pick_doc(index)
			elif index >= 0 and _menu_visible():
				if index < menu.size():
					_choose(str(menu[index]["id"]))
			elif index == 0 and listen_active:
				_nod()
			elif index == 0 and tea_active:
				_grab_tea()
			elif code == KEY_SPACE or code == KEY_ENTER:
				_advance()
		elif phase == "menu":
			_menu_key(code)
		elif code == KEY_SPACE or code == KEY_ENTER:
			_press_start()
	elif event is InputEventMouseMotion and phase == "menu":
		var hover := _episode_at(event.position)
		if hover >= 0:
			menu_sel = hover
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if phase == "menu":
			var hit := _episode_at(event.position)
			if hit >= 0:
				menu_sel = hit
				_open_episode(hit)
			return
		if phase == "play":
			if looking:
				if LOOK_BACK_RECT.has_point(event.position):
					_leave_look()
					return
				for spot in Data.HOTSPOTS:
					if (spot["rect"] as Rect2).has_point(event.position):
						_inspect(spot)
						return
			elif docs_active:
				for i in docs_cards.size():
					if _doc_rect(i).has_point(event.position):
						_pick_doc(i)
						return
			elif _menu_visible():
				for i in menu.size():
					if _button_rect(i).has_point(event.position):
						_choose(str(menu[i]["id"]))
						return
			else:
				_advance()
		else:
			_press_start()


func _to_menu() -> void:
	if is_instance_valid(school):
		school.set_process(false)
		school.set_process_input(false)
		school.set_process_unhandled_input(false)
		school.hide()
		school.queue_free()
		school = null
	for player in players:
		player.stop()
	phase = "menu"
	looking = false
	listen_active = false
	listen_pending = false
	tea_active = false
	tea_pending = false
	docs_active = false
	docs_pending = false
	popups.clear()


func _ep_rect(i: int) -> Rect2:
	return Rect2(60.0 + (i % 3) * 400.0, 200.0 + (i / 3) * 232.0, 360.0, 202.0)


func _episode_at(pos: Vector2) -> int:
	for i in Data.EPISODES.size():
		if _ep_rect(i).has_point(pos):
			return i
	return -1


func _menu_key(code: int) -> void:
	var count: int = Data.EPISODES.size()
	match code:
		KEY_LEFT: menu_sel = (menu_sel + count - 1) % count
		KEY_RIGHT: menu_sel = (menu_sel + 1) % count
		KEY_UP: menu_sel = (menu_sel + count - 3) % count
		KEY_DOWN: menu_sel = (menu_sel + 3) % count
		KEY_ENTER, KEY_SPACE: _open_episode(menu_sel)


func _open_episode(i: int) -> void:
	if bool(Data.EPISODES[i]["open"]):
		episode = i
		if Data.EPISODES[i].get("mode", "") == "school":
			phase = "school"
			school = SchoolDay.new()
			school.leave_requested.connect(_to_menu)
			school.sound_requested.connect(_play)
			add_child(school)
			get_viewport().set_input_as_handled()
			queue_redraw()
		else:
			phase = "title"
		_play("up")
	else:
		menu_toast = Data.MENU_LOCKED
		menu_toast_t = 2.2
		_play("down")


func _press_start() -> void:
	if phase == "title" or (phase == "end" and end_t > 0.7):
		_start()


func _menu_cols() -> int:
	return 2 if menu.size() <= 4 else 3


func _button_rect(i: int) -> Rect2:
	var cols := _menu_cols()
	var width := (MENU_W - BTN_GAP_X * (cols - 1)) / cols
	return Rect2(
		MENU_X + (i % cols) * (width + BTN_GAP_X),
		MENU_Y + (i / cols) * (BTN_H + BTN_GAP_Y),
		width, BTN_H)


# ---------------------------------------------------------------- звук

func _make_tone(freqs: Array, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var total := int(rate * duration)
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var part := mini(int(float(i) / total * freqs.size()), freqs.size() - 1)
		var envelope := 1.0 - float(i) / total
		var sample := sin(TAU * float(freqs[part]) * i / rate) * envelope * 0.35
		data.encode_s16(i * 2, int(sample * 32767.0))
	return _wav(data, rate)


func _make_melody(notes: Array, note_len: float) -> AudioStreamWAV:
	var rate := 22050
	var per := int(rate * note_len)
	var data := PackedByteArray()
	data.resize(per * notes.size() * 2)
	for n in notes.size():
		for i in per:
			var envelope := minf(1.0, float(i) / 300.0) * (1.0 - float(i) / per)
			var sample := sin(TAU * float(notes[n]) * i / rate) * envelope * 0.22
			data.encode_s16((n * per + i) * 2, int(sample * 32767.0))
	return _wav(data, rate)


func _make_click() -> AudioStreamWAV:
	# глухой щелчок клавиши калькулятора: низкий «тук» с шумом
	var rate := 22050
	var total := int(rate * 0.07)
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var envelope := exp(-float(i) / total * 7.0)
		var sample := (sin(TAU * 150.0 * i / rate) * 0.7 + randf_range(-1.0, 1.0) * 0.4) * envelope * 0.5
		data.encode_s16(i * 2, int(sample * 32767.0))
	return _wav(data, rate)


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


func _play(id: String) -> void:
	if players.is_empty() or not tones.has(id):
		return
	var player: AudioStreamPlayer = players[players.size() - 1]
	for p in players:
		if not p.playing:
			player = p
			break
	player.volume_db = -14.0 if id == "click" else -8.0
	player.stream = tones[id]
	player.play()


# ---------------------------------------------------------------- рисование

func _text(pos: Vector2, text: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(font, pos, text, align, width, size, color)


func _draw() -> void:
	if phase == "school":
		return
	_draw_background()
	if phase == "menu":
		_draw_menu_screen()
		return
	if looking and phase == "play":
		_draw_room()
		_draw_look()
		_draw_popups()
		return
	if docs_active and phase == "play":
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.08, 0.08, 0.74))
		_draw_room()
		_draw_docs()
		_draw_popups()
		return
	if phase != "title":
		_draw_room()
		_draw_log()
		_draw_inventory()
		_draw_menu()
		if listen_active:
			_draw_listen_prompt()
		if tea_active:
			_draw_tea()
	_draw_popups()
	if phase == "title":
		_draw_title()
	elif phase == "end":
		_draw_end()


func _time_x(minutes: float) -> float:
	return 50.0 + 570.0 * clampf((minutes - Data.CLOCK_START) / float(Data.CLOCK_END - Data.CLOCK_START), 0.0, 1.0)


func _draw_background() -> void:
	if background != null:
		draw_texture_rect(background, Rect2(0, 0, 1280, 720), false)
		return
	draw_rect(Rect2(0, 0, 1280, 720), BG)
	for x in range(0, 1280, 40):
		draw_line(Vector2(x, 0), Vector2(x, 720), BG_LINE, 1.0)


func _draw_room() -> void:
	var header := Color(HEADER, 0.93 if background != null else 1.0)
	if looking:
		header = Color(HEADER, 0.7)
	draw_rect(Rect2(0, 0, 1280, 128), header)
	if background != null and not looking and not docs_active:
		draw_rect(Rect2(0, 538, 1280, 182), Color(0.04, 0.08, 0.08, 0.6))
	_text(Vector2(50, 36), Data.TITLE, 26, GOLD)
	_text(Vector2(50, 58), "%s · «%s»" % [Data.SUBTITLE.split(" · ")[0], Data.LEVEL_NAME], 14, MUTED)
	# часы
	var shown := int(round(clock_shown))
	var clock_color := PAPER
	if shown > Data.COPY_WINDOW:
		clock_color = BAD
	elif shown > Data.DEADLINE:
		clock_color = GOLD
	_text(Vector2(980, 56), _fmt(shown), 44, clock_color, HORIZONTAL_ALIGNMENT_RIGHT, 250.0)
	_text(Vector2(880, 76), "справка нужна к %s · банк ждёт в %s" % [_fmt(Data.DEADLINE), _fmt(Data.BANK_AT)], 13, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 350.0)
	# шкала времени
	_text(Vector2(50, 88), "ВРЕМЯ", 11, MUTED)
	var tbar := Rect2(50, 92, 570, 14)
	bar_style.bg_color = Color(1, 1, 1, 0.1)
	draw_style_box(bar_style, tbar)
	var tcolor := GOOD
	if shown > Data.COPY_WINDOW:
		tcolor = BAD
	elif shown > Data.DEADLINE:
		tcolor = GOLD
	if shown > Data.CLOCK_START:
		bar_style.bg_color = tcolor
		draw_style_box(bar_style, Rect2(tbar.position, Vector2(maxf(14.0, _time_x(clock_shown) - 50.0), tbar.size.y)))
	for mark in [Data.DEADLINE, Data.BANK_AT, Data.COPY_WINDOW]:
		var mx := _time_x(float(mark))
		draw_line(Vector2(mx, 89), Vector2(mx, 109), PAPER, 2.0 if mark == Data.DEADLINE else 1.0)
	_text(Vector2(50, 123), _fmt(Data.CLOCK_START), 12, MUTED)
	_text(Vector2(_time_x(Data.DEADLINE) - 60.0, 123), "%s справка" % _fmt(Data.DEADLINE), 12, PAPER, HORIZONTAL_ALIGNMENT_CENTER, 120.0)
	_text(Vector2(_time_x(Data.BANK_AT) - 50.0, 123), "%s банк" % _fmt(Data.BANK_AT), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 100.0)
	_text(Vector2(520, 123), _fmt(Data.CLOCK_END), 12, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 100.0)
	# шкала уважения
	_text(Vector2(660, 88), "УВАЖЕНИЕ ЛГ", 11, MUTED)
	var rbar := Rect2(660, 92, 570, 14)
	bar_style.bg_color = Color(1, 1, 1, 0.1)
	draw_style_box(bar_style, rbar)
	var share := clampf(respect_shown / float(Data.RESPECT_MAX), 0.0, 1.0)
	if share > 0.0:
		bar_style.bg_color = BAD.lerp(GOLD, minf(share * 2.0, 1.0)).lerp(GOOD, maxf(0.0, share * 2.0 - 1.0))
		draw_style_box(bar_style, Rect2(rbar.position, Vector2(maxf(14.0, rbar.size.x * share), rbar.size.y)))
	_text(Vector2(660, 123), str(Data.RESPECT_TIERS.back()[1]), 12, MUTED)
	_text(Vector2(660, 123), _tier(respect_shown), 13, PAPER, HORIZONTAL_ALIGNMENT_CENTER, 570.0)
	_text(Vector2(1130, 123), str(Data.RESPECT_TIERS[0][1]), 12, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, 100.0)
	if not looking and not docs_active:
		_draw_accountant()


func _draw_accountant() -> void:
	var tex: Texture2D = portraits.get(mood)
	if tex == null:
		_draw_accountant_fallback()
		return
	box_style.bg_color = Color(0.04, 0.08, 0.08, 0.55)
	box_style.border_color = Color(1, 1, 1, 0.14)
	draw_style_box(box_style, PORTRAIT_BOX)
	# портрет 512x640 вписан в подложку по ширине, ноги и руки обрезаются снизу
	var width := PORTRAIT_BOX.size.x - 8.0
	var height := width * 640.0 / 512.0
	draw_texture_rect(tex, Rect2(PORTRAIT_BOX.position.x + 4.0, PORTRAIT_BOX.position.y + 2.0, width, height), false)
	var strip := Rect2(PORTRAIT_BOX.position.x + 1.0, PORTRAIT_BOX.end.y - 28.0, PORTRAIT_BOX.size.x - 2.0, 27.0)
	draw_rect(strip, Color(0.04, 0.08, 0.08, 0.8))
	_text(Vector2(strip.position.x, strip.position.y + 19.0), Data.ACCOUNTANT_NAME, 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER, strip.size.x)


func _draw_accountant_fallback() -> void:
	draw_set_transform(Vector2(18, 5), 0.0, Vector2.ONE * 1.3)
	# пиджак, воротник, шея
	draw_colored_polygon(PackedVector2Array([Vector2(40, 250), Vector2(170, 250), Vector2(152, 204), Vector2(58, 204)]), Color("#3b4a6b"))
	draw_colored_polygon(PackedVector2Array([Vector2(92, 204), Vector2(118, 204), Vector2(105, 228)]), PAPER)
	draw_rect(Rect2(96, 190, 18, 18), Color("#e8b995"))
	# голова, причёска, пучок
	draw_circle(Vector2(105, 168), 32.0, SKIN)
	draw_circle(Vector2(105, 142), 30.0, Color("#4a3b36"))
	draw_circle(Vector2(105, 118), 14.0, Color("#4a3b36"))
	draw_rect(Rect2(76, 140, 58, 20), SKIN)
	# очки
	draw_arc(Vector2(92, 166), 11.0, 0.0, TAU, 20, INK, 2.5)
	draw_arc(Vector2(118, 166), 11.0, 0.0, TAU, 20, INK, 2.5)
	draw_line(Vector2(103, 166), Vector2(107, 166), INK, 2.5)
	# глаза
	match mood:
		"down":
			draw_circle(Vector2(92, 171), 2.5, INK)
			draw_circle(Vector2(118, 171), 2.5, INK)
			draw_line(Vector2(82, 163), Vector2(102, 163), Color("#c79b78"), 3.0)
			draw_line(Vector2(108, 163), Vector2(128, 163), Color("#c79b78"), 3.0)
		"melt", "happy":
			draw_arc(Vector2(92, 169), 6.0, PI + 0.4, TAU - 0.4, 10, INK, 2.5)
			draw_arc(Vector2(118, 169), 6.0, PI + 0.4, TAU - 0.4, 10, INK, 2.5)
		"whisper":
			draw_circle(Vector2(96, 166), 2.5, INK)
			draw_circle(Vector2(122, 166), 2.5, INK)
		_:
			draw_circle(Vector2(92, 166), 2.5, INK)
			draw_circle(Vector2(118, 166), 2.5, INK)
	if mood == "angry":
		draw_line(Vector2(80, 150), Vector2(98, 156), INK, 3.0)
		draw_line(Vector2(130, 150), Vector2(112, 156), INK, 3.0)
	if mood == "melt":
		draw_circle(Vector2(80, 182), 6.0, Color(1.0, 0.45, 0.5, 0.4))
		draw_circle(Vector2(130, 182), 6.0, Color(1.0, 0.45, 0.5, 0.4))
	# рот
	var lips := Color("#a83a3a")
	match mood:
		"happy", "melt":
			draw_arc(Vector2(105, 178), 11.0, 0.3, PI - 0.3, 12, lips, 3.0)
		"angry":
			draw_arc(Vector2(105, 192), 10.0, PI + 0.4, TAU - 0.4, 12, lips, 3.0)
		"whisper":
			draw_circle(Vector2(108, 187), 4.0, lips)
		_:
			draw_line(Vector2(96, 186), Vector2(114, 186), lips, 3.0)
	draw_set_transform(Vector2.ZERO)
	_text(Vector2(40, 348), Data.ACCOUNTANT_NAME, 15, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 230.0)


func _speaker(who: String) -> String:
	match who:
		"ЛГ": return Data.ACCOUNTANT_NAME.to_upper()
		"ВЫ": return "ВЫ"
	return "СИСТЕМА"


func _speaker_color(who: String) -> Color:
	match who:
		"ЛГ": return GOLD
		"ВЫ": return YOU
	return MUTED


func _draw_log() -> void:
	box_style.bg_color = Color(0.03, 0.07, 0.07, 0.8 if background != null else 0.3)
	box_style.border_color = Color(1, 1, 1, 0.12)
	draw_style_box(box_style, PANEL)
	var inner := Rect2(PANEL.position + Vector2(24, 14), PANEL.size - Vector2(48, 58))
	var heights: Dictionary = {}
	var total := 0.0
	var first := log.size()
	for i in range(log.size() - 1, -1, -1):
		var th := font.get_multiline_string_size(str(log[i]["text"]), HORIZONTAL_ALIGNMENT_LEFT, inner.size.x - 14.0, 22).y
		var h := 22.0 + th + 12.0
		if total + h > inner.size.y and first < log.size():
			break
		heights[i] = h
		total += h
		first = i
	var y := inner.position.y
	var ascent := font.get_ascent(22)
	for i in range(first, log.size()):
		var e: Dictionary = log[i]
		var who := str(e["who"])
		var fresh := i == log.size() - 1
		var alpha := 1.0 if fresh else 0.6
		var col := _speaker_color(who)
		var text := str(e["text"])
		if fresh and _typing():
			text = text.substr(0, int(float(e["chars"])))
		draw_rect(Rect2(inner.position.x, y + 2.0, 3.0, float(heights[i]) - 14.0), Color(col, alpha))
		_text(Vector2(inner.position.x + 14.0, y + 12.0), _speaker(who), 12, Color(col, alpha))
		var body := PAPER if who == "ЛГ" else (Color("#d6ecff") if who == "ВЫ" else MUTED)
		draw_multiline_string(font, Vector2(inner.position.x + 14.0, y + 22.0 + ascent), text, HORIZONTAL_ALIGNMENT_LEFT, inner.size.x - 14.0, 22, -1, Color(body, alpha))
		y += float(heights[i])
	# подсказка внизу панели
	var base := PANEL.position.y + PANEL.size.y
	if _typing():
		return
	if not queue.is_empty():
		_text(Vector2(PANEL.position.x, base - 16), "Пробел или клик", 14, Color(GOLD, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 260.0)), HORIZONTAL_ALIGNMENT_RIGHT, PANEL.size.x - 20.0)
	elif pending_end != "" and phase == "play":
		_text(Vector2(PANEL.position.x, base - 16), "Пробел или клик — финал", 14, Color(GOLD, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 260.0)), HORIZONTAL_ALIGNMENT_RIGHT, PANEL.size.x - 20.0)
	elif _menu_visible():
		_text(Vector2(PANEL.position.x + 24.0, base - 16), "Ваш ход: 1–%d или клик. ЛГ ждёт ответа." % menu.size(), 13, MUTED)
		var share := clampf(idle_t / IDLE_LIMIT, 0.0, 1.0)
		draw_rect(Rect2(PANEL.position.x + 24.0, base - 8.0, (PANEL.size.x - 48.0) * share, 3.0), Color(BAD, 0.8))


func _inventory_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if has_choc:
		items.append({"label": "Шоколадка с фундуком", "icon": "choc", "doc": false})
	items.append({"label": "Паспорт", "icon": "passport", "doc": false})
	items.append({"label": "Пропуск", "icon": "pass", "doc": false})
	if mug == "empty":
		items.append({"label": "Кружка (пустая)", "icon": "mug", "doc": false})
	for d in docs:
		items.append({"label": d, "icon": str(Data.DOC_ICONS.get(d, "")), "doc": true})
	return items


func _draw_inventory() -> void:
	box_style.bg_color = Color(0.04, 0.08, 0.08, 0.55)
	box_style.border_color = Color(1, 1, 1, 0.14)
	draw_style_box(box_style, INV)
	var items := _inventory_items()
	var cols := 4
	var gap_x := 10.0
	var gap_y := 6.0
	var x0 := INV.position.x + (INV.size.x - (cols * ICON + (cols - 1) * gap_x)) * 0.5
	var mouse := get_local_mouse_position()
	var hovered := -1
	for i in mini(items.size(), cols * 2):
		var rect := Rect2(x0 + (i % cols) * (ICON + gap_x), INV.position.y + 4.0 + (i / cols) * (ICON + gap_y), ICON, ICON)
		var item: Dictionary = items[i]
		var is_doc: bool = item["doc"]
		box_style.bg_color = Color(GOOD, 0.16) if is_doc else Color(1, 1, 1, 0.07)
		box_style.border_color = Color(GOOD, 0.5) if is_doc else Color(1, 1, 1, 0.12)
		draw_style_box(box_style, rect)
		var tex: Texture2D = items_art.get(str(item["icon"]))
		if tex != null:
			draw_texture_rect(tex, rect.grow(-2.0), false)
		else:
			draw_multiline_string(font, rect.position + Vector2(3, 12), str(item["label"]), HORIZONTAL_ALIGNMENT_LEFT, ICON - 6.0, 9, 4, PAPER)
		if rect.has_point(mouse):
			hovered = i
	if hovered >= 0:
		var label := str(items[hovered]["label"])
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 20.0
		var tip := Rect2(INV.position.x, INV.position.y - 30.0, minf(w, 330.0), 26.0)
		box_style.bg_color = Color(0.03, 0.06, 0.06, 0.95)
		box_style.border_color = GOLD
		draw_style_box(box_style, tip)
		_text(tip.position + Vector2(10, 18), label, 14, PAPER)


func _draw_menu() -> void:
	if not _menu_visible():
		return
	var mouse := get_local_mouse_position()
	for i in menu.size():
		var rect := _button_rect(i)
		var hover := rect.has_point(mouse)
		box_style.bg_color = Color("#34504f") if hover else Color("#27403f")
		box_style.border_color = GOLD if hover else Color(1, 1, 1, 0.18)
		draw_style_box(box_style, rect)
		_text(rect.position + Vector2(14, 29), str(i + 1), 18, GOLD)
		var label := str(menu[i]["label"])
		var label_w := rect.size.x - 52.0
		var h := font.get_multiline_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, label_w, 15, 2).y
		draw_multiline_string(font, rect.position + Vector2(40, (BTN_H - h) * 0.5 + font.get_ascent(15)), label, HORIZONTAL_ALIGNMENT_LEFT, label_w, 15, 2, PAPER)


func _draw_listen_prompt() -> void:
	var rect := Rect2(MENU_X, MENU_Y + 6.0, MENU_W, 100.0)
	var in_pause := listen_state == "pause"
	box_style.bg_color = Color("#34504f") if in_pause else Color(0.04, 0.08, 0.08, 0.7)
	box_style.border_color = GOLD if in_pause else Color(1, 1, 1, 0.15)
	draw_style_box(box_style, rect)
	var total := Data.C1_CHUNKS.size() - 1
	if in_pause:
		var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 90.0)
		_text(rect.position + Vector2(0, 42), "КИВНИТЕ!  Пробел, 1 или клик", 28, Color(GOLD, pulse), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		var left := clampf(1.0 - listen_t / Data.LISTEN_PAUSE, 0.0, 1.0)
		draw_rect(Rect2(rect.position.x + 40.0, rect.position.y + 62.0, (rect.size.x - 80.0) * left, 8.0), Color(GOLD, 0.9))
	else:
		_text(rect.position + Vector2(0, 42), "ЛГ говорит… не перебивайте", 24, MUTED, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	_text(rect.position + Vector2(0, 88), "Кивнули вовремя: %d из %d     Перебили: %d" % [listen_good, total, listen_interrupts], 14, PAPER, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


func _draw_tea() -> void:
	var rect := Rect2(50, 538, 1180, 174)
	box_style.bg_color = Color(0.03, 0.07, 0.07, 0.94)
	box_style.border_color = GOLD
	draw_style_box(box_style, rect)
	_text(rect.position + Vector2(0, 30), Data.TEA_HINT_TITLE, 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	var cy := rect.position.y + 98.0
	var near := _tea_nearest()
	for i in tea_bags.size():
		var rel := _tea_x(i)
		var edge := clampf((rect.size.x * 0.5 - 70.0 - absf(rel)) / 110.0, 0.0, 1.0)
		if edge <= 0.35:
			continue
		var bag: Dictionary = tea_bags[i]
		var x := 640.0 + rel
		var card := Rect2(x - 62.0, cy - 44.0, 124.0, 88.0)
		var base: Color = bag["color"]
		draw_line(Vector2(x, card.position.y - 16.0), Vector2(x, card.position.y), Color(PAPER, edge * 0.7), 2.0)
		box_style.bg_color = Color(base, edge)
		box_style.border_color = Color(GOLD, edge) if i == near else Color(INK, 0.5 * edge)
		draw_style_box(box_style, card)
		var ink := INK if base.get_luminance() > 0.45 else PAPER
		draw_multiline_string(font, card.position + Vector2(6, 26), str(bag["name"]), HORIZONTAL_ALIGNMENT_CENTER, card.size.x - 12.0, 15, 2, Color(ink, edge))
		_text(card.position + Vector2(0, 76), str(bag["tag"]), 11, Color(ink, edge * 0.85), HORIZONTAL_ALIGNMENT_CENTER, card.size.x)
	# рамка-прицел в центре
	draw_rect(Rect2(640.0 - 72.0, cy - 54.0, 144.0, 108.0), GOLD, false, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(628, cy - 66), Vector2(652, cy - 66), Vector2(640, cy - 54)]), GOLD)
	_text(rect.position + Vector2(0, 167), Data.TEA_HINT, 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


func _doc_rect(i: int) -> Rect2:
	return Rect2(68.0 + (i % 5) * 232.0, 224.0 + (i / 5) * 182.0, 216.0, 170.0)


func _draw_docs() -> void:
	var strip := Rect2(68, 140, 1144, 44)
	box_style.bg_color = Color(0.03, 0.07, 0.07, 0.92)
	box_style.border_color = GOLD
	draw_style_box(box_style, strip)
	_text(strip.position + Vector2(0, 29), Data.DOCS_RULE, 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER, strip.size.x)
	# таймер
	var left := _docs_left()
	var share := left / Data.DOCS_TIME
	bar_style.bg_color = Color(1, 1, 1, 0.12)
	draw_style_box(bar_style, Rect2(68, 192, 1080, 12))
	if share > 0.0:
		bar_style.bg_color = GOOD if share > 0.5 else (GOLD if share > 0.2 else BAD)
		draw_style_box(bar_style, Rect2(68, 192, maxf(12.0, 1080.0 * share), 12))
	_text(Vector2(1148, 204), "%d с" % ceili(left), 20, PAPER if share > 0.2 else BAD, HORIZONTAL_ALIGNMENT_RIGHT, 64.0)
	var mouse := get_local_mouse_position()
	for i in docs_cards.size():
		var card: Dictionary = docs_cards[i]
		var rect := _doc_rect(i)
		var bad: bool = card["bad"]
		var hover := rect.has_point(mouse) and not bad
		box_style.bg_color = Color("#fff6dc") if hover else PAPER
		box_style.border_color = GOLD if hover else Color(INK, 0.5)
		draw_style_box(box_style, rect)
		draw_circle(rect.position + Vector2(22, 22), 13.0, Color(INK, 0.85))
		_text(rect.position + Vector2(9, 28), str((i + 1) % 10), 16, PAPER, HORIZONTAL_ALIGNMENT_CENTER, 26.0)
		_text(rect.position + Vector2(44, 27), "№ %06d" % int(card["serial"]), 12, Color(INK, 0.5))
		draw_multiline_string(font, rect.position + Vector2(14, 60), str(card["title"]), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 28.0, 16, 2, INK)
		draw_rect(Rect2(rect.position + Vector2(14, 98), Vector2(150, 5)), Color(INK, 0.16))
		draw_rect(Rect2(rect.position + Vector2(14, 110), Vector2(110, 5)), Color(INK, 0.16))
		_text(rect.position + Vector2(14, 142), "за %d год" % int(card["year"]), 20, INK)
		var state := str(card["state"])
		var state_color := Color("#2f6a45") if state == Data.DOC_STATE_OK else (Color("#b3453d") if state == "пустой бланк" else Color("#b07a1a"))
		_text(rect.position + Vector2(14, 162), state, 13, state_color)
		if bad:
			draw_rect(rect, Color(BAD, 0.42))
			draw_line(rect.position + Vector2(40, 40), rect.end - Vector2(40, 40), Color("#b3453d"), 6.0)
			draw_line(Vector2(rect.end.x - 40, rect.position.y + 40), Vector2(rect.position.x + 40, rect.end.y - 40), Color("#b3453d"), 6.0)
	if docs_msg != "" and docs_msg_t < 3.0:
		_text(Vector2(68, 632), docs_msg, 24, BAD, HORIZONTAL_ALIGNMENT_CENTER, 1144.0)
	else:
		_text(Vector2(68, 632), Data.DOCS_HINT, 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 1144.0)


func _draw_look() -> void:
	var mouse := get_local_mouse_position()
	var hovered: Dictionary = {}
	for spot in Data.HOTSPOTS:
		var rect: Rect2 = spot["rect"]
		var is_seen := seen.has(str(spot["id"]))
		var hover := rect.has_point(mouse)
		if hover:
			hovered = spot
			box_style.bg_color = Color(GOLD, 0.12)
			box_style.border_color = GOLD
			draw_style_box(box_style, rect)
		var center := rect.intersection(Rect2(0, 134, 1280, 586)).get_center()
		if not is_seen:
			var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 260.0 + center.x)
			draw_circle(center, 15.0, Color(0.04, 0.08, 0.08, 0.75))
			draw_arc(center, 15.0, 0.0, TAU, 24, Color(GOLD, pulse), 2.5)
			_text(center + Vector2(-15, 7), "?", 20, Color(GOLD, pulse), HORIZONTAL_ALIGNMENT_CENTER, 30.0)
		else:
			draw_circle(center, 9.0, Color(0.04, 0.08, 0.08, 0.6))
			draw_arc(center, 9.0, 0.0, TAU, 20, Color(GOOD, 0.8), 2.0)
	if not hovered.is_empty():
		var rect: Rect2 = hovered["rect"]
		var spot_name := str(hovered["name"])
		var w := font.get_string_size(spot_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 20.0
		var tip := Rect2(clampf(rect.position.x, 8.0, 1272.0 - w), maxf(rect.position.y - 30.0, 134.0), w, 26.0)
		box_style.bg_color = Color(0.03, 0.06, 0.06, 0.95)
		box_style.border_color = GOLD
		draw_style_box(box_style, tip)
		_text(tip.position + Vector2(10, 19), spot_name, 16, PAPER)
	# подпись внизу
	box_style.bg_color = Color(0.03, 0.07, 0.07, 0.88)
	box_style.border_color = Color(1, 1, 1, 0.15)
	draw_style_box(box_style, LOOK_CAPTION)
	var caption := look_text if look_text != "" else Data.LOOK_HINT
	draw_multiline_string(font, LOOK_CAPTION.position + Vector2(20, 32), caption, HORIZONTAL_ALIGNMENT_LEFT, LOOK_CAPTION.size.x - 40.0, 20, 5, PAPER if look_text != "" else MUTED)
	# кнопка назад
	var back_hover := LOOK_BACK_RECT.has_point(mouse)
	box_style.bg_color = Color("#34504f") if back_hover else Color("#27403f")
	box_style.border_color = GOLD if back_hover else Color(1, 1, 1, 0.18)
	draw_style_box(box_style, LOOK_BACK_RECT)
	_text(LOOK_BACK_RECT.position + Vector2(0, 26), Data.LOOK_BACK, 15, PAPER, HORIZONTAL_ALIGNMENT_CENTER, LOOK_BACK_RECT.size.x)
	_text(LOOK_BACK_RECT.position + Vector2(0, -8), "Esc, Пробел или кнопка", 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER, LOOK_BACK_RECT.size.x)
	# заметки
	box_style.bg_color = Color(0.03, 0.07, 0.07, 0.88)
	draw_style_box(box_style, LOOK_NOTES)
	_text(LOOK_NOTES.position + Vector2(16, 28), Data.LOOK_NOTES_TITLE, 13, GOLD)
	var y := LOOK_NOTES.position.y + 38.0
	if clues.is_empty():
		draw_multiline_string(font, Vector2(LOOK_NOTES.position.x + 16, y + 14.0), Data.LOOK_NOTES_EMPTY, HORIZONTAL_ALIGNMENT_LEFT, LOOK_NOTES.size.x - 32.0, 14, 3, MUTED)
	for key in clues:
		var note := "• %s" % str(clues[key])
		var nh := font.get_multiline_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, LOOK_NOTES.size.x - 32.0, 13).y
		draw_multiline_string(font, Vector2(LOOK_NOTES.position.x + 16, y + font.get_ascent(13)), note, HORIZONTAL_ALIGNMENT_LEFT, LOOK_NOTES.size.x - 32.0, 13, -1, PAPER)
		y += nh + 4.0


func _draw_popups() -> void:
	for p in popups:
		var t: float = p["t"]
		var pos: Vector2 = p["pos"]
		var color: Color = p["color"]
		_text(pos + Vector2(-140, -t * 40.0), str(p["text"]), 20, Color(color, clampf(2.0 - t * 1.3, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, 280.0)


func _dim(alpha: float) -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.07, 0.07, alpha))


func _draw_title() -> void:
	_dim(0.8 if background != null else 0.975)
	var ep: Dictionary = Data.EPISODES[episode]
	_text(Vector2(0, 190), "СЕРИЯ %d  ·  %s" % [episode + 1, str(ep["name"]).to_upper()], 20, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	_text(Vector2(0, 250), str(ep.get("title", Data.LEVEL_NAME)), 56, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	_text(Vector2(0, 295), Data.SUBTITLE, 24, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	for i in Data.RULES.size():
		_text(Vector2(0, 365.0 + i * 32.0), str(Data.RULES[i]), 20, PAPER, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	_text(Vector2(0, 545), "В карманах: шоколадка с фундуком, паспорт, пропуск, пустая кружка.", 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 260.0)
	_text(Vector2(0, 620), Data.START_HINT, 26, Color(GOOD, pulse), HORIZONTAL_ALIGNMENT_CENTER, 1280.0)


func _draw_menu_screen() -> void:
	_dim(0.8 if background != null else 0.96)
	var episodes: Array = Data.EPISODES
	var open_count := 0
	for ep in episodes:
		if bool(ep["open"]):
			open_count += 1
	_text(Vector2(0, 84), Data.TITLE, 60, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	_text(Vector2(0, 124), Data.MENU_SUBTITLE, 22, PAPER, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	_text(Vector2(0, 156), Data.MENU_COUNT % [episodes.size(), open_count], 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	for i in episodes.size():
		_draw_episode_card(i, episodes[i])
	# строка под сеткой: подпись выбранной серии или сообщение о закрытой
	var sel: Dictionary = episodes[menu_sel]
	if menu_toast_t > 0.0:
		_text(Vector2(0, 672), menu_toast, 20, Color(GOLD, clampf(menu_toast_t * 2.0, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	else:
		_text(Vector2(0, 672), str(sel["tagline"]), 20, PAPER, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
	_text(Vector2(0, 703), Data.MENU_HELP, 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)


func _draw_episode_card(i: int, ep: Dictionary) -> void:
	var rect := _ep_rect(i)
	var selected := i == menu_sel
	var open: bool = ep["open"]
	if selected:
		rect = rect.grow(6.0)
	var tint: Color = ep["color"]
	box_style.set_corner_radius_all(10)
	box_style.bg_color = tint.darkened(0.55)
	box_style.border_color = GOLD if selected else Color(1, 1, 1, 0.12)
	box_style.set_border_width_all(3 if selected else 2)
	draw_style_box(box_style, rect)
	box_style.set_corner_radius_all(8)
	box_style.set_border_width_all(2)
	var inner := rect.grow(-3.0)
	if ep.get("mode", "") == "school":
		draw_rect(inner, SchoolDay.BOARD)
		_text(inner.position + Vector2(22, 31), "ОБРАЗОВАНИЕ", 16, PAPER)
		var ticket := Rect2(inner.position + Vector2(22, 54), Vector2(inner.size.x - 44, 65))
		SchoolDay.draw_ticket(self, ticket)
		_text(ticket.position + Vector2(14, 39), "КИНО   /   15:30", 23, SchoolDay.INK)
	elif open:
		# постер: фон кабинета и портрет ЛГ
		if background != null:
			draw_texture_rect(background, inner, false)
		var portrait: Texture2D = portraits.get("neutral")
		if portrait != null:
			var ph := inner.size.y
			var pw := ph * 512.0 / 640.0
			draw_texture_rect(portrait, Rect2(inner.end.x - pw - 8.0, inner.position.y + 6.0, pw, ph), false)
	else:
		draw_rect(inner, Color(tint.darkened(0.6), 0.9))
		_text(inner.position + Vector2(0, 112), str(i + 1), 110, Color(tint, 0.22), HORIZONTAL_ALIGNMENT_CENTER, inner.size.x)
		_draw_lock(inner.position + Vector2(inner.size.x * 0.5, 44.0))
		draw_multiline_string(font, inner.position + Vector2(28, 98), str(ep["tagline"]), HORIZONTAL_ALIGNMENT_CENTER, inner.size.x - 56.0, 14, 2, Color(PAPER, 0.6))
	# нижняя плашка с названием
	var strip := Rect2(inner.position.x, inner.end.y - 60.0, inner.size.x, 60.0)
	draw_rect(strip, Color(0.03, 0.06, 0.06, 0.82))
	_text(strip.position + Vector2(14, 20), "СЕРИЯ %d" % (i + 1), 12, GOLD if open else MUTED)
	var heading := str(ep["name"]) if not open else str(ep.get("title", ep["name"]))
	_text(strip.position + Vector2(14, 46), heading, 20, PAPER if open else Color(PAPER, 0.7), HORIZONTAL_ALIGNMENT_LEFT, inner.size.x - 28.0)
	if open:
		var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() / 300.0)
		_text(strip.position + Vector2(0, 20), "СМОТРЕТЬ", 13, Color(GOOD, pulse if selected else 0.8), HORIZONTAL_ALIGNMENT_RIGHT, inner.size.x - 14.0)
	else:
		_text(strip.position + Vector2(0, 20), Data.MENU_LOCK_TAG, 12, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, inner.size.x - 14.0)


func _draw_lock(center: Vector2) -> void:
	var color := Color(PAPER, 0.8)
	draw_arc(center + Vector2(0, -8), 12.0, PI, TAU, 16, color, 4.0)
	draw_rect(Rect2(center + Vector2(-17, -8), Vector2(34, 26)), color)
	draw_circle(center + Vector2(0, 5), 3.5, Color(0.04, 0.08, 0.08, 0.9))


func _draw_end() -> void:
	_dim(minf(0.96, end_t * 3.0))
	var info: Dictionary = Data.ENDINGS[ending]
	var good := ending == "human"   # формальная победа красная: справку никто не примет
	var art: Texture2D = endings_art.get(ending)
	var fade := clampf(end_t * 3.0, 0.0, 1.0)
	var stats := "Время: %s  ·  банк ждёт в %s  ·  Уважение ЛГ: «%s»\nПриз: %s" % [
		_fmt(mini(clock, Data.CLOCK_END)), _fmt(Data.BANK_AT), _tier(float(respect)), str(info["prize"])]
	var tint := GOOD.darkened(0.35) if good else BAD.darkened(0.2)
	var stamp_alpha := clampf(end_t * 4.0, 0.0, 1.0)
	var scale_in := lerpf(2.4, 1.0, ease(clampf(end_t / 0.3, 0.0, 1.0), 0.4))
	if art != null:
		# иллюстрация концовки сверху, подпись и приз снизу
		var frame := Rect2(160, 18, 960, 540)
		draw_rect(frame.grow(6.0), Color(PAPER, fade))
		draw_texture_rect(art, frame, false, Color(1, 1, 1, fade))
		draw_set_transform(Vector2(930, 480), -0.18, Vector2.ONE * scale_in)
		draw_rect(Rect2(-190, -34, 380, 68), Color(PAPER, 0.88 * stamp_alpha))
		draw_rect(Rect2(-190, -34, 380, 68), Color(tint, stamp_alpha), false, 5.0)
		_text(Vector2(-190, 14), str(info["stamp"]), 44, Color(tint, stamp_alpha), HORIZONTAL_ALIGNMENT_CENTER, 380.0)
		draw_set_transform(Vector2.ZERO)
		_text(Vector2(0, 604), str(info["title"]), 28, Color(GOLD, fade), HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
		draw_multiline_string(font, Vector2(90, 632), str(info["sub"]), HORIZONTAL_ALIGNMENT_CENTER, 1100.0, 18, 1, Color(PAPER, fade))
		draw_multiline_string(font, Vector2(90, 658), stats, HORIZONTAL_ALIGNMENT_CENTER, 1100.0, 16, 2, Color(MUTED, fade))
		_text(Vector2(0, 710), "Пробел или клик — ещё раз   ·   Esc — к списку серий", 16, Color(MUTED, fade), HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
		return
	# запасной вариант без иллюстрации: бумажная карточка
	var paper := Rect2(290, 130, 700, 460)
	box_style.bg_color = PAPER
	box_style.border_color = Color(INK, 0.4)
	draw_style_box(box_style, paper)
	_text(Vector2(290, 184), str(info["title"]), 26, INK, HORIZONTAL_ALIGNMENT_CENTER, 700.0)
	draw_multiline_string(font, Vector2(320, 222), str(info["sub"]), HORIZONTAL_ALIGNMENT_CENTER, 640.0, 18, 2, Color("#5a4f44"))
	draw_multiline_string(font, Vector2(320, 320), stats, HORIZONTAL_ALIGNMENT_CENTER, 640.0, 20, 4, INK)
	draw_set_transform(Vector2(640, 510), -0.18, Vector2.ONE * scale_in)
	draw_rect(Rect2(-190, -34, 380, 68), Color(tint, stamp_alpha), false, 5.0)
	_text(Vector2(-190, 14), str(info["stamp"]), 44, Color(tint, stamp_alpha), HORIZONTAL_ALIGNMENT_CENTER, 380.0)
	draw_set_transform(Vector2.ZERO)
	_text(Vector2(0, 640), "Пробел или клик — ещё раз   ·   Esc — к списку серий", 20, MUTED, HORIZONTAL_ALIGNMENT_CENTER, 1280.0)
