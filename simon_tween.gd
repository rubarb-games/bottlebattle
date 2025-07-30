extends Node

var activeTweens:Array = []

var verbose_output:bool = false


enum State { PLAYING, PAUSED, IDLE, STEPPED }
enum Mode {NORMAL, PINGPONG, LOOPING, REVERSED, LOOPING_PINGPONG}
var ts:State = State.IDLE
var tt = Mode.NORMAL

signal tweenDone
signal tweenDoneFullChain
signal tweenResumed
signal tweenPaused
signal fullChainLoopDone

var revise_tween_list: bool = false

class singleTween:
	
	var verbose_debug:bool = false
	
	var ts:State = State.IDLE
	var tt = Mode.NORMAL
	var isRelative:bool = false
	var isFullChainLooping:bool = false

	var obj:Node
	var pPath:NodePath
	var rawProperty:String
	var endResult
	var time:float = 1.0
	var time_elapsed:float = 0.0
	var intCurve:Curve
	var modDValue
	var initialValue
	var loops:int = 0
	var breakLoop:bool = false
	var snap_to_value:bool = false
	var snap_to_start_value:bool = false

	var deltaValue:float
	var totalTweenMovement:Variant
	var sceneTreeHandle:SceneTree
	
	var last_tweened_property
	
	var indexed_property = true
	
	var is_tween_active = false
	var is_tween_finished = false
	var is_subsequent_tween = false
	var subsequent_tweens = []

	signal tween_finished
	signal tween_looped
	signal new_subsequent_tween(tween:singleTween)
	
	func another():
		var a = singleTween.new()
		a.is_subsequent_tween = true
		subsequent_tweens.append(a)
		return a

	func set_relative(rel):
		isRelative = rel
		return self
		
	func set_start_snap(s:bool):
		snap_to_start_value = s
		return self
	
	func set_end_snap(s:bool):
		snap_to_value = s
		return self
		
	func set_loops(l):
		loops = l
		return self

	func start_tween(objArg:Object,propPath:String,endResultArg,timeArg,intCurveArg,typ = Mode.NORMAL):

		if (time <= 0 or time > 100):
			return self
		
		if (!intCurveArg):
			intCurve = Curve.new()
			intCurve.add_point(Vector2(0,0))
			intCurve.add_point(Vector2(1,1))
		else:
			intCurve = intCurveArg
		
		tt = typ
		
		obj = objArg
		rawProperty = propPath
		#pPath = NodePath(propPath)
		
		if (verbose_debug):
			print_rich("[color=AQUA] Testing "+str(rawProperty))
		if (rawProperty in obj):
			indexed_property = false
		else:
			print("Dealing with indexed property")
			
		time = timeArg
		endResult = endResultArg
	
		if (!is_subsequent_tween):
			initiate_tween()
		
		return self
		
	func get_tweened_value():
		if (!is_instance_valid(obj)):
			force_finish_tween()
			
		if (indexed_property and !is_tween_finished):
			last_tweened_property = obj.get_indexed(rawProperty)
		elif (!is_tween_finished):
			last_tweened_property = obj.get(rawProperty)
			
		return last_tweened_property
		
	func set_tweened_value(val):
		if (!is_instance_valid(obj)):
			return
		
		if (indexed_property):
			obj.set_indexed(rawProperty,val)
		else:
			obj.set(rawProperty,val)

	func initiate_tween():
		deltaValue = 0
		modDValue = get_tweened_value() - get_tweened_value()
		time_elapsed = 0
		initialValue = get_tweened_value()
		is_tween_finished = false
		is_tween_active = true

	func process_tween(delta):
		#if tween is paused
		if (!is_tween_active):
			return false
				
		#Cache previous frame modified delta value
		var prevMod = modDValue
		#New var to be modified with offset
		var factor = clamp(time_elapsed/time,0,1)
		if (tt == Mode.PINGPONG):
			factor = factor if factor < 1 else 2 - factor
		var modDMod = (intCurve.sample(factor) * endResult)
		
		if (verbose_debug):
			print_rich("[color=AQUA] Time: "+str(time_elapsed)+" / "+str(time)+" * "+str(endResult)+" = "+str(modDMod)+" And the actual result is... "+str(get_tweened_value()))
		modDValue = modDMod
		
		#Relative accounts for other transformations happening inbetween by offsetting the animation by previous frame's transform
		if (isRelative):
			var deltaMod = modDMod - prevMod
			modDMod = get_tweened_value() + deltaMod
		else:
			modDMod = lerp(get_tweened_value(),endResult,intCurve.sample(factor))

		set_tweened_value(modDMod)
		
		return check_tween_condition(delta)
			
	func check_tween_condition(delta):
		time_elapsed += delta
		match tt:
			Mode.NORMAL:
				if time_elapsed >= time or breakLoop:
					return finish_tween()
			Mode.PINGPONG:
				if time_elapsed >= (time * 2) or breakLoop:
					return finish_tween()
			Mode.LOOPING:
				if ((time_elapsed/time >= loops) and loops != -1) or breakLoop:
					return finish_tween()
		return false
	
	func restart_tween():
		initiate_tween()
		return self
		
	func pause():
		is_tween_active = false
		return self
		
	func play():
		is_tween_active = true
		return self
			
	func finish_tween(skip_all:bool = false):
		#Looping
		if (!breakLoop):
			if (loops > 0):
				loops -= 1
				restart_tween()
				return false
		
		if (snap_to_value):
			set_tweened_value(endResult)
		
		if (snap_to_start_value):
			set_tweened_value(initialValue)
		
		is_tween_finished = true
		tween_finished.emit()
		
		return true

	func force_finish_tween():
			is_tween_finished = true
			tween_finished.emit()
			
			return true

func _process(delta: float) -> void:
	for tween in activeTweens:
		#If the tween is finished
		if (tween.process_tween(delta)):
			if (verbose_output):
				print_rich("[color=AQUA] tween is finished...")
			#Start next tween if there's more subsequent ones - If there are, trigger all of them
			if (tween.subsequent_tweens.size() > 0):
				for t in tween.subsequent_tweens:
					activeTweens.append(t)
					t.initiate_tween()
			revise_tween_list = true
			
	#Build new list consisting of only unfinished tweens.
	if revise_tween_list:
		activeTweens = activeTweens.filter(func(tw): return tw.is_tween_finished == false)
		revise_tween_list = false

func start_tween(objArg:Node, propPath:String, endResultArg, timeArg:float = 1, intCurveArg:Curve = null, typ = Mode.NORMAL):
	if (verbose_output):
		print_rich("[color=CORAL][font_size=32] Stating new tween on object: "+str(objArg.name)+" to modify attribute "+str(propPath)+" to value "+str(endResultArg)+" ! Sounds good")
	
	var tween = singleTween.new()
	activeTweens.append(tween)
	tween.start_tween(objArg,propPath,endResultArg,timeArg,intCurveArg,typ)
	return tween
