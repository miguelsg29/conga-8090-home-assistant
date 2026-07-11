#!/usr/bin/env bashio

# Leer configuraciones mediante las herramientas nativas bashio de Home Assistant
export MQTT_HOST=$(bashio::config 'MQTT_HOST')
export MQTT_PORT=$(bashio::config 'MQTT_PORT')
export MQTT_USER=$(bashio::config 'MQTT_USER')
export MQTT_PASS=$(bashio::config 'MQTT_PASS')
export ROBOT_DID=$(bashio::config 'ROBOT_DID')
export ROBOT_USERID=$(bashio::config 'ROBOT_USERID')
export ROBOT_SN=$(bashio::config 'ROBOT_SN')
export ROBOT_MAC=$(bashio::config 'ROBOT_MAC')
export FACTORY_ID=$(bashio::config 'FACTORY_ID')
export PROJECT_TYPE=$(bashio::config 'PROJECT_TYPE')
export LISTEN_PORT=$(bashio::config 'LISTEN_PORT')
export DEFAULT_FAN=$(bashio::config 'DEFAULT_FAN')
export DEFAULT_WATER=$(bashio::config 'DEFAULT_WATER')
export DEFAULT_MOP=$(bashio::config 'DEFAULT_MOP')
export DEFAULT_TWICE=$(bashio::config 'DEFAULT_TWICE')

# El script de python espera encontrar 'cert.pem' y 'key.pem' en su directorio de ejecucion.
# Si el usuario tiene certificados propios en la carpeta /ssl de HA, los usamos. 
# Si no, generamos unos autofirmados en el acto para evitar configuraciones complejas.
if [ -f "/ssl/conga_cert.pem" ] && [ -f "/ssl/conga_key.pem" ]; then
    cp /ssl/conga_cert.pem /cert.pem
    cp /ssl/conga_key.pem /key.pem
else
    bashio::log.info "Certificados no encontrados en /ssl/. Generando certificados TLS locales automáticos..."
    openssl req -x509 -newkey rsa:2048 -keyout /key.pem -out /cert.pem -days 3650 -nodes -subj "/CN=tcp-cecotec.3irobotix.net"
fi

bashio::log.info "Lanzando el servidor puente Conga 8090..."
python3 /conga_mqtt_bridge.py