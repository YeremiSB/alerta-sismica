# Alerta Sísmica

App de Android hecha en Godot 4 que usa el **acelerómetro del teléfono** para detectar
sacudidas: cuando la magnitud supera un umbral, suena una sirena, vibra el móvil y aparece un
botón para avisar por SMS a un contacto guardado.

Nació como **proyecto escolar de innovación tecnológica** (FENCYT 2026, Categoría E) en la
I.E.P. La Salle Quillabamba, con la idea de aprovechar un sensor que ya trae cualquier celular
en vez de depender de sismógrafos caros.

> **Aviso honesto:** esto **no** predice sismos ni consulta ninguna red sísmica. Detecta que
> *tu* teléfono se está moviendo. Sirve como alarma local de sacudida y como proyecto de
> aprendizaje, no como sistema de alerta temprana.

---

## La idea científica

Un sismo genera dos tipos de ondas, una tras otra:

- **Ondas P** (primarias): llegan primero, viajan más rápido y apenas se sienten.
- **Ondas S** (secundarias): llegan después y son las que producen la sacudida destructiva.

La distancia entre una y otra puede ser de segundos, y ahí está la promesa del proyecto: si
detectas el inicio de las P, puedes avisar antes de que llegue lo fuerte. El sensor que lo haría
posible es el **acelerómetro MEMS** que casi todo smartphone trae de fábrica, con una precisión
típica de ±0.01 a ±0.05 m/s².

**Dónde se rompe la promesa:** el informe describe "detección de ondas P", pero el código actual
no lo hace. `main.gd` solo calcula `accel.length() - 9.8` y lo compara contra un umbral fijo.
Ese cálculo detecta *cualquier* aceleración —caminar, correr, un golpe en la mesa—, no la firma
de una onda P. Distinguirla requiere análisis de frecuencia o forma de onda, y es el trabajo
técnico más interesante que queda pendiente.

## Estado

| | |
|---|---|
| Motor | Godot **4.6** (renderer `mobile`, Jolt Physics) |
| Plataforma objetivo | Android (necesita acelerómetro) |
| Scripts | 2 (`main.gd`, `configuracion.gd`) |
| Compilado | **No.** `export_presets.cfg` existe pero nunca se exportó; no hay APK |
| Probado en dispositivo | **No** |
| Tests | Ninguno |
| Validación experimental | **Tabla vacía.** Planteada en el informe, sin ejecutar |
| Licencia | Sin definir |

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

**Monitoreo continuo mientras la app está abierta:** el proyecto usa *keep screen on* y el
permiso `WAKE_LOCK` para que el procesador no entre en reposo profundo durante la vigilancia.

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

- **No hay APK.** El preset de exportación está, pero nunca se compiló ni se probó en un teléfono.
- **No se puede probar sin móvil.** No existe un modo de depuración que simule el acelerómetro.
- **La calibración es a ojo.** `umbral = 3.0` y `duracion_minima = 0.10` los elegí sin medir
  nada: ni una sola sacudida registrada, ni datos de sismos para contrastar.
- **La etiqueta "Magnitud" engaña.** No es la magnitud de Richter: es la desviación de la
  aceleración respecto a `9.8 m/s²`, en `m/s²`. Un sismo de 4.0 y uno de 7.0 pueden mover tu
  teléfono exactamente igual.
- **No distingue falsos positivos.** Caminar o golpear la mesa dispara la alarma igual que un
  sismo, porque no hay análisis de frecuencia.
- **Sin monitoreo en segundo plano.** Con la pantalla apagada o la app cerrada, Android corta
  la vigilancia: falta un Foreground Service nativo.
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

## Validación pendiente

El informe deja diseñado el experimento, pero la tabla de resultados está vacía. Para llenarla
de verdad hacen falta, como mínimo, 10–15 repeticiones por nivel de intensidad:

1. **Mesa vibratoria casera** a distintas intensidades, midiendo cada repetición.
2. **Instrumento de referencia** en paralelo (sensor calibrado u otra app certificada).
3. **Pruebas de falsos positivos**: caminar, correr, dejar caer el celular, golpes accidentales.
4. **Tabla del informe**: `N° prueba | intensidad aplicada | lectura app | lectura referencia | error (%)`.
5. **Ajuste del umbral** con esos datos, y dejar registrado con qué criterio se eligió.

Sin ese paso, cualquier afirmación sobre "segundos de anticipación" es una hipótesis, no un
resultado.

## Documentación del proyecto escolar

El proyecto tiene un informe completo en formato FENCYT (Categoría E) que no vive en este
repositorio, porque incluye datos personales de quienes figuran en la inscripción del concurso.
Contiene:

- Contexto: Perú en el Cinturón de Fuego, límites de los sismógrafos, cobertura rural.
- Marco científico: ondas P y S, acelerómetro MEMS, márgenes de error.
- Descripción de la solución, requerimientos y materiales.
- Diseño de la validación (mesa vibratoria, pruebas repetitivas, falsos positivos).
- Implementación pantalla por pantalla.
- **Limitaciones reconocidas** y trabajo futuro (Foreground Service, confirmación colaborativa
  entre varios celulares al estilo MyShake).

**Lo que falta en el informe:** resumen de 250 palabras, diagrama de flujo, cronograma, costos,
capturas de pantalla del editor y del celular, tabla de validación con datos, bibliografía en
APA 7 y anexos.

## Lista para retomar

1. Modo debug: un `HSlider` que inyecte una magnitud falsa, para probar la alarma entera en PC.
2. Exportar el APK y probarlo en un teléfono real durante una semana.
3. Registrar las sacudidas en CSV y recalibrar el umbral con esos datos.
4. **Separar sismo de movimiento humano:** análisis de frecuencia (FFT) o detectar el patrón
   de las ondas P. Es lo que convertiría esto en el proyecto que el informe describe.
5. Cambiar la etiqueta "Magnitud" por algo que no se confunda con la escala de Richter
   (ej. "Sacudida: 3.2 m/s²").
6. Notificación local + canal de Android, y Foreground Service para que no muera en segundo plano.
7. Envío automático del SMS (o al menos `SmsManager` en vez de `OS.shell_open`).
8. Tests de la máquina de estados, sin necesidad de Godot.
9. Renombrar assets y definir licencia del proyecto.

## Estructura

```
main.gd            lógica del acelerómetro, umbral y alerta
configuracion.gd   guarda el número de contacto (user://ajustes.cfg)
main.tscn          pantalla principal
configuracion.tscn panel de ajustes
aero.gdshader      shader del fondo (estética Frutiger Aero)
alert.wav          sirena
```

## Créditos

Código, interfaz, shader y documentación técnica: **Yeremi S. BΛSTIAN**.

El proyecto se presentó en **FENCYT 2026 (Categoría E)** como trabajo de la **I.E.P. La Salle
Quillabamba** (Quillabamba, Cusco, Perú). Esa categoría del concurso se inscribe por equipos y
con docente asesor, así que la ficha oficial lista al equipo de 4.º "B" y al asesor; el
desarrollo que está en este repositorio es mío.

[yeremisb.com](https://yeremisb.com) · Quillabamba, Perú
