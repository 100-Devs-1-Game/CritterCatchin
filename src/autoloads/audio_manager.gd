extends Node

const MUSIC = preload("res://audio/music.tscn")

func _ready() -> void:
	var c = MUSIC.instantiate()
	c.bus = "Music"
	c.finished.connect(func(): c.play())
	_send_to_root(c)

## Accepts either a string path to a sound or an AudioStream, creates and plays them globally
func play_sound(sound) -> void:
	var p = AudioStreamPlayer.new()
	p.stream = sound if sound is AudioStream else load(sound)
	_send_to_root(p)
	p.volume_db = -14.0
	p.call_deferred("play")
	p.bus = "SFX"
	p.finished.connect(func(): p.queue_free())


## Sends the freshly created AudioStreamPlayer to root
func _send_to_root(node: Node) -> void:
	get_tree().root.call_deferred("add_child", node)
