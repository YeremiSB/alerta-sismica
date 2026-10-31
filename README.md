# Alerta Sísmica

App de Android hecha en Godot 4 que usa el **acelerómetro del teléfono** para detectar
sacudidas: cuando la magnitud supera un umbral, suena una sirena, vibra el móvil y aparece un
botón para avisar por SMS a un contacto guardado.

> **Aviso honesto:** esto **no** detecta sismos por red sísmica ni avisa de un terremoto que
> ocurre a 100 km. Detecta que *tu* teléfono se está moviendo. Sirve como alarma local de
> sacudida, como proyecto de aprendizaje, no como sistema de alerta temprana.

---

## Estado

| | |
|---|---|
| Motor | Godot **4.6** (renderer `mobile`, Jolt Physics) |
| Plataforma objetivo | Android (necesita acelerómetro) |
| Scripts | 2 (`main.gd`, `configuracion.gd`) |
| Compilado | **No.** `export_presets.cfg` existe pero nunca se exportó; no hay APK |
| Probado en dispositivo | **No** |
| Tests | Ninguno |
| Licencia | Sin definir todavía |

## Cómo funciona

1. `main.gd` lee `Input.get_accelerometer()` cada frame y le resta la gravedad
   (`accel.length() - 9.8`) para quedarse con el "impacto".
2. Si esa magnitud supera `umbral = 3.0` durante al menos `0.10 s`, se dispara la alerta.
3. La alerta pone el fondo rojo, reproduce `alert.wav`, hace vibrar el móvil 500 ms y muestra
   el botón de SMS.
4. Tras `0.3 s` por debajo del umbral, vuelve a "Monitoreando".
5. `configuracion.gd` guarda el número de contacto en `user://ajustes.cfg` con `ConfigFile`.
6. El botón de SMS abre la app de mensajes con el texto ya escrito mediante
   `OS.shell_open("sms:<numero>?body=...")`.

## Cómo abrirlo

Requisitos: Godot 4.6 y, para probarlo de verdad, un Android con acelerómetro.

```bash
# abrir el proyecto
godot --path . --editor

# exportar a APK (necesita Android build template instalado)
godot --headless --export-release "Android" alerta-sismica.apk
```

**En PC no vas a ver nada moverse:** `Input.get_accelerometer()` devuelve vector cero en
escritorio, así que la app se queda en "Monitoreando..." para siempre. Es la primera cosa a
arreglar (ver abajo).

## Dónde lo dejé

Lo dejé justo cuando ya funcionaba la lógica y faltaba todo lo demás:

- **No hay APK.** `export_presets.cfg` está, pero nunca se compiló ni se probó en un teléfono.
- **No se puede probar sin móvil.** No existe un modo de depuración que simule el acelerómetro.
- **La calibración es a ojo.** `umbral = 3.0` y `duracion_minima = 0.10` los elegí sin medir
  nada: ni una sola sacudida real registrada, ni datos de sismos para contrastar.
- **La etiqueta "Magnitud" engaña.** No es la magnitud de Richter: es la desviación de la
  aceleración respecto a `9.8 m/s²`, en `m/s²`. Un sismo de 4.0 y uno de 7.0 pueden mover tu
  teléfono exactamente igual.
- **Sin monitoreo en segundo plano.** Si la app no está abierta (o Android la duerme), no
  alerta nada. Falta un servicio en primer plano.
- **El SMS no se envía solo.** Solo abre la app de mensajes con el texto escrito; el usuario
  tiene que pulsar enviar.
- **Sin notificaciones ni permisos declarados** en el preset de export.
- **Nombres de assets ilegibles:** `0aaa8f1e6f22f8047f9d821062c23919-removebg-preview.png` y
  `1000055564.jpeg`. Renombrarlos **desde el editor de Godot** (si los cambias a mano desde el
  explorador rompes las referencias y los `.import`).
- **Sin tests.** La máquina de estados (umbral → duración mínima → tiempo de gracia) es lógica
  pura y se puede testear sin acelerómetro.
- **Solo español, hardcodeado.** Sin archivos de traducción.
- **La fuente DS-DIGI es de uso personal.** Antes de distribuir el APK hay que revisar su
  licencia o cambiarla por una libre (Google Fonts).

## Lista para retomar

1. Modo debug: un `HSlider` que inyecte una magnitud falsa, para probar la alarma entera en PC.
2. Exportar el APK y probarlo en un teléfono real durante una semana.
3. Registrar las sacudidas en CSV y recalibrar el umbral con esos datos.
4. Cambiar la etiqueta "Magnitud" por algo que no se confunda con la escala de Richter
   (ej. "Sacudida: 3.2 m/s²").
5. Notificación local + canal de Android, y servicio en primer plano para que no muera en
   segundo plano.
6. Envío automático del SMS (o al menos `SmsManager` en vez de `OS.shell_open`).
7. Tests de la máquina de estados, sin necesidad de Godot.
8. Renombrar assets y definir licencia del proyecto.

## Estructura

```
main.gd            lógica del acelerómetro, umbral y alerta
configuracion.gd   guarda el número de contacto (user://ajustes.cfg)
main.tscn          pantalla principal
configuracion.tscn panel de ajustes
aero.gdshader      shader del fondo (estética Frutiger Aero)
alert.wav          sirena
```

Hecho por **Yeremi S. BΛSTIAN** — Quillabamba, Perú · [yeremisb.com](https://yeremisb.com)
