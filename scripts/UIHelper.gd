extends Node

# Helper function to style buttons consistently across the game
func style_button(btn: Button, theme_override: Theme = null) -> void:
	if theme_override == null:
		theme_override = Theme.new()
	
	# Sleek dark theme with subtle styling
	var normal_color = Color(0.15, 0.15, 0.15, 0.9)      # Dark gray
	var hover_color = Color(0.25, 0.25, 0.25, 0.95)      # Slightly lighter
	var pressed_color = Color(0.1, 0.1, 0.1, 1.0)        # Even darker
	var text_color = Color(0.95, 0.95, 0.95, 1.0)        # Off-white
	
	# Set font size
	theme_override.set_font_size("font_sizes", "Button", 18)
	
	# Set button states via StyleBox — subtle, no heavy borders
	var normal_stylebox = StyleBoxFlat.new()
	normal_stylebox.bg_color = normal_color
	normal_stylebox.set_corner_radius_all(4)
	normal_stylebox.content_margin_left = 12
	normal_stylebox.content_margin_right = 12
	normal_stylebox.content_margin_top = 8
	normal_stylebox.content_margin_bottom = 8
	
	var hover_stylebox = StyleBoxFlat.new()
	hover_stylebox.bg_color = hover_color
	hover_stylebox.set_corner_radius_all(4)
	hover_stylebox.content_margin_left = 12
	hover_stylebox.content_margin_right = 12
	hover_stylebox.content_margin_top = 8
	hover_stylebox.content_margin_bottom = 8
	
	var pressed_stylebox = StyleBoxFlat.new()
	pressed_stylebox.bg_color = pressed_color
	pressed_stylebox.set_corner_radius_all(4)
	pressed_stylebox.content_margin_left = 12
	pressed_stylebox.content_margin_right = 12
	pressed_stylebox.content_margin_top = 8
	pressed_stylebox.content_margin_bottom = 8
	
	theme_override.set_stylebox("normal", "Button", normal_stylebox)
	theme_override.set_stylebox("hover", "Button", hover_stylebox)
	theme_override.set_stylebox("pressed", "Button", pressed_stylebox)
	theme_override.set_stylebox("focus", "Button", hover_stylebox)
	theme_override.set_color("font_color", "Button", text_color)
	
	btn.theme = theme_override
	btn.custom_minimum_size = Vector2(120, 40)
