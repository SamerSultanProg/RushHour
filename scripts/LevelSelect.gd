extends Control

func _ready() -> void:
	# Nombre total de niveaux
	var count: int = Levels.get_level_count()

	# ----- Récupérer ou créer le GridContainer pour les boutons -----
	var grid: GridContainer = null

	# 1) Essayer avec un nœud existant nommé "grid" ou "Grid"
	if has_node("grid"):
		grid = get_node("grid") as GridContainer
	elif has_node("Grid"):
		grid = get_node("Grid") as GridContainer

	# 2) Si rien trouvé, on en crée un nouveau au centre
	if grid == null:
		grid = GridContainer.new()
		grid.name = "grid"
		grid.columns = 5   # 5 boutons par rangée (comme avant)

		# Mise en page simple centrée
		grid.anchor_left = 0.5
		grid.anchor_top = 0.5
		grid.anchor_right = 0.5
		grid.anchor_bottom = 0.5
		grid.position = get_viewport_rect().size / 2.0
		grid.position.x -= 250  # petit offset pour centrer visuellement
		grid.position.y -= 60

		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		add_child(grid)

	# ----- Création dynamique des boutons de niveaux -----
	for i in range(count):
		var b := Button.new()
		b.text = "Niveau %d" % (i + 1)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func (): _load_level(i))
		grid.add_child(b)

	# ----- Bouton Retour -----
	if has_node("ReturnButton"):
		$ReturnButton.pressed.connect(_on_return_pressed)

func _load_level(idx: int) -> void:
	Levels.set_level(idx)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Start.tscn")
