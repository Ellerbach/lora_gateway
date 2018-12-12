# Running a Docker container with RAK833-USB on a Mac

Main issue to run a Docker container on a Mac is to acess the USB ports. For this, you'll need to use VirtualBox, create a specific Docker machine, build the Docker container for the specific machine and then run with priviledges.

## Install VirtualBox and create the machine

Follow the steps:

- Install VirtualBox from https://www.virtualbox.org/wiki/Downloads
- During installation, make sure you give the permission to VirtualBox to access the system in the System preferences
- In a bash command line, type:

```bash
docker-machine create --driver virtualbox default
```

Sometimes the docker machine starts, check if it is running and stop it if it is running:

```bash
docker-machine ls
docker-machine stop default
```

- Then add the USB support to the machine:

```bash
vboxmanage modifyvm default --usb on
```

- Then list the USB port available

```bash 
vboxmanage list usbhost
```

You should see the FTDI port in the list:

![usblist](/images/usblist.png)

If you don't see the FTDI port in the list, reboot the Mac. Sometimes, the Mac doesn't mount correctly the FTDI.

- Add the FTDI in the USB list
    - Open the VirtualBox environment
    - Select the default VM which must be stopped
    - Go to settings
    - Then to the Ports, select USB:

![usb port](/images/usbmenu.png)

    - Then add the FTDI hardware like this:

![usb ftdi](/images/addusb.png)

Make sure you enter Vendor ID as 0x0403 so 0403 in the graphical interface and the Product ID as 0x6010 so as 6010 in the UI.

- Then go back to a terminal and start the docker machine:

```bash
docker-machine start default
```

- Then make sure this default environment will be launch when the docker command is called:

```bash
eval "$(docker-machine env default)"
```

- Then build the container amd64.Dockerfile

```bash
docker build -t lorapktfwd -f amd64.Dockerfile .
```

- Run the docker container in privileged mode

```bash
docker run --privileged lorapktfwd
```
