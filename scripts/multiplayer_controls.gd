extends Node

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@onready var AudioManager := $"../AudioManager"

func _on_host_button_pressed() -> void:
	var ip : String
	if OS.has_feature("windows"):
		ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)
	else:
		ip = IP.resolve_hostname(str(OS.get_environment("HOSTNAME")), IP.TYPE_IPV4)
	# https://forum.godotengine.org/t/how-to-get-local-ip-address/10399/2
		
	var port = $HostPort_Input.text
	var HOST_ERROR = peer.create_server(int(port))
	
	if HOST_ERROR != OK:
		print("NETWORK: HOST ERROR")
		return
		
	$IP_Label.text = ip + ":" + port
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.server_disconnected.connect(server_disconnected)
	AudioManager.set_multiplayer_id("1")
	add_player()
	


func connected_to_server():
	print("Connected to server")
	var id := multiplayer.get_unique_id()
	AudioManager.set_multiplayer_id(str(id))


func peer_connected(id = 1): 
	if multiplayer.is_server():
		rpc_id(id, "add_initial_buffers", multiplayer.get_peers())
		add_new_player_buffer.rpc(id)
	add_player(id)


func peer_disconnected(id):
	# TODO: retirar o nodo do jogador do mundo quando ele desconecta.
	print("Peer disconnected: " + str(id))


func server_disconnected():
	# TODO: mandar o jogador para menu principal quando o servidor desconecta
	print("Server disconnected")
	

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# TODO: Trocar isso por outro método que seja menos dependente da configuração da árvore de nodos
	var parent = get_parent()
	parent.call_deferred("add_child", player)


func _on_join_button_pressed() -> void:
	var ip = $IP_Input.text
	var port = int($JoinPort_Input.text)
	
	var JOIN_ERROR = peer.create_client(ip, port)
	if JOIN_ERROR != OK:
		print("NETWORK: JOIN ERROR")
		return
		
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(connected_to_server)


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set($IP_Label.text)


func _on_paste_button_pressed() -> void:
	var fullIp = DisplayServer.clipboard_get()
	var split = fullIp.split(":")
	if split.size()  > 1:
		$IP_Input.text = split[0]
		$JoinPort_Input.text = split[1]


@rpc("authority", "call_local", "reliable")
func add_new_player_buffer(id: int):
	if id != multiplayer.get_unique_id():
		AudioManager.add_buffer(str(id))


@rpc("authority", "call_remote", "reliable")
func add_initial_buffers(ids: PackedInt32Array):
	var own_id := multiplayer.get_unique_id()
	var host_id := multiplayer.get_remote_sender_id()
	AudioManager.add_buffer(str(host_id))
	for id in ids:
		if id != own_id:
			AudioManager.add_buffer(str(id))
