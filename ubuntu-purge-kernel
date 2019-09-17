#!/bin/bash
dpkg --get-selections | grep linux-image | awk '/deinstall/ {print $1}' | xargs sudo apt purge -y
