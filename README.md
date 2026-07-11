# Conga 8090 Ultra - Local MQTT Bridge (Home Assistant Add-on)

Este proyecto permite el **control local total** del robot aspirador **Cecotec Conga 8090 Ultra** desde Home Assistant sin depender de los servidores en la nube de Cecotec[cite: 10]. 

A diferencia de las generaciones anteriores (modelos 3090 al 6090) que utilizaban un protocolo binario compatible con proyectos como Congatudo, la serie 8000/Ultra utiliza una arquitectura moderna basada en **TLS 1.2 → WebSocket → Mensajes JSON** y mapas en **Protobuf (zlib)**[cite: 10]. Este puente suplanta por completo al servidor oficial, terminando la conexión cifrada de forma segura en tu entorno local[cite: 7, 10].

---

## Características Soportadas ✅

*   **Control de Entidad Vacuum Nativa:** Iniciar, pausar, detener, localizar (pitido) y retorno automático a la base de carga[cite: 7, 9].
*   **Lógica Inteligente de Estados:** Mapeo en tiempo real del estado del robot (`cleaning`, `docked`, `returning`, `paused`, `idle`, `error`) cruzando los reportes de actividad con el estado de carga física[cite: 7].
*   **Sensores de Telemetría:** Nivel de batería corregido (escala 0-100%), área total limpiada ($m^2$) y tiempo de limpieza transcurrido (minutos)[cite: 7, 9].
*   **Limpieza Inmediata por Habitación:** Botones individuales independientes creados automáticamente para limpiar estancias específicas en base a los IDs reales de tu mapa[cite: 7, 9].
*   **Selectores de Configuración Dinámica:** Ajuste en caliente desde la interfaz de Home Assistant para la potencia de succión, caudal de agua, nivel de vibración de la mopa y conmutador para doble pasada ($x2$)[cite: 7, 9].
*   **MQTT Autodiscovery:** No requiere configuración manual de entidades en YAML; el puente publica la configuración del dispositivo y Home Assistant lo detecta al instante[cite: 7, 9].

---

## Estructura del Repositorio para el Add-on

Para instalar el puente de forma nativa en tu servidor de Home Assistant OS sin depender de equipos externos, el repositorio de GitHub debe mantener la siguiente estructura de archivos:

| Archivo | Descripción |
| :--- | :--- |
| `conga_8090_bridge/config.yaml` | Metadatos del Add-on y definición del formulario visual de configuración[cite: 9]. |
| `conga_8090_bridge/Dockerfile` | Instrucciones de construcción del contenedor ligero (Alpine + Python3)[cite: 7]. |
| `conga_8090_bridge/run.sh` | Script de inicialización y exportación automatizada de variables de entorno[cite: 7]. |
| `conga_8090_bridge/conga_mqtt_bridge.py` | El código principal del puente local interactivo[cite: 7]. |
| `decodificar_mapa.py` | Script auxiliar para extraer la rejilla binaria y exportar el mapa en formato PNG[cite: 3]. |
| `mitm_captura_total.py` | Proxy interceptor TLS/WebSocket orientado a la captura inicial de credenciales[cite: 8]. |

---

## Guía de Puesta en Marcha

### Paso 1: Extracción Exhaustiva de Credenciales Privadas

Dado que las comunicaciones van cifradas, necesitas interceptar los identificadores únicos de tu unidad física antes de aislarla de internet[cite: 10].

1.  **Generar Certificados Temporales:** En una máquina local con OpenSSL instalado, genera un par de claves autofirmadas temporales[cite: 5]:
    ```bash
    openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=tcp-cecotec.3irobotix.net"
    ```
2.  **Colocar las Claves:** Asegúrate de guardar los archivos `cert.pem` y `key.pem` generados en el mismo directorio donde se encuentra el script `mitm_captura_total.py`[cite: 5, 8].
3.  **Configurar Redirección DNS:** En tu servidor DNS local (AdGuard Home, Pi-hole o la sección de DNS estáticos de tu router), añade un **DNS Rewrite** para desviar el dominio `tcp-cecotec.3irobotix.net` hacia la IP local de la máquina donde ejecutarás la captura[cite: 2, 8].
4.  **Iniciar la Captura:** Lanza el script en tu terminal[cite: 8]:
    ```bash
    python mitm_captura_total.py
    ```
5.  **Reiniciar el Robot:** Apaga el interruptor de energía física de tu Conga, espera unos segundos y vuélvelo a encender[cite: 5, 9].
6.  **Anotar Identificadores:** El robot conectará a tu proxy y verás aparecer en consola las tramas descifradas precedidas por `>>>`[cite: 8]. Copia y guarda en un lugar seguro los siguientes parámetros que verás en el bloque `auth/login`[cite: 2, 8]:
    *   `did` (ID del dispositivo)[cite: 2]
    *   `userId` (ID de vinculación de la App)[cite: 2]
    *   `sn` (Número de serie)[cite: 2]
    *   `mac` (Dirección MAC física)[cite: 2]
    *   `AUTH` (Token de sesión JWT completo)[cite: 2]

> ⚠️ **NOTA DE SEGURIDAD:** Una vez obtenidos estos valores, detén el script de captura. Estos identificadores son estrictamente privados y actúan como las llaves de tu dispositivo; no los expongas en ningún repositorio público.

---

### Paso 2: Instalación del Add-on en Home Assistant

1.  Dirígete a tu panel de Home Assistant y navega hasta **Ajustes** → **Complementos** (Add-ons).
2.  Haz clic en el botón **Tienda de complementos** ubicado abajo a la derecha.
3.  Despliega el menú de los tres puntos verticales en la esquina superior derecha y selecciona **Repositorios**.
4.  Introduce la URL de este repositorio de GitHub y haz clic en **Añadir**. Cierra el cuadro de diálogo.
5.  Refresca la página del navegador. Verás aparecer la sección correspondiente a este proyecto junto al complemento **Cecotec Conga 8090 Local Bridge**. Haz clic en él e **Instalar**.

---

### Paso 3: Configuración y Lanzamiento Visual

Una vez completada la instalación interna, no inicies el servicio todavía:

1.  Accede a la pestaña superior de **Configuración** del Add-on desde la interfaz web de Home Assistant[cite: 9].
2.  Completa los campos del formulario interactivo generado automáticamente con tus credenciales locales[cite: 9]:
    *   **MQTT_HOST:** IP local de tu instancia de Home Assistant o broker Mosquitto independiente[cite: 7].
    *   **MQTT_USER / MQTT_PASS:** Credenciales de acceso de tu broker[cite: 7].
    *   **ROBOT_DID / USERID / SN / MAC / AUTH_JWT:** Pega los valores exactos que recopilaste durante el proceso de captura del Paso 1[cite: 7].
    *   **Configuraciones por Defecto:** Define los niveles de succión, agua y mopa preferidos con los que deseas que el robot inicie de forma automática al pulsar los botones de limpieza rápida por habitación[cite: 9].
3.  Haz clic en **Guardar**[cite: 9].
4.  Regresa a la pestaña **Información** y haz clic en **Iniciar**.

El script se encargará de levantar el servidor local de suplantación cifrada y mapeará instantáneamente la aspiradora como un dispositivo MQTT completo e interactivo dentro de tu red[cite: 7, 9].

---

## Contribuciones e Ingeniería Inversa del Mapa

Si deseas avanzar en el renderizado en tiempo real del mapa de tu vivienda dentro de Home Assistant, el script `decodificar_mapa.py` detalla el mecanismo matemático de descompresión de la carga útil binaria del servicio `syn_no_cache`[cite: 3]. Extrae el flujo *zlib* (firma `78 9c`), parsea los campos de nivel superior mapeados en *Protobuf* y reconstruye de manera exacta la rejilla espacial de $800 \times 800$ celdas para exportar el plano de habitaciones etiquetado en formato de imagen nativa[cite: 3].

---

## Agradecimientos 🤝

Este proyecto no habría sido posible sin la inspiración, el trabajo previo y el camino abierto por grandes iniciativas de la comunidad de código abierto y la domótica:

*   **[Valetudo](https://github.com/Hypfer/Valetudo):** El proyecto de referencia absoluto en la liberación de robots aspiradores de la nube. Su filosofía de privacidad, soberanía del hardware y control local ha sido el faro conceptual y la mayor fuente de inspiración para este desarrollo.
*   **[Congatudo / agnoc](https://github.com/congatudo/agnoc):** Por demostrar que era posible romper las cadenas de la nube en el ecosistema de Cecotec y por servir de base para comprender cómo abordaba la comunidad las primeras generaciones de estos dispositivos. Este proyecto nace con el objetivo de dar continuidad a su excelente trabajo, adaptándolo a la nueva pila tecnológica basada en WebSockets de la serie 8000.
