#!bin/bash

echo "Executing: sudo systemctl start containerd.service docker.socket docker.service"
sudo systemctl start containerd.service docker.socket docker.service

