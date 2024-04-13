extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry: LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const Player = preload("res://Scenes/Player/player.tscn")

var NumberofPlayers : int

var secret_key

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connected_to_server.connect(connected_to_server)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_option_button_item_selected(index: int) -> void:
	NumberofPlayers = int($CanvasLayer/MainMenu/MarginContainer/VBoxContainer/OptionButton.get_item_text(index))

func _on_host_button_pressed() -> void:
	main_menu.hide()
	
	enet_peer.create_server(PORT, 10)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	
	
	add_player(multiplayer.get_unique_id())
	upnp_setup()
	StartGame.rpc()
	SendPlayerInformation($CanvasLayer/MainMenu/MarginContainer/VBoxContainer/NameEntry.text, multiplayer.get_unique_id())

func decodes_for_address():
	secret_key = address_entry.text

func connected_to_server():
	print("Connected to server")
	SendPlayerInformation.rpc_id(1, $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/NameEntry.text, multiplayer.get_unique_id())


func _on_join_button_pressed() -> void:
	main_menu.hide()
	
	decodes_for_address()
	var decoded_address = decode(secret_key)
	StartGame.rpc()
	
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)

@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id]= {
			"name" : $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/NameEntry.text,
			"id" : id,
			"score" : 0
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)
	
	 

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

@rpc("any_peer", "call_local")
func StartGame():
	var scene = preload("res://Scenes/stage.tscn").instantiate()
	get_tree().root.add_child(scene)
	print("start game")

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
# Define a secret key for encoding and decoding
# Original UPnP address
	var upnp_address = upnp.query_external_address()  # Example UPnP address
		# Encode the UPnP address into a secret code
	var secret_code = encode(upnp_address)
	print("Secret code:", secret_code)
		
		# Decode the secret code back into the original UPnP address

# Function to encode the UPnP address into a secret code
func encode(address: String) -> String:
	var encoded_address = ""
	for i in range(address.length()):
		var char_code = (address[i]).to_ascii_buffer()[0] + 1
		encoded_address += str(char_code)
	return encoded_address

# Function to decode the secret code back into the original UPnP address
func decode(code: String) -> String:
	var decoded_address = ""
	for i in range(0, code.length(), 2):
		var char_code = int(code.substr(i, 2)) - 1
		decoded_address += String.chr(char_code)
	return decoded_address


