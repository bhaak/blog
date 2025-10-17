+++
date = '2025-10-12T14:51:25+02:00'
title = 'Pimiga 4 on Raspberry Pi 5'
categories = ['Emulation']
tags = ['Amiga', 'Raspberry Pi']
+++

I got myself a Raspberry Pi 5 with the intent of using it for Amiga emulation.
There are several images floating around on the internet that bundle Amiga software.

The most comprehensive page I found is https://amigang.com/software-pii/ on AmigaNG.

I tried the Pimiga 4 image (PIMIGA_ARM.7z, md5sum
34ff61d2fd58e70b8109312b1a9202a9) but it turned out that [the bundled kernel is
too old for this board](https://forums.raspberrypi.com/viewtopic.php?t=380721).
Running this image results in the following kernel panics:

```text
Kernel panic - not syncing: Asynchronous SError Interrupt
CPU: 3 PID: 1 Comm: swapper/0 Not tainted 6.1.0-rpi8-rpi-2712 #1 Debian 1:6.1.73-1+rpt1
Hardware name: Raspberry Pi 5 Model B Rev 1.1 (DT)
```

I copied the files from a [bookworm Raspberry Pi
OS](https://www.raspberrypi.com/software/operating-systems/) to the boot
partition of the Pimiga image, only preserving the cmdline.txt for booting the
correct partition.

Now the image boots but quickly runs into a blank screen. Accessing the machine
by ssh shows an error message in /var/log/Xorg.0.log.
```text
[    70.506] (EE) open /dev/fb0: No such file or directory
[    70.506] (EE) No devices detected.
Fatal server error:
[    70.506] (EE) no screens found(EE)
```

Updating the OS will fix this issue.
But there are performance issues (e.g. stuttering sound in fullscreen mode)
with current drivers on bookworm for the Raspberry Pi.
On the Facebook page for Pimiga, I found this snippet that will prevent
updating the drivers.
The whole sequence for updating the image is:
```shell
sudo apt-mark hold libegl-mesa0 libgl1-mesa-dri libglapi-mesa libglu1-mesa libglx-mesa0 mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers libgbm1
sudo apt update
sudo apt upgrade
```

Afterwards it finally boots into Pimiga. You still might to reduce the resolution of your display. The Raspberry Pi is not powerful enough to power a 4k display. FullHD (1920x1080) at 60hz is a resolution known to work well. 
