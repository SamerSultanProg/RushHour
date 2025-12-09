extends Node

# Helper function to style buttons consistently across the game
func style_button(btn: Button, theme_override: Theme = null) -> void:
	# Style moderne et épuré directement sur le bouton
	
	# Couleurs - dégradé subtil bleu-gris moderne
	var base_color := Color(0.18, 0.22, 0.28, 0.95)       # Bleu-gris foncé
	var hover_color := Color(0.25, 0.35, 0.45, 1.0)       # Plus clair au hover
	var pressed_color := Color(0.12, 0.15, 0.20, 1.0)    # Plus foncé au clic
	var border_color := Color(0.4, 0.5, 0.6, 0.5)        # Bordure subtile
	var border_hover := Color(0.5, 0.65, 0.85, 0.8)      # Bordure lumineuse au hover
	
	# === NORMAL STATE ===
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(8)
	normal.border_color = border_color
	normal.set_border_width_all(1)
	# Légère ombre interne en bas pour effet de profondeur
	normal.shadow_color = Color(0, 0, 0, 0.3)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(0, 2)
	# Marges confortables
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	
	# === HOVER STATE ===
	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_color
	hover.set_corner_radius_all(8)
	hover.border_color = border_hover
	hover.set_border_width_all(2)
	hover.shadow_color = Color(0.3, 0.5, 0.8, 0.3)
	hover.shadow_size = 4
	hover.shadow_offset = Vector2(0, 2)
	hover.content_margin_left = 20
	hover.content_margin_right = 20
	hover.content_margin_top = 12
	hover.content_margin_bottom = 12
	
	# === PRESSED STATE ===
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = pressed_color
	pressed.set_corner_radius_all(8)
	pressed.border_color = Color(0.3, 0.4, 0.6, 0.6)
	pressed.set_border_width_all(1)
	pressed.shadow_size = 0  # Pas d'ombre quand pressé (effet "enfoncé")
	pressed.content_margin_left = 20
	pressed.content_margin_right = 20
	pressed.content_margin_top = 13  # Légèrement décalé vers le bas
	pressed.content_margin_bottom = 11
	
	# === FOCUS STATE (même que hover) ===
	var focus := hover.duplicate()
	
	# === DISABLED STATE ===
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.15, 0.15, 0.15, 0.5)
	disabled.set_corner_radius_all(8)
	disabled.border_color = Color(0.3, 0.3, 0.3, 0.3)
	disabled.set_border_width_all(1)
	disabled.content_margin_left = 20
	disabled.content_margin_right = 20
	disabled.content_margin_top = 12
	disabled.content_margin_bottom = 12
	
	# Appliquer les styles
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("disabled", disabled)
	
	# Couleurs du texte
	btn.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.85, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	
	# Taille de police
	btn.add_theme_font_size_override("font_size", 17)
	
	# Taille minimale
	btn.custom_minimum_size = Vector2(140, 45)


# Style alternatif pour boutons d'action principale (ex: "Jouer", "Continuer")
func style_primary_button(btn: Button) -> void:
	var accent := Color(0.2, 0.45, 0.7, 1.0)          # Bleu accent
	var accent_hover := Color(0.25, 0.55, 0.85, 1.0)  # Plus lumineux
	var accent_pressed := Color(0.15, 0.35, 0.55, 1.0)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent
	normal.set_corner_radius_all(8)
	normal.border_color = Color(0.4, 0.6, 0.9, 0.6)
	normal.set_border_width_all(1)
	normal.shadow_color = Color(0.1, 0.3, 0.6, 0.4)
	normal.shadow_size = 3
	normal.shadow_offset = Vector2(0, 2)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = accent_hover
	hover.set_corner_radius_all(8)
	hover.border_color = Color(0.5, 0.7, 1.0, 0.8)
	hover.set_border_width_all(2)
	hover.shadow_color = Color(0.2, 0.4, 0.8, 0.5)
	hover.shadow_size = 6
	hover.shadow_offset = Vector2(0, 3)
	hover.content_margin_left = 24
	hover.content_margin_right = 24
	hover.content_margin_top = 14
	hover.content_margin_bottom = 14
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = accent_pressed
	pressed.set_corner_radius_all(8)
	pressed.border_color = Color(0.3, 0.5, 0.7, 0.6)
	pressed.set_border_width_all(1)
	pressed.shadow_size = 0
	pressed.content_margin_left = 24
	pressed.content_margin_right = 24
	pressed.content_margin_top = 15
	pressed.content_margin_bottom = 13
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.95, 1.0))
	
	btn.add_theme_font_size_override("font_size", 18)
	btn.custom_minimum_size = Vector2(160, 50)


# Style pour boutons secondaires/danger (ex: "Quitter", "Supprimer")
func style_secondary_button(btn: Button) -> void:
	var base := Color(0.35, 0.18, 0.18, 0.9)
	var hover_col := Color(0.5, 0.22, 0.22, 1.0)
	var pressed_col := Color(0.25, 0.12, 0.12, 1.0)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = base
	normal.set_corner_radius_all(8)
	normal.border_color = Color(0.6, 0.3, 0.3, 0.5)
	normal.set_border_width_all(1)
	normal.shadow_color = Color(0.3, 0, 0, 0.3)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(0, 2)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = hover_col
	hover.set_corner_radius_all(8)
	hover.border_color = Color(0.8, 0.4, 0.4, 0.7)
	hover.set_border_width_all(2)
	hover.shadow_color = Color(0.5, 0.1, 0.1, 0.4)
	hover.shadow_size = 4
	hover.shadow_offset = Vector2(0, 2)
	hover.content_margin_left = 20
	hover.content_margin_right = 20
	hover.content_margin_top = 12
	hover.content_margin_bottom = 12
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = pressed_col
	pressed.set_corner_radius_all(8)
	pressed.border_color = Color(0.5, 0.25, 0.25, 0.6)
	pressed.set_border_width_all(1)
	pressed.shadow_size = 0
	pressed.content_margin_left = 20
	pressed.content_margin_right = 20
	pressed.content_margin_top = 13
	pressed.content_margin_bottom = 11
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	
	btn.add_theme_color_override("font_color", Color(0.95, 0.9, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	
	btn.add_theme_font_size_override("font_size", 17)
	btn.custom_minimum_size = Vector2(140, 45)
