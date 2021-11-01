# This is a workaround to keep Debugger panel opened in Output when a scene runs.
# As you can see this requres calling _process(), because there are no scene_runned and scene_stopped signals
# the implementation looks really weird.
# I really think this should be done (fixed?) in core, not with a plugin.

tool
extends EditorPlugin

var debugger_control:Control

# idle frames.
# this is for reopening recent Debugger tab (Debugger,  Errors, Profiler..).
# If the recent tab isn't reopened
# (instead it always resets to the first tab named Debugger), try some greater values
export var frames_to_wait_before_restore_tab: = 7

# wait time between debugger hidden scene start running.
# we need to know if the debugger is hidden because of a scene run (then we want to re reopen it)
# or hidden by the user (then do nothing).
export var wait_time: = 0.2


#===================== Add scene_run, scene_stopped signals ====================

signal scene_run()
signal scene_stopped()

var is_playing_scene = get_editor_interface().is_playing_scene()

func _process(delta):
	if get_editor_interface().is_playing_scene():
		if !is_playing_scene:
			emit_signal("scene_run")
			is_playing_scene = true
	elif is_playing_scene:
		emit_signal("scene_stopped")
		is_playing_scene = false

#===============================================================================


# called when a scene runs and Debugger was hidden by Godot, not by the user
func on_debugger_was_auto_hidden():
	var tab_cont:TabContainer = get_child_by_class(debugger_control, 'TabContainer')
	var tab = tab_cont.current_tab

	make_bottom_panel_item_visible(debugger_control)

	for i in frames_to_wait_before_restore_tab:
		yield(get_tree(), "idle_frame")

	tab_cont.current_tab = tab




func on_debugger_hide():
	
	var tab_cont:TabContainer = get_child_by_class(debugger_control, 'TabContainer')
	var tab = tab_cont.current_tab
	
	connect_once_for_time(wait_time, self, "scene_run", self, 'on_debugger_was_auto_hidden')
	connect_once_for_time(wait_time, self, "scene_stopped", self, 'on_debugger_was_auto_hidden')


func _enter_tree():
	var base = get_editor_interface().get_base_control()

	var controls_container = get_bottom_panel_controls_container(base)
	debugger_control = get_child_by_class(controls_container, 'ScriptEditorDebugger')

	debugger_control.connect("hide", self, 'on_debugger_hide')



func _exit_tree():
	pass





#==================== Utils ========================

func connect_once_for_time(time:float, signal_obj:Object, signal_name:String, callback_obj:Object, callback_name:String,   args:=[]):
	signal_obj.connect(signal_name, callback_obj, callback_name, args, CONNECT_ONESHOT)
	yield(get_tree().create_timer(time), "timeout")
	if signal_obj.is_connected(signal_name, callback_obj, callback_name):
		signal_obj.disconnect(signal_name, callback_obj, callback_name)



static func get_child_by_class(node:Node, cls:String):
	for child in node.get_children():
		if child.get_class() == cls:
			return child



static func get_node_by_class_path(node:Node, class_path:Array)->Node:
	var res:Node

	var stack = []
	var depths = []

	var first = class_path[0]
	for c in node.get_children():
		if c.get_class() == first:
			stack.push_back(c)
			depths.push_back(0)

	if not stack: return res
	
	var max_ = class_path.size()-1

	while stack:
		var d = depths.pop_back()
		var n = stack.pop_back()

		if d>max_:
			continue
		if n.get_class() == class_path[d]:
			if d == max_:
				res = n
				return res

			for c in n.get_children():
				stack.push_back(c)
				depths.push_back(d+1)

	return res




static func get_bottom_panel_controls_container(base:Control)->VBoxContainer:
	var result: VBoxContainer = get_node_by_class_path(
		base, [
			'VBoxContainer', 
			'HSplitContainer',
			'HSplitContainer',
			'HSplitContainer',
			'VBoxContainer',
			'VSplitContainer',
			'PanelContainer',
			'VBoxContainer',
		]
	)
	return result
