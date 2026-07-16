# Conga 8090 Ultra - Local MQTT Bridge (Home Assistant Add-on)

Este proyecto permite el **control local total** del robot aspirador **Cecotec Conga 8090 Ultra** desde Home Assistant sin depender de los servidores en la nube de Cecotec.

A diferencia de las generaciones anteriores (modelos 3090 al 6090) que utilizaban un protocolo binario compatible con proyectos como Congatudo, la serie 8000/Ultra utiliza una arquitectura moderna basada en **TLS 1.2 → WebSocket → Mensajes JSON** y mapas en **Protobuf (zlib)**. Este puente suplanta por completo al servidor oficial, terminando la conexión cifrada de forma segura en tu entorno local.

> ℹ️ **¿Buscas la documentación técnica completa?** Este repositorio es el **add-on listo para instalar**. Si quieres entender el protocolo por dentro, ver la especificación completa, las herramientas de captura, el decodificador de mapa o adaptar otro modelo, visita el repositorio hermano de documentación e ingeniería inversa:
> **[github.com/miguelsg29/conga_8090_mqtt_bridge](https://github.com/miguelsg29/conga_8090_mqtt_bridge)** — donde iremos añadiendo más información técnica, guías de depuración y el detalle del protocolo.

---

## Características Soportadas ✅

*   **Control de Entidad Vacuum Nativa:** Iniciar, pausar, detener, localizar (pitido) y retorno automático a la base de carga.
*   **Lógica Inteligente de Estados:** Mapeo en tiempo real del estado del robot (`cleaning`, `docked`, `returning`, `paused`, `idle`, `error`) cruzando los reportes de actividad con el estado de carga física.
*   **Sensores de Telemetría:** Nivel de batería corregido (escala 0-100%), área total limpiada ($m^2$) y tiempo de limpieza transcurrido (minutos).
*   **Limpieza Inmediata por Habitación:** Botones individuales independientes creados automáticamente para limpiar estancias específicas en base a los IDs reales de tu mapa.
*   **Selectores de Configuración Dinámica:** Ajuste en caliente desde la interfaz de Home Assistant para la potencia de succión, caudal de agua, nivel de vibración de la mopa y conmutador para doble pasada ($x2$).
*   **JWT Sintético (sin caducidad):** El puente genera automáticamente el token de autenticación, así que **no necesitas capturarlo ni renovarlo nunca**. El robot no valida la firma del token (verificado empíricamente).
*   **MQTT Autodiscovery:** No requiere configuración manual de entidades en YAML; el puente publica la configuración del dispositivo y Home Assistant lo detecta al instante.
*   **Horarios por habitación:** planifica limpiezas por día y hora con el modo (potencia/agua/mopa/x2) **propio de cada estancia**, definidos en un fichero `conga_plans.json` (ver sección de horarios).
*   **Modo "No molestar":** interruptor y franja horaria de silencio configurables desde Home Assistant.
*   **Controles avanzados descubiertos por ingeniería inversa:** botón de **vaciar base**, e interruptores/selectores para **turbo en alfombras**, **voz + volumen**, **actualizaciones automáticas (OTA)**, **tipo de base** y **modo de limpieza** (Auto, Limpieza completa, Fregado, Bordes, Espiral, Espiral cuadrada, Punto).
*   **Sensores de consumibles:** vida de cepillo central, cepillo lateral, filtro y mopa.

---

## Estructura del Repositorio para el Add-on

Para instalar el puente de forma nativa en tu servidor de Home Assistant OS sin depender de equipos externos, el repositorio de GitHub debe mantener la siguiente estructura de archivos:

| Archivo | Descripción |
| :--- | :--- |
| `conga_8090_bridge/config.yaml` | Metadatos del Add-on y definición del formulario visual de configuración. |
| `conga_8090_bridge/Dockerfile` | Instrucciones de construcción del contenedor ligero (Alpine + Python3). |
| `conga_8090_bridge/run.sh` | Script de inicialización y exportación automatizada de variables de entorno. |
| `conga_8090_bridge/conga_mqtt_bridge.py` | El código principal del puente local interactivo. |
| `decodificar_mapa.py` | Script auxiliar para extraer la rejilla binaria y exportar el mapa en formato PNG. |
| `mitm_captura_total.py` | Proxy interceptor TLS/WebSocket orientado a la captura inicial de credenciales. |

---

## Guía de Puesta en Marcha

### Paso 1: Extracción de los Identificadores de tu Robot

Dado que las comunicaciones van cifradas, necesitas interceptar los identificadores únicos de tu unidad física antes de aislarla de internet.

1.  **Generar Certificados Temporales:** En una máquina local con OpenSSL instalado, genera un par de claves autofirmadas temporales:
    ```bash
    openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=tcp-cecotec.3irobotix.net"
    ```
2.  **Colocar las Claves:** Asegúrate de guardar los archivos `cert.pem` y `key.pem` generados en el mismo directorio donde se encuentra el script `mitm_captura_total.py`.
3.  **Configurar Redirección DNS:** En tu servidor DNS local (AdGuard Home, Pi-hole o la sección de DNS estáticos de tu router), añade un **DNS Rewrite** para desviar el dominio `tcp-cecotec.3irobotix.net` hacia la IP local de la máquina donde ejecutarás la captura.
4.  **Iniciar la Captura:** Lanza el script en tu terminal:
    ```bash
    python mitm_captura_total.py
    ```
5.  **Reiniciar el Robot:** Apaga el interruptor de energía física de tu Conga, espera unos segundos y vuélvelo a encender.
6.  **Anotar Identificadores:** El robot conectará a tu proxy y verás aparecer en consola las tramas descifradas precedidas por `>>>`. Copia y guarda en un lugar seguro los siguientes parámetros que verás en el bloque `auth/login`:
    *   `did` (ID del dispositivo)
    *   `userId` (ID de vinculación de la App)
    *   `sn` (Número de serie)
    *   `mac` (Dirección MAC física)

> 💡 **Nota sobre el token JWT (`AUTH`):** Ya **no es necesario** capturarlo. El add-on genera un token sintético sin caducidad de forma automática (el robot no valida la firma). Si por algún motivo tu unidad lo rechazara, siempre puedes capturar el campo `AUTH` del bloque `auth/login` y pegarlo en el campo opcional `AUTH_JWT` de la configuración.

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

1.  Accede a la pestaña superior de **Configuración** del Add-on desde la interfaz web de Home Assistant.
2.  Completa los campos del formulario interactivo generado automáticamente con tus credenciales locales:
    *   **MQTT_HOST:** IP local de tu instancia de Home Assistant o broker Mosquitto independiente.
    *   **MQTT_USER / MQTT_PASS:** Credenciales de acceso de tu broker.
    *   **ROBOT_DID / USERID / SN / MAC:** Pega los valores exactos que recopilaste durante el proceso de captura del Paso 1.
    *   **AUTH_JWT / USE_SYNTHETIC_JWT (opcional):** Déjalos como están. Por defecto, `USE_SYNTHETIC_JWT` está activo y el add-on genera el token automáticamente. Solo rellena `AUTH_JWT` si necesitas usar el token capturado de tu robot.
    *   **Configuraciones por Defecto:** Define los niveles de succión, agua y mopa preferidos con los que deseas que el robot limpie al pulsar los botones de limpieza por habitación, y si quieres doble pasada ($x2$).
3.  Haz clic en **Guardar**.
4.  Regresa a la pestaña **Información** y haz clic en **Iniciar**.

El script se encargará de levantar el servidor local de suplantación cifrada y mapeará instantáneamente la aspiradora como un dispositivo MQTT completo e interactivo dentro de tu red. En los registros verás la línea `[JWT] modo: SINTÉTICO (generado, sin caducidad)` confirmando que el token se genera solo.

---

### Paso 4: Redirección del DNS a Producción (¡El paso definitivo! 🚀)

Un error muy común es dejar el DNS apuntando al ordenador donde hiciste las pruebas iniciales. Para que el puente empiece a recibir los datos reales del robot, debes redirigir el tráfico hacia tu servidor de Home Assistant:

1. **Modificar AdGuard Home / Pi-hole:** Vuelve a la regla de **DNS Rewrite** que creaste en el *Paso 1*.
2. **Cambiar la IP:** Borra la IP de tu ordenador y escribe la **IP local exacta de tu Home Assistant**.
3. **Reinicio eléctrico obligatorio:** Apaga el interruptor físico de tu Conga 8090, espera 5 segundos y vuélvelo a encender. Esto vaciará la caché DNS interna del robot y le obligará a buscar su nueva "nube" local en la IP de Home Assistant.

En cuanto el robot arranque, verás en los registros (logs) del Add-on cómo aparece el mensaje `[robot] conectado ✓` y las entidades de tu panel MQTT cobrarán vida con el estado real de la batería y las habitaciones.

---

## Entidades que aparecerán en Home Assistant

Tras arrancar el add-on y con el robot conectado, se crea automáticamente un dispositivo **Conga 8090** con:

*   **Aspiradora** (`vacuum.conga_8090`): iniciar, pausar, reanudar, parar, volver a base y localizar.
*   **Sensores:** batería (%), área limpiada ($m^2$) y tiempo de limpieza (min).
*   **Botones "Limpiar &lt;habitación&gt;":** uno por cada estancia detectada en tu mapa.
*   **Selectores:** potencia de succión, nivel de agua, vibración de la mopa, **tipo de base** y **modo de limpieza**.
*   **Interruptores:** doble pasada ($x2$), **turbo en alfombras**, **voz**, **actualizaciones automáticas (OTA)** y **no molestar**.
*   **Volumen** de voz y **franja horaria** del no molestar (inicio/fin).
*   **Botón "Vaciar base"** (autovaciado manual) y, si defines horarios, un interruptor por cada plan más los botones "Sincronizar/Consultar horarios".
*   **Sensores de consumibles:** cepillo central, lateral, filtro y mopa.

Al pulsar un botón de habitación, el puente aplica primero la configuración de los selectores (potencia/agua/mopa/x2) y luego lanza la limpieza de esa estancia.

---

## Horarios programados por habitación (opcional)

El robot puede ejecutar limpiezas solo, a la hora y días que quieras, con el **modo propio de cada habitación**. Para activarlo:

1.  Crea un fichero llamado **`conga_plans.json`** en la carpeta **`/config`** de Home Assistant (con el add-on *File Editor* o *Samba*).
2.  Rellénalo siguiendo el formato de [`plans.example.json`](https://github.com/miguelsg29/conga_8090_mqtt_bridge/blob/main/plans.example.json) del repositorio de documentación. Ejemplo:
    ```json
    {"plans": [
      {"id": "noche", "name": "Noche", "enable": true, "time": "22:30",
       "days": ["lun","mar","mie","jue","vie"],
       "rooms": [
         {"room": 13, "fan": "Turbo",  "water": "Alto", "mop": "Potente", "twice": true},
         {"room": 15, "fan": "Normal", "water": "Bajo", "mop": "Estándar"}
       ]}
    ]}
    ```
3.  Reinicia el add-on. Aparecerá **un interruptor por plan** en Home Assistant, más los botones **"Sincronizar horarios"** (empuja los planes al robot) y **"Consultar horarios"**.

> Los `room` son los IDs de tu mapa (10–16), los mismos de los botones "Limpiar &lt;habitación&gt;". Si no creas el fichero, todo lo demás funciona igual; solo no aparecen los horarios.

---

## Solución de Problemas y Depuración

Si el robot no aparece o algo no funciona, revisa los **registros (logs)** del add-on. Señales útiles:

*   `[JWT] modo: SINTÉTICO...` → el token se genera correctamente.
*   `[robot] conectado ✓` → el robot ha encontrado el puente (DNS y puerto 9090 OK).
*   Si no aparece `[robot] conectado` en 1-2 minutos: revisa el **DNS Rewrite** (debe apuntar a la IP de HA) y que el **puerto 9090** esté accesible. Reinicia el robot con corte eléctrico real.
*   Si el robot conecta pero no salen las entidades: recarga la integración **MQTT** en Home Assistant.

Para depuración avanzada del protocolo, captura de comandos nuevos, o entender el
detalle de los mensajes, consulta el repositorio de documentación técnica:
**[github.com/miguelsg29/conga_8090_mqtt_bridge](https://github.com/miguelsg29/conga_8090_mqtt_bridge)**.

---

## Contribuciones e Ingeniería Inversa del Mapa

Si deseas avanzar en el renderizado en tiempo real del mapa de tu vivienda dentro de Home Assistant, el script `decodificar_mapa.py` detalla el mecanismo de descompresión de la carga útil binaria del servicio `syn_no_cache`. Extrae el flujo *zlib* (firma `78 9c`), parsea los campos de nivel superior mapeados en *Protobuf* y reconstruye la rejilla espacial de $800 \times 800$ celdas para exportar el plano de habitaciones etiquetado en formato de imagen nativa.

La especificación completa del protocolo (transporte, comandos, estados, mapa y
todos los hallazgos de la ingeniería inversa) está en el repositorio de
documentación: **[github.com/miguelsg29/conga_8090_mqtt_bridge](https://github.com/miguelsg29/conga_8090_mqtt_bridge)**.

---

## Agradecimientos 🤝

Este proyecto no habría sido posible sin la inspiración, el trabajo previo y el camino abierto por grandes iniciativas de la comunidad de código abierto y la domótica:

*   **[Valetudo](https://github.com/Hypfer/Valetudo):** El proyecto de referencia absoluto en la liberación de robots aspiradores de la nube. Su filosofía de privacidad, soberanía del hardware y control local ha sido el faro conceptual y la mayor fuente de inspiración para este desarrollo.
*   **[Congatudo / agnoc](https://github.com/congatudo/agnoc):** Por demostrar que era posible romper las cadenas de la nube en el ecosistema de Cecotec y por servir de base para comprender cómo abordaba la comunidad las primeras generaciones de estos dispositivos. Este proyecto nace con el objetivo de dar continuidad a su excelente trabajo, adaptándolo a la nueva pila tecnológica basada en WebSockets de la serie 8000.