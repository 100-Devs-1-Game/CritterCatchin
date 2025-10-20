extends Node

@warning_ignore("unused_signal")
signal bug_caught
@warning_ignore("unused_signal")
signal level_started(difficulty: int)
@warning_ignore("unused_signal")
signal stage_begun
@warning_ignore("unused_signal")
signal level_ended
@warning_ignore("unused_signal")
signal add_bug()
@warning_ignore("unused_signal")
signal special_removed
@warning_ignore("unused_signal")
signal wrong_click
@warning_ignore("unused_signal")
signal pauser_removed
@warning_ignore("unused_signal")
signal sound_request(sound: String)
@warning_ignore("unused_signal")
signal menu_closed
@warning_ignore("unused_signal")
signal warning_closed(confirmed: bool)
@warning_ignore("unused_signal")
signal special_bug_caught
@warning_ignore("unused_signal")
signal announce_unlock

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
