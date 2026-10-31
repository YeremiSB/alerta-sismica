extends Control

@onready var label_estado = $LabelEstado
@onready var label_magnitud = $LabelMagnitud
@onready var fondo = $TextureRect
@onready var sonido = $AudioStreamPlayer
@onready var barra_vibracion = $BarraVibracion
@onready var boton_sms = $BotonSMS
@onready var configuracion = $Configuracion

var umbral := 3.0                
var tiempo_sobre_umbral := 0.0
var duracion_minima := 0.10   
var tiempo_bajo_umbral := 0.0
var tiempo_gracia := 0.3          
var numero_contacto := ""
var en_alerta := false

func _ready():
	configuracion.numero_actualizado.connect(_on_numero_actualizado)
	numero_contacto = configuracion.numero_contacto

	label_estado.text = "Monitoreando..."
	fondo.modulate = Color.WHITE
	boton_sms.visible = false
	barra_vibracion.min_value = 0
	barra_vibracion.max_value = 20

	boton_sms.pressed.connect(_on_boton_sms_pressed)

func _process(delta):
	var accel = Input.get_accelerometer()
	var magnitud = accel.length() - 9.8   #estoy restando la gravedad para solo tener de referencia el impacto
	label_magnitud.text = "Magnitud: %.2f" % magnitud
	barra_vibracion.value = magnitud

	if magnitud > umbral:
		tiempo_sobre_umbral += delta
		tiempo_bajo_umbral = 0.0
		if tiempo_sobre_umbral >= duracion_minima and not en_alerta:
			activar_alerta()
	else:
		tiempo_sobre_umbral = 0.0
		if en_alerta:
			tiempo_bajo_umbral += delta
			if tiempo_bajo_umbral >= tiempo_gracia:
				resetear_estado()

func activar_alerta():
	en_alerta = true
	label_estado.text = "¡ALERTA SÍSMICA!"
	fondo.modulate = Color.RED
	sonido.stop()   
	sonido.play()
	Input.vibrate_handheld(500)
	boton_sms.visible = true

func resetear_estado():
	en_alerta = false
	label_estado.text = "Monitoreando..."
	fondo.modulate = Color.WHITE
	boton_sms.visible = false
	sonido.stop()  

func _on_boton_sms_pressed():
	if numero_contacto == "":
		_on_boton_config_pressed()
		return

	var mensaje := "ALERTA SÍSMICA detectada por mi app. Necesito confirmar que estoy bien, por favor contáctame."
	var mensaje_codificado := mensaje.uri_encode()
	var uri := "sms:" + numero_contacto + "?body=" + mensaje_codificado
	OS.shell_open(uri)

func _on_boton_config_pressed():
	configuracion.visible = true

func _on_numero_actualizado(numero: String):
	numero_contacto = numero
