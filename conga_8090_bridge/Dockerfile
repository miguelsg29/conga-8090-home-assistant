ARG BUILD_FROM
FROM $BUILD_FROM

# Instalar Python y dependencias de red
RUN apk add --no-cache python3 py3-pip openssl jq

# Instalar la librería MQTT rompiendo la restricción de paquetes del sistema del contenedor externo
RUN pip3 install paho-mqtt --break-system-packages

# Copiar archivos al contenedor
COPY conga_mqtt_bridge.py /conga_mqtt_bridge.py
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]