#!/bin/bash

BOARD=h3

../sunxi-tools/sunxi-fel -p uboot u-boot-sunxi-with-spl.bin \
                        write 0x45000000 openwrt-sunxi-cortexa7-friendlyarm_nanopi-neo-air-initramfs-kernel.bin \
                        write 0x49000000 boot.scr
