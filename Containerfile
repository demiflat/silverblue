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

COPY --from=${AKMODS_URL} / /tmp/akmods-nvidia
RUN find /tmp/akmods-nvidia
## optionally install remove old and install new kernel
# dnf -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
## install ublue support package and desired kmod(s)
RUN dnf install /tmp/rpms/ublue-os/ublue-os-nvidia*.rpm
RUN dnf install /tmp/rpms/kmods/kmod-nvidia*.rpm

RUN mkdir -p /nix

RUN mkdir -p /development

# clean up and finalize container build
RUN rm -rf \
        /tmp/* \
        /var/* && \
    ostree container commit
