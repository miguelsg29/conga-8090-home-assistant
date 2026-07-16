#!/bin/sh
# Ruta donde Home Assistant guarda los datos del formulario visual
CONFIG_PATH="/data/options.json"
# Leer configuraciones de forma nativa usando jq (y asignar defaults si vienen vacíos)
export MQTT_HOST=$(jq -r '.MQTT_HOST // ""' $CONFIG_PATH)
export MQTT_PORT=$(jq -r '.MQTT_PORT // 1883' $CONFIG_PATH)
export MQTT_USER=$(jq -r '.MQTT_USER // ""' $CONFIG_PATH)
export MQTT_PASS=$(jq -r '.MQTT_PASS // ""' $CONFIG_PATH)
export ROBOT_DID=$(jq -r '.ROBOT_DID // 0' $CONFIG_PATH)
export ROBOT_USERID=$(jq -r '.ROBOT_USERID // 0' $CONFIG_PATH)
export ROBOT_SN=$(jq -r '.ROBOT_SN // ""' $CONFIG_PATH)
export ROBOT_MAC=$(jq -r '.ROBOT_MAC // ""' $CONFIG_PATH)
export FACTORY_ID=$(jq -r '.FACTORY_ID // "1003"' $CONFIG_PATH)
export PROJECT_TYPE=$(jq -r '.PROJECT_TYPE // "CECOTECCRL350-1001"' $CONFIG_PATH)
export LISTEN_PORT=$(jq -r '.LISTEN_PORT // 9090' $CONFIG_PATH)
# map_head_id opcional (el puente lo detecta solo; sirve de respaldo)
export MAP_HEAD_ID=$(jq -r '.MAP_HEAD_ID // ""' $CONFIG_PATH)

# JWT: opcional. Si se deja vacio (o USE_SYNTHETIC_JWT=true), el puente genera
# un JWT sintetico sin caducidad (el robot no valida la firma).
export AUTH_JWT=$(jq -r '.AUTH_JWT // ""' $CONFIG_PATH)
# USE_SYNTHETIC_JWT es un booleano de HA; el puente acepta "true"/"on".
if [ "$(jq -r '.USE_SYNTHETIC_JWT // true' $CONFIG_PATH)" = "true" ]; then
    export USE_SYNTHETIC_JWT="on"
else
    export USE_SYNTHETIC_JWT="off"
fi

# Ajustes de limpieza por defecto
export DEFAULT_FAN=$(jq -r '.DEFAULT_FAN // "Normal"' $CONFIG_PATH)
export DEFAULT_WATER=$(jq -r '.DEFAULT_WATER // "Medio"' $CONFIG_PATH)
export DEFAULT_MOP=$(jq -r '.DEFAULT_MOP // "Estándar"' $CONFIG_PATH)
export DEFAULT_TWICE=$(jq -r '.DEFAULT_TWICE // "off"' $CONFIG_PATH)

# Generar certificados TLS si no existen en la carpeta compartida /ssl
if [ -f "/ssl/conga_cert.pem" ] && [ -f "/ssl/conga_key.pem" ]; then
    cp /ssl/conga_cert.pem /cert.pem
    cp /ssl/conga_key.pem /key.pem
else
    echo "[INFO] Certificados no encontrados en /ssl/. Generando certificados TLS locales automáticos..."
    openssl req -x509 -newkey rsa:2048 -keyout /key.pem -out /cert.pem -days 3650 -nodes -subj "/CN=tcp-cecotec.3irobotix.net"
fi
# Horarios por habitacion (opcional): si el usuario deja un fichero de horarios en
# /config/conga_plans.json, se usa como plans.json del puente. Formato en el repo
# principal (plans.example.json). Sin el, el resto de controles funcionan igual.
if [ -f "/config/conga_plans.json" ]; then
    cp /config/conga_plans.json /plans.json
    echo "[INFO] Horarios cargados de /config/conga_plans.json"
fi

echo "[INFO] Lanzando el servidor puente Conga 8090..."
python3 /conga_mqtt_bridge.py