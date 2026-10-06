extends SceneTree

const MatchCasesScript: GDScript = preload("res://tests/match_cases.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("MARK boot")
	InputActions.install()
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var app: App = packed.instantiate() as App
	app.test_driven = true
	root.add_child(app)
	app.start_fight("vs2", "police", 0)
	await process_frame
	await process_frame
	print("MARK schema")
	print(MatchCasesScript.schema_and_machine())
	var listed: PackedStringArray = SimTrace.list_dir("res://tests/traces/match")
	for path in listed:
		print("MARK trace1 ", path)
		var a: Dictionary = await SimReplay.play_path(app, path)
		print("MARK trace1_done ", path, " ok=", a.get("ok"), " ticks=", a.get("ticks"), " errors=", a.get("errors"))
		print("MARK trace2 ", path)
		var b: Dictionary = await SimReplay.play_path(app, path)
		print("MARK trace2_done ", path, " ok=", b.get("ok"), " ticks=", b.get("ticks"), " errors=", b.get("errors"))
	print("MARK done")
	app.shutdown()
	app.queue_free()
	await process_frame
	quit(0)
