FROM alpine:latest

# Forzar a Python a mostrar los logs en tiempo real sin búfer
ENV PYTHONUNBUFFERED=1

# Instalar Python, dependencias de red y librerías criptográficas de soporte para SSL
RUN apk add --no-cache python3 py3-pip openssl jq python3-dev build-base libffi-dev

# Instalar la librería MQTT
RUN pip3 install paho-mqtt --break-system-packages

# Copiar archivos al contenedor
COPY conga_mqtt_bridge.py /conga_mqtt_bridge.py
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]