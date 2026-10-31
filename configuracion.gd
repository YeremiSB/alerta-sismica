extends Control

@onready var input_numero = $InputNumero
@onready var boton_guardar_numero = $BotonGuardarNumero
@onready var label_confirmacion = $LabelConfirmacion
@onready var boton_cerrar = $BotonCerrar

var numero_contacto := ""
var config := ConfigFile.new()
const RUTA_CONFIG := "user://ajustes.cfg"

signal numero_actualizado(numero: String)

func _ready():
	visible = false
	label_confirmacion.visible = false
	cargar_numero()

func cargar_numero():
	var err = config.load(RUTA_CONFIG)
	if err == OK:
		numero_contacto = config.get_value("contacto", "numero", "")
		input_numero.text = numero_contacto

func _on_boton_guardar_numero_pressed():
	var numero_ingresado: String = input_numero.text.strip_edges()
	if numero_ingresado == "":
		return
	numero_contacto = numero_ingresado
	config.set_value("contacto", "numero", numero_contacto)
	config.save(RUTA_CONFIG)
	label_confirmacion.text = "Numero guardado ✓"
	label_confirmacion.visible = true
	numero_actualizado.emit(numero_contacto)

func _on_boton_cerrar_pressed():
	hide()
