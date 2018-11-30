# This docker builds a container for the SPI/USB RAK833 (and equivalent) LoRaWaN gateway using a USB-SPI adaptor
# The first image is used to build the full solution
FROM debian as builder
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y git build-essential
RUN apt-get install -y swig libftdi-dev curl

# libmpsse install
WORKDIR /build
RUN git clone https://github.com/devttys0/libmpsse.git
WORKDIR /build/libmpsse/src
RUN ./configure --disable-python
RUN make
RUN make install
RUN ldconfig

# Lora Gateway for RAK833 based modules
WORKDIR /build
RUN git clone https://github.com/ellerbach/lora_gateway
RUN cp ./lora_gateway/libloragw/99-libftdi.rules /build/99-libftdi.rules
WORKDIR /build/lora_gateway
RUN make

# Lora packet forwarder
WORKDIR /build
RUN git clone https://github.com/ellerbach/packet_forwarder.git
WORKDIR /build/packet_forwarder
RUN make

# Download in the first image the needed FTDI dependencies package
WORKDIR /build
RUN curl -L http://ftp.us.debian.org/debian/pool/main/libf/libftdi/libftdi1_0.20-2_amd64.deb -o libftdi1_0.20-2_amd64.deb
RUN curl -L http://ftp.us.debian.org/debian/pool/main/libu/libusb/libusb-0.1-4_0.1.12-30_amd64.deb -o libusb-0.1-4_0.1.12-30_amd64.deb

# The second image is used to deploy the built solution
FROM debian as exec
WORKDIR /LoRa
# Install the various USB libraries
COPY --from=builder /build/libmpsse/src/libmpsse.so libmpsse.so
COPY --from=builder /build/libmpsse/src/libmpsse.a libmpsse.a
COPY --from=builder /build/libftdi1_0.20-2_amd64.deb .
COPY --from=builder /build/libusb-0.1-4_0.1.12-30_amd64.deb . 
COPY --from=builder /build/99-libftdi.rules /etc/udev/rules.d/99-libftdi.rules
RUN install -D -m644 libmpsse.so //usr/local/lib/libmpsse.so
RUN install -D -m644 libmpsse.a //usr/local/lib/libmpsse.a
RUN dpkg -i ./libusb-0.1-4_0.1.12-30_amd64.deb
RUN dpkg -i ./libftdi1_0.20-2_amd64.deb
RUN ldconfig

# Copy the packet forwarder containing the fully build application
COPY --from=builder /build/packet_forwarder/lora_pkt_fwd/lora_pkt_fwd .
# Copy the various config file supporting US and EU fequencies and configurations
COPY --from=builder /build/packet_forwarder/lora_pkt_fwd/global_conf.json .
COPY local_conf.json .
COPY global_conf.us.json .
COPY global_conf.json global_conf.eu.json 
# Copy the 
COPY start_pktfwd.sh .
RUN chmod +x start_pktfwd.sh
ENTRYPOINT ["./start_pktfwd.sh"]