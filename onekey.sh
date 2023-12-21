#!/bin/bash

# Clone vgpu-proxmox
git clone https://github.com/fanglaogong/vgpu-proxmox.git

# Change to /opt directory
cd /opt

# Clone vgpu_unlock-rs
git clone https://github.com/fanglaogong/vgpu_unlock-rs.git

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
source $HOME/.cargo/env

# Change to vgpu_unlock-rs directory
cd vgpu_unlock-rs/

# Build vgpu_unlock-rs
cargo build --release

# Create directories and files
mkdir /etc/vgpu_unlock
touch /etc/vgpu_unlock/profile_override.toml

mkdir -p /etc/systemd/system/nvidia-vgpud.service.d
mkdir -p /etc/systemd/system/nvidia-vgpu-mgr.service.d

# Configure nvidia-vgpud.service
echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpud.service.d/vgpu_unlock.conf

# Configure nvidia-vgpu-mgr.service
echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpu-mgr.service.d/vgpu_unlock.conf

# Add code if the GPU natively supports VGPU
echo "unlock = false" > /etc/vgpu_unlock/config.toml

# Move GPU driver to PVE /home directory
mv /root/onekey--vgpu-8.1/NVIDIA-Linux-x86_64-535.129.03-vgpu-kvm.run /home

# Change to /home directory
cd /home

# Add execute permission to the driver
chmod +x NVIDIA-Linux-x86_64-535.129.03-vgpu-kvm.run

# Apply the patch
./NVIDIA-Linux-x86_64-535.129.03-vgpu-kvm.run --apply-patch ~/vgpu-proxmox/535.129.03.patch

# Install the driver with DKMS support
./NVIDIA-Linux-x86_64-535.129.03-vgpu-kvm-custom.run --dkms

# Clean up downloaded files
cd /home
rm -r NVIDIA-Linux-x86_64-535.129.03-vgpu-kvm.run
rm -r NVIDIA-Linux-x86_64-535.129.03-vgpu-kvm-custom.run
cd /root
rm -r onekey--vgpu-8.1
rm -r vgpu-proxmox
# Reboot the system
reboot
