extends Node

@export var push_to_talk := false

@onready var input : AudioStreamPlayer = $Input
var stream_player_scene = preload("res://scenes/audio_stream_player.tscn") 

var recordBusIndex : int
var captureEffect : AudioEffectCapture
var inputThreshold := 0.005

# Talvez trocar os dicionários por um número fixo de buffers e playbacks
var playback_array : Dictionary
var receiveBuffers : Dictionary

var activeBuffers := 0
var multiplayer_id : String
var captureIndex : int

var delay_on := false
var capturing := true

func _ready() -> void:
	setupAudio()


func set_multiplayer_id(id: String):
	multiplayer_id = id


func add_buffer(id: String) -> void:
	print("Adding buffer for player: " + id)
	receiveBuffers[id] = PackedFloat32Array()
	print(receiveBuffers)
	
	var stream_player = stream_player_scene.instantiate()
	add_child(stream_player)
	playback_array[id] = stream_player.get_stream_playback()
	activeBuffers += 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mic"):
		capturing = not capturing
		AudioServer.set_bus_effect_enabled(recordBusIndex, captureIndex, capturing)
	elif event.is_action_pressed("delay_effect"):
		delay_on = not delay_on
		AudioServer.set_bus_effect_enabled(recordBusIndex, 0, delay_on)
		AudioServer.set_bus_effect_enabled(recordBusIndex, 1, delay_on)
	
	
func setupAudio() -> void:
	input.stream = AudioStreamMicrophone.new()
	input.play()
	
	recordBusIndex = AudioServer.get_bus_index("Record")
	captureIndex = AudioServer.get_bus_effect_count(recordBusIndex) - 1
	
	if push_to_talk:
		AudioServer.set_bus_effect_enabled(recordBusIndex, captureIndex, 0)
		
	# Efeito Capture deve sempre ser o último no bus Record
	captureEffect = AudioServer.get_bus_effect(recordBusIndex, captureIndex)


func _process(_delta: float) -> void:
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
			
		# Não envia dados quando a entrada é muito baixa
		if maxAmplitude < inputThreshold:
			return
			
		sendData.rpc(data, multiplayer_id)
		
		
func process_incoming() -> void:
	for id in receiveBuffers:
		var buffer = receiveBuffers[id]
		if buffer.size() <= 0:
			continue
		
		var playback = playback_array[id]
		for i in range(min(playback.get_frames_available(), buffer.size())):
			playback.push_frame(Vector2(buffer[0], buffer[0]))
			buffer.remove_at(0)
	
	
@rpc("any_peer", "call_remote", "unreliable_ordered")
func sendData(data: PackedFloat32Array, id):
	if receiveBuffers.is_empty():
		return

	receiveBuffers[id].append_array(data)
		
