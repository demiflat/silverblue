ARG IMAGE_URL=ghcr.io/ublue-os/bluefin:stable
ARG IMAGE_REGISTRY=ghcr.io/ublue-os
ARG AKMODS_URL=ghcr.io/ublue-os/akmods-nvidia-lts:main-44

FROM ${IMAGE_URL}
ARG RECIPE=recipe.yml

# copy over configuration files
# etc is copied to /usr/etc/ to prevent "merge conflicts"
# as it is the proper directory for "system" configuration files
# and /etc/ is for editing by the local admin
# see issue #28 (https://github.com/ublue-os/startingpoint/issues/28)
COPY etc /usr/etc
COPY usr /usr

# copy scripts
RUN mkdir /tmp/scripts
COPY scripts /tmp/scripts
RUN find /tmp/scripts -type f -exec chmod +x {} \;

COPY ${RECIPE} /usr/etc/ublue-recipe.yml

# yq used in build.sh and the setup-flatpaks recipe to read the recipe.yml
# copied from the official container image as it's not avaible as an rpm
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

# copy and run the build script
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh

COPY --from=ghcr.io/ublue-os/akmods-nvidia-lts:main-44 / /tmp/akmods-nvidia
RUN find /tmp/akmods-nvidia
## optionally install remove old and install new kernel
RUN dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
## install ublue support package and desired kmod(s)
RUN dnf5 install -y --allowerasing /tmp/akmods-nvidia/rpms/ublue-os/*.rpm 
RUN dnf5 install -y --allowerasing mesa-dri-drivers.i686 mesa-filesystem.i686 mesa-libEGL.i686 mesa-libGL.i686 mesa-libgbm.i686 mesa-vulkan-drivers.i686
RUN dnf5 config-manager setopt fedora-nvidia.enabled=1 nvidia-container-toolkit.enabled=1
RUN dnf5 config-manager setopt fedora-multimedia.enabled=0
RUN dnf5 install -y --allowerasing libnvidia-fbc libnvidia-ml.i686 libva-nvidia-driver nvidia-driver nvidia-driver-cuda nvidia-driver-cuda-libs.i686 nvidia-driver-libs.i686 nvidia-settings nvidia-container-toolkit /tmp/akmods-nvidia/rpms/kmods/*.rpm /tmp/akmods-nvidia/rpms/nvidia/*.rpm /tmp/akmods-nvidia/kernel-rpms/*.rpm
#gnome-shell-extension-supergfxctl-gex supergfxctl

RUN mkdir -p /nix

RUN mkdir -p /development

# clean up and finalize container build
RUN rm -rf \
        /tmp/* \
        /var/* && \
    ostree container commit
