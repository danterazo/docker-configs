FROM lscr.io/linuxserver/plex:latest

USER root

# install prerequisites
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		ca-certificates gnupg curl apt-transport-https

# add (or update) nvidia cuda repository for ubuntu 22.04
RUN mkdir -p /etc/apt/keyrings && \
	curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub | \
		gpg --dearmor -o /etc/apt/keyrings/nvidia-archive-keyring.gpg && \
	echo "deb [signed-by=/etc/apt/keyrings/nvidia-archive-keyring.gpg] \
		https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" \
		> /etc/apt/sources.list.d/nvidia-cuda-ubuntu2204.list

# install only the nvidia 575 user-space libraries (don't add kernel modules)
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		libnvidia-encode-575=575.64.03-0ubuntu0.22.04.1 \
		libnvidia-decode-575=575.64.03-0ubuntu0.22.04.1 \
		libnvidia-compute-575=575.64.03-0ubuntu0.22.04.1 && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# repair permissions (ensures containers start as non-root user, as per linuxserver.io standards)
USER 1000

# environment settings for nvidia runtime
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
