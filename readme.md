# LoRa Gateway support for USB-FTDI mPCIe RAK833 board

Semtech officially dropped since v3.2.0 the FDTI support. Only old versions were available not offering support for recent updates, bug fixes and LoRa Packet Forwarder. USB FTDI support is still a great option, very cheap when few devices are connected.

This repository add *again* support for FDTI. It has been especially designed for Raspberry Pi but it is as well functional on Mac. Tests on Mac has been very minimal, so there may still be not fully functional or having few left bugs.

We will describe the hardware as well as the software needed to have a full working solution. Please note that a Docker file is provided as well so the solution can be fully integrated in a light container. This is as well fully detailed.

This repository will be maintained to support new versions of both the LoRa Gateway and the LoRa Packet Forwarder.

## Key Changes vs Original Semtech Repos

In order to support in recent versions of [LoRa Gateway](https://github.com/Lora-net/lora_gateway) and [LoRa Network Packet Forwarder](https://github.com/lora-net/packet_forwarder) modifications had to be done in the core Lora Gateway library from Semtech:

* Adding the support for FTDI communications in the file [loragw_spi.ftdi.c](libloragw\src\loragw_spi.ftdi.c). This file is a modified version for the old legacy version of this project. Part of the modifications, the function definitions changed over time to support multiplexing. So the file reflect those changes.
* Adding a definition for the rak833 specific build thru the file [rak833_rpi.h](libloragw\inc\rak833_rpi.h). this file has been gathered from the legacy code.
* Changing the file [library.cfg](libloragw\library.cfg) to support FTDI. This modification is inspired by the legacy code.
* All *Makefile* files has been changed to support the additional FTDI support and Mac

Most important chnages is in the *linking options* and can be summarize as (the linking depends on the file, they are a bit different):

```makefile
### linking options

ifeq ($(CFG_SPI),native)
  LIBS := -lloragw -lrt -lm
else ifeq ($(CFG_SPI),ftdi)
  LIBS := -lloragw -lrt -lmpsse -lm
else ifeq ($(CFG_SPI),mac)
  LIBS := -lloragw -lmpsse -lm
else
  LIBS := -lloragw -lrt -lm
endif
```

As all test tools are supported, you can then run the tests and follow the [original documentation from Semtech](original_readme.md).

### Specific Mac Support

If you want to use the Mac support, you'll need to change the file [library.cfg](libloragw\library.cfg) and replace *ftdi* by *mac*. This has followed limited tests and may result in unstable configurations.

## Hardware Requirements

The needed hardware is a RAK833 with SPI + USB support. The USB is actually a FTDI FT2232H and appear with Vendor ID 0x0403 and Product ID 0x6010.
You can find this specific mPCIe board [here for example](https://www.aliexpress.com/item/RAK833-SPI-USB-Industrial-Grade-Mini-PCIe-LoRa-Gateway-Concentrator-Module-SX1301-FT2232H-Chip-868-915MHz/32867370031.html). It cost approximately 110€ including the antena.

![Picture RAK833](/images/rak833.jpg)

**Note**: it is critical to plug the antena before using the board. It may distroy the board if you're not doing it. At best, it will only damage it.

It does then require a specific USB-mPCIe adaptor which is basically a passthrough connecting the USB pins from the mPCIe board to the regular USB. This part is actually quite complicated to find. You can find [here for example](https://www.aliexpress.com/item/Mini-PCI-Express-pcie-pci-express-PCI-E-Wireless-WWAN-to-USB-Adapter-Card-with-SIM/32657444139.html). Be aware that hard drive ones and other implementing a USB component on the board won't work. Only those ones are actually working. Cost is about 8€.

![Picture USB-mPCIe](/images/usb-ftdi.jpg)

The solution is designed to work on a Raspberry Pi 3 (works as well on v2 and 3+). so you'll need a Raspberry Pi. This one is easy to find.

The all solution looks like this:

![solution](/images/raspberry.jpg)

## Debian arm32v7 Docker Image

The [docker file](/docker/Dockerfile) contains all what is needed to build a container with all the individual needed components. In short, you'll need the [libmpsse](https://github.com/devttys0/libmpsse.git) library and few dependencies. You'll need as well, this repository and the [LoRa Packet Forwarder](https://github.com/ellerbach/packet_forwarder).

The Dockerfile contains 2 large sections. The first one use a standard arm32v7 Debian image and build the full solution. The second one is the same image used to run the solution. It is a good practice to use one container to build the solution and using a light one, with only the necessary elements to run it.

This principle allow when possible (not in our case because of the hardware dependencies) a cross platform build in the first container and just what is needed in the second one. This reduce the size of the final containers and reduces as well the security risk by having the minimum number of software in it.

I do recommend to use the Moby version of Docker. This will do the trick:

```bash
# Download and install the moby-engine
curl -L https://aka.ms/moby-engine-armhf-latest -o moby_engine.deb && sudo dpkg -i ./moby_engine.deb
# Download and install the moby-cli
curl -L https://aka.ms/moby-cli-armhf-latest -o moby_cli.deb && sudo dpkg -i ./moby_cli.deb
# Run apt-get fix
sudo apt-get install -f
# Add the pi user to the group which can run Docker without priviledges. Need to logoff and log on
sudo usermod -aG docker pi
```

In order to understand all what is needed in the container, please refer to the next section.

**Note**: this container can be fully build on Windows with Docker setup to run Linux containers. This will be much eaiser and much faster than building it on a Raspberry Pi.

## Software Manual Installation

This section describes all the needed elements and how to manually install them. This is what you'll need if you want to have all elements running directly in your Raspberry Pi. If you prefer the docker container solution, please refer to the previous section.

### OS

Use any Raspbian (Debian based) Raspberry distribution, should work with any version higher than 7. 9+ and higher has been fully tested. Flash an SD card and you're good to go. Nothing special needs to be activated for the hardware except SSH to get the remote administration. As always, change the default password. The native SPI neither the native UART won't be used for this solution.

Please make sure you're up to date and install the few following dependencies:

```bash
sudo apt-get update && apt-get upgrade -y
sudo apt-get install -y git build-essential swig libftdi-dev curl
```

### FTDI to SPI bridge

The component to use is the [libmpsse](https://github.com/devttys0/libmpsse.git). This library should be compiled and installed.

```bash
cd ~
git clone https://github.com/devttys0/libmpsse.git
cd libmpsse/src
./configure --disable-python
make
sudo make install
sudo ldconfig
```

### LoRa Gateway

This is the main component and it needs to be cloned from this repository. All is already setup and no further changes needs to be done.

```bash
cd ~
git clone https://github.com/ellerbach/lora_gateway
sudo cp ./lora_gateway/libloragw/99-libftdi.rules /etc/udev/rules.d/99-libftdi.rules
cd ./lora_gateway
make
```

### LoRa Packet Forwarder

This component will allow you to forward the LoRa messages to any server you want. You can for example use the [LoRa Azure Starter Kit](https://github.com/Azure/iotedge-lorawan-starterkit/) if you want to connect your LoRa devices to Azure.

You'll have to use the specifc fork that is present on my other repository as it does contains the necessary modifications to support the FTDI board.

```bash
cd ~
git clone https://github.com/ellerbach/packet_forwarder.git
cd ./packet_forwarder
make
```

### Run the Solution

To run the solution, just run the *./lora_pkt_fwd* in the *packet_forwarder* directory. You should not have privileges issues as the 99-libftdi.rules file contains the necessary information to give you access to the FDTI. In case you have issues, try running it with privileges using the *sudo* command.

If all goes right, you should see few messages and after few seconds, the blue led of the RAK833 will turn on the mPCIe board.

![running](/images/raspberry-radiator.jpg)

*note*: The radiator is not an option. The RAK833 board is overheating quite a lot and will drop all packages when it will get too warm. Please make sure you find a way to cool it (a fan can be as well an option).