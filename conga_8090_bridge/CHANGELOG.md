## 1.2.0
- Horarios programados por habitación (`setOrder6090`) vía `/config/conga_plans.json`.
- Control del "no molestar" en HA (interruptor + franja horaria inicio/fin).
- Nuevos controles descubiertos por ingeniería inversa: botón de vaciar base,
  interruptores de turbo en alfombras, voz y actualizaciones automáticas (OTA),
  slider de volumen, selectores de tipo de base y modo de limpieza, y sensores
  de consumibles (cepillos, filtro, mopa).
- El interruptor de doble pasada (x2) ahora aplica el ajuste real en el robot.
- Nueva opción `MAP_HEAD_ID` (opcional; el puente lo detecta solo).
- Arreglo de codificación en Windows/consola que podía cortar la conexión del
  robot, y migración a la API de callbacks v2 de paho-mqtt.

## 1.1.1
- Actualizar documentación.

## 1.1.0
- JWT sintético (ya no hace falta capturar el token), selectores de potencia/agua/mopa, switch de doble pasada, botones de limpieza por habitación y sensores de área/tiempo.

## 1.0.10
- Reparación de errores.

## 1.0.9
- Reparación de errores.

## 1.0.8
- Reparación de errores.

## 1.0.7
- Añadido icono personalizado en formato 3D para la interfaz de Home Assistant.
- Optimizada la compilación de la imagen base y dependencias de red.

## 1.0.6
- Primera versión funcional empaquetada como Add-on local estable.
- Implementación de MQTT Autodiscovery para entidades nativas de aspiradora.
- Soporte para selectores de potencia de succión, agua y vibración de mopa.
- Configuración de botones individuales para la limpieza interactiva por estancias.