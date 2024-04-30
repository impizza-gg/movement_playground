extends Node

@export var push_to_talk := false

@onready var input : AudioStreamPlayer = $Input
var recordBusIndex : int
var captureEffect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback
var inputThreshold := 0.005
var receiveBuffer := PackedFloat32Array()
var captureIndex : int

var delay_on := false
var capturing := true

func _ready() -> void:
	setupAudio()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mic"):
		capturing = not capturing
		AudioServer.set_bus_effect_enabled(recordBusIndex, 1, capturing)
	elif event.is_action_pressed("delay_effect"):
		delay_on = not delay_on
		AudioServer.set_bus_effect_enabled(recordBusIndex, 0, delay_on)
	
	
func setupAudio() -> void:
	input.stream = AudioStreamMicrophone.new()
	input.play()
	
	recordBusIndex = AudioServer.get_bus_index("Record")
	captureIndex = AudioServer.get_bus_effect_count(recordBusIndex) - 1
	
	if push_to_talk:
		AudioServer.set_bus_effect_enabled(recordBusIndex, captureIndex, 0)
		
	# Efeito Capture deve sempre ser o último no bus Record
	captureEffect = AudioServer.get_bus_effect(recordBusIndex, captureIndex)
	playback = $AudioStreamPlayer.get_stream_playback()


func _process(delta: float) -> void:
	if push_to_talk:
		if Input.is_action_pressed("push_to_talk"):
			AudioServer.set_bus_effect_enabled(recordBusIndex, captureIndex, 1)
		else:
			AudioServer.set_bus_effect_enabled(recordBusIndex, captureIndex, 0)
		
	process_mic()
	process_incoming()
	
	
#func set_record_effect(index: int, val := true):
	#AudioServer.set_bus_effect_enabled(recordBusIndex, index, val)
	
	
func process_mic() -> void:
	if not capturing:
		return
		
	var stereoData : PackedVector2Array = captureEffect.get_buffer(captureEffect.get_frames_available())
	
	if stereoData.size() > 0:
		var data = PackedFloat32Array()
		data.resize(stereoData.size())
		var maxAmplitude := 0.0
		
		for i in range(stereoData.size()):
			var value = (stereoData[i].x + stereoData[i].y) / 2
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
			
		if maxAmplitude < inputThreshold:
			return
			
		sendData.rpc(data)
		
		
func process_incoming() -> void:
	if receiveBuffer.size() <= 0:
		return
		
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)
	
	
@rpc("any_peer", "call_remote", "unreliable_ordered")
func sendData(data: PackedFloat32Array):
	receiveBuffer.append_array(data)
		
