#docker run --rm -v /lib/modules:/lib/modules --cap-add CAP_SYS_MODULE
ARG KERNEL_VERSION
FROM linuxkit/kernel:${KERNEL_VERSION} AS ksrc
# https://hub.docker.com/r/linuxkit/alpine/tags
FROM linuxkit/alpine:3fdc49366257e53276c6f363956a4353f95d9a81 AS builder
ARG KERNEL_VERSION
# Taken from https://github.com/linuxkit/linuxkit/blob/master/kernel/Dockerfile#L2
RUN apk update && apk add \
    argp-standalone \
    automake \
    bash \
    bc \
    binutils-dev \
    bison \
    build-base \
    curl \
    diffutils \
    flex \
    git \
    gmp-dev \
    gnupg \
    installkernel \
    kmod \
    elfutils-dev \
    linux-headers \
    mpc1-dev \
    mpfr-dev \
    ncurses-dev \
    openssl-dev \
    patch \
    sed \
    squashfs-tools \
    tar \
    xz \
    xz-dev \
    zlib-dev

# Kernel headers from previous build extract to /usr/src/linux-headers-<version>/
COPY --from=ksrc /kernel-dev.tar /
# Kernel source
COPY --from=ksrc /linux.tar.xz /
RUN tar xf kernel-dev.tar
RUN tar xf linux.tar.xz -C /usr/src/
WORKDIR /usr/src/linux/

# Copy current kernel build config and module symbol versions
RUN cp ../linux-headers-${KERNEL_VERSION}-linuxkit/.config ../linux-headers-${KERNEL_VERSION}-linuxkit/Module.symvers .
# Copy tne randstruct seed to match vermagic! https://github.com/torvalds/linux/commit/313dd1b629219db50cad532dba6a3b3b22ffe622
RUN cp ../linux-headers-${KERNEL_VERSION}-linuxkit/scripts/gcc-plugins/randomize_layout_seed.h scripts/gcc-plugins/randomize_layout_seed.h \
  && mkdir include/generated \
  && cp ../linux-headers-${KERNEL_VERSION}-linuxkit/include/generated/randomize_layout_hash.h include/generated/randomize_layout_hash.h

# Add module options
RUN echo "CONFIG_MAC80211_HWSIM=m" >> .config \
  && echo "CONFIG_CFG80211=m" >> .config \
  && echo "CONFIG_MAC80211=m" >> .config
# Silently add required defaults & prepare to compile mods
RUN make olddefconfig \
  && make modules_prepare
# Compile the modules
RUN make M=net/wireless/ \
  && make M=net/mac80211/ \
  && make M=drivers/net/wireless/
# Copy them to where we'll need them
RUN mkdir /kmod/ \
  && cp /usr/src/linux/drivers/net/wireless/mac80211_hwsim.ko \
  /usr/src/linux/net/wireless/cfg80211.ko \
  /usr/src/linux/net/mac80211/mac80211.ko /kmod/

#FROM scratch
FROM alpine:3.10
LABEL maintainer="@singe at SensePost <research@sensepost.com>"
LABEL repository="https://github.com/singe/linuxkit-mac80211_hwsim"
ENTRYPOINT []
CMD []
WORKDIR /
COPY --from=builder /kmod/* /kmod/
COPY probe.sh /probe.sh
ENTRYPOINT ["/bin/sh", "/probe.sh", "4"]
