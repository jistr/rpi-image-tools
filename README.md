rpi-image-tools
===============

Turns a Fedora ARMv7 minimal image into an image bootable on Raspberry
Pi 2.

Usage
-----

* Clone and `cd`.

```bash
git clone https://github.com/jistr/rpi-image-tools
cd rpi-image-tools
```

* Download the sources (Fedora ARMv7 minimal image, RPi
  firmware). They'll be downloaded into `rpi-image-sources` directory.

```bash
./download-sources.sh
```

* Build the image. You'll be prompted for image and partition sizes,
  and a root password (the root password for the image, not your
  workstation's root password).

```bash
./build-image.sh
```

* That's it! The generated image is in the `rpi-image-output`
  directory. You can `dd` it onto an SD card.

  It's quite possible you'll want to make further customizations to
  the image. For that you can use e.g. tools like `virt-customize` or
  `virt-edit` or a loop device mount. (You can also write the image to
  an SD card first and then mount and customize the SD card directly.)

Q & A
-----

* *What does ./build-image.sh do with the downloaded source image?*

  ./build-image.sh does e.g.:

  * Resizes the image to your liking.

  * Optionally removes the swap partition.

  * Changes the boot partition from ext3 to vfat (as required by the
    Pi) and amends `/etc/fstab` accordingly.

  * Installs the Raspberry Pi firmware.

  * Configures a very basic `/boot/cmdline.txt` and
    `/boot/config.txt`.

  * Enables getty on the serial console breakout pins.

  * Sets a root password and disables initial-setup app.

  For a complete list of changes, read the source (it's not too long).

* *Why disable the initial-setup app?*

  The aim is to have an image in a ready working state, so that it can
  be used even without a display attached to the Raspberry Pi.

* *What Fedora image and firmware versions are downloaded?*

  The defaults are visible on the top of the `lib/variables.sh`
  file. You can export custom values for the `RPI_OS_IMAGE_URL` and
  `RPI_FIRMWARE_URL` variables prior to running the download and build
  scripts. However, please make sure not to break the tool's
  expectations on what it downloads. This means, mainly:

  * The `RPI_OS_IMAGE_URL` points to a Fedora ARMv7 minimal .raw.xz
    image with 3 partitions - sda1 is boot, sda2 is swap, sda3 is
    root.

  * The `RPI_FIRMWARE_URL` points to a .tar.gz archive of a specific
    commit in the GitHub Raspberry Pi firmware repository. The tool
    relies on the internal structure of such an archive.

* *Can parameters be passed into ./build-image.sh instead of asking
  for user input?*

  Yes, use `RPI_BOOT_SIZE`, `RPI_SWAP_SIZE`, `RPI_ROOT_SIZE`,
  `RPI_IMAGE_SIZE`, and `RPI_ROOT_PASSWORD` environment variables.

* *Do the scripts have to be run as root?*

  No, the scripts don't have to (and should not) be run as root.

* *Can i use the image on Raspberry Pi 1?*

  No, the Fedora ARM images are for ARMv7+ processors, so Raspberry Pi
  older than 2 will not work with these.
