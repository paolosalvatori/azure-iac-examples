#!/bin/bash

sudo systemctl stop goweb.service
sudo systemctl disable goweb.service
sudo rm /etc/systemd/system/goweb.service

cp ./main /home/localadmin/main

cat <<EOF > /etc/systemd/system/goweb.service
[Unit]
Description=Go sample web app
After=multi-user.target

[Service]
User=root
Group=root
ExecStart=/home/localadmin/main

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start goweb.service
sudo systemctl enable goweb.service
