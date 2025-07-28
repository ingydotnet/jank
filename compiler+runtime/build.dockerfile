FROM ubuntu:24.10

RUN apt update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        build-essential \
        clang \
        cmake \
        curl \
        doctest-dev \
        entr \
        g++ \
        gcc \
        git \
        git-lfs \
        libbz2-dev \
        libclang-dev \
        libdouble-conversion-dev \
        libffi-dev \
        libgc-dev \
        libssl-dev \
        libzip-dev \
        llvm \
        llvm-dev \
        ninja-build \
        pkg-config \
        zip \
        zlib1g-dev \
 && true
