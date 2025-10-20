extends Panel
class_name DiscordPanelButton

@onready var button: TextureButton = $"DiscordButton"
@export var animator: AnimationPlayer
@export var animation_name: String = "default"

var sb: StyleBoxFlat
var tween_scale: Tween
var tween_color: Tween

@export var shadow_color_grow: Color = Color(1,0,0,0.6)
@export var shadow_color_shrink: Color = Color(0,0,0,0.6)
@export var shadow_size_idle: float = 0.0
@export var shadow_size_hover: float = 18.0

@export var corner_radius: Vector4 = Vector4(16,16,16,16) # TL, TR, BL, BR
@export var panel_scale_hover: Vector2 = Vector2(1.05,1.05)
@export var tween_time: float = 0.3
@export var tween_loop: bool = true

@export var url: String = "https://discord.gg/UHN4AjMw4d"

var confirmed_animation: bool = false

func _ready() -> void:
	if not is_instance_valid(button):
		for c in get_children():
			if c is TextureButton:
				button = c
				break

	var base_sb := get_theme_stylebox("panel")
	if base_sb is StyleBoxFlat:
		sb = (base_sb as StyleBoxFlat).duplicate()
	else:
		sb = StyleBoxFlat.new()
	add_theme_stylebox_override("panel", sb)

	sb.shadow_color = shadow_color_shrink
	sb.shadow_size = shadow_size_idle
	sb.shadow_offset = Vector2.ZERO

	sb.corner_radius_top_left = corner_radius.x
	sb.corner_radius_top_right = corner_radius.y
	sb.corner_radius_bottom_left = corner_radius.z
	sb.corner_radius_bottom_right = corner_radius.w

	pivot_offset = size * 0.5

	if is_instance_valid(button):
		button.mouse_entered.connect(_on_enter)
		button.mouse_exited.connect(_on_exit)
		button.pressed.connect(_on_pressed)
	else:
		push_warning("DiscordPanelButton: No child TextureButton found. Hover/press won't work.")

	sb.shadow_color = shadow_color_shrink
	sb.shadow_size = shadow_size_idle
	scale = Vector2.ONE

func _on_enter() -> void:
	if tween_scale:
		tween_scale.kill()
	if tween_color:
		tween_color.kill()

	tween_scale = create_tween()
	if tween_loop:
		tween_scale.set_loops()
	tween_scale.tween_property(self, "scale", panel_scale_hover, tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_scale.tween_property(self, "scale", Vector2.ONE, tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_start_shadow_color_cycle()

	#below chhecks for the given anim_name, if not valid it will try to find the next valid one for you
	if animator:
		if animation_name != "" and animator.has_animation(animation_name):
			animator.play(animation_name)
			confirmed_animation = true
		else:
			var anim_list = animator.get_animation_list()
			var first_anim: String = ""

			for anim_name in anim_list:
				if anim_name.to_upper() != "RESET":
					first_anim = anim_name
					break

			if first_anim == "" and anim_list.size() > 0:
				first_anim = anim_list[0]

			if first_anim != "":
				if animation_name != first_anim:
					push_warning("Animation '%s' not found. Defaulting to '%s'." % [animation_name, first_anim])
				animation_name = first_anim
				animator.play(animation_name)
				confirmed_animation = true
			else:
				push_warning("Animator '%s' contains no animations." % animator.name)


func _start_shadow_color_cycle() -> void:
	if not sb:
		return
	if tween_color:
		tween_color.kill()

	tween_color = create_tween()
	if tween_loop:
		tween_color.set_loops()

	sb.shadow_size = shadow_size_hover

	tween_color.tween_property(sb, "shadow_color", shadow_color_grow, tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_color.tween_property(sb, "shadow_color", shadow_color_shrink, tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_exit() -> void:
	if tween_scale:
		tween_scale.kill()
		tween_scale = null
	if tween_color:
		tween_color.kill()
		tween_color = null

	sb.shadow_color = shadow_color_shrink
	sb.shadow_size = shadow_size_idle
	scale = Vector2.ONE

	if animator and confirmed_animation:
		animator.play_backwards(animation_name)

func _on_pressed() -> void:
	if url != "":
		OS.shell_open(url)
