# https://solarianprogrammer.com/2018/05/06/building-gcc-cross-compiler-raspberry-pi/

# Raspberry Pi equivalent
FROM debian:buster

# This should match the one on your raspi
ENV GCC_VERSION gcc-8.3.0
ENV GLIBC_VERSION glibc-2.28
ENV BINUTILS_VERSION binutils-2.31.1

# Install some tools and compilers + clean up
RUN apt-get update && \
    apt-get install -y git wget gcc-8 g++-8 cmake gdb gdbserver bzip2 && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Use GCC 8 as the default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 999 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 999 \
 && update-alternatives --install /usr/bin/cc  cc  /usr/bin/gcc-8 999 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-8 999

# Add a user called `develop`
RUN useradd -ms /bin/bash develop
RUN echo "develop   ALL=(ALL:ALL) ALL" >> /etc/sudoers

WORKDIR /home/develop

# Download and extract GCC
RUN wget https://ftp.gnu.org/gnu/gcc/${GCC_VERSION}/${GCC_VERSION}.tar.gz && \
    tar xf ${GCC_VERSION}.tar.gz && \
    rm ${GCC_VERSION}.tar.gz
# Download and extract LibC
RUN wget https://ftp.gnu.org/gnu/libc/${GLIBC_VERSION}.tar.bz2 && \
    tar xjf ${GLIBC_VERSION}.tar.bz2 && \
    rm ${GLIBC_VERSION}.tar.bz2
# Download and extract BinUtils
RUN wget https://ftp.gnu.org/gnu/binutils/${BINUTILS_VERSION}.tar.bz2 && \
    tar xjf ${BINUTILS_VERSION}.tar.bz2 && \
    rm ${BINUTILS_VERSION}.tar.bz2
# Download the GCC prerequisites
RUN cd ${GCC_VERSION} && contrib/download_prerequisites && rm *.tar.*
#RUN cd gcc-9.2.0 && contrib/download_prerequisites && rm *.tar.*

# Build BinUtils
RUN mkdir -p /opt/cross-pi-gcc
WORKDIR /home/develop/build-binutils
RUN ../${BINUTILS_VERSION}/configure \
        --prefix=/opt/cross-pi-gcc --target=arm-linux-gnueabihf \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --disable-multilib
RUN make -j$(nproc)
RUN make install

# Build the first part of GCC
WORKDIR /home/develop/build-gcc
RUN ../${GCC_VERSION}/configure \
        --prefix=/opt/cross-pi-gcc \
        --target=arm-linux-gnueabihf \
        --enable-languages=c,c++,fortran \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --disable-multilib
RUN make -j$(nproc) all-gcc
RUN make install-gcc
ENV PATH=/opt/cross-pi-gcc/bin:${PATH}

# Install dependencies
RUN apt-get update && \
    apt-get install -y gawk bison python3 && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Download and install the Linux headers
WORKDIR /home/develop
RUN git clone --depth=1 https://github.com/raspberrypi/linux
WORKDIR /home/develop/linux
ENV KERNEL=kernel7
RUN make ARCH=arm INSTALL_HDR_PATH=/opt/cross-pi-gcc/arm-linux-gnueabihf headers_install

# Build GLIBC
WORKDIR /home/develop/build-glibc
RUN ../${GLIBC_VERSION}/configure \
        --prefix=/opt/cross-pi-gcc/arm-linux-gnueabihf \
        --build=$MACHTYPE --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf \
        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
        --with-headers=/opt/cross-pi-gcc/arm-linux-gnueabihf/include \
        --disable-multilib libc_cv_forced_unwind=yes
RUN make install-bootstrap-headers=yes install-headers
RUN make -j8 csu/subdir_lib
RUN install csu/crt1.o csu/crti.o csu/crtn.o /opt/cross-pi-gcc/arm-linux-gnueabihf/lib
RUN arm-linux-gnueabihf-gcc -nostdlib -nostartfiles -shared -x c /dev/null \
        -o /opt/cross-pi-gcc/arm-linux-gnueabihf/lib/libc.so
RUN touch /opt/cross-pi-gcc/arm-linux-gnueabihf/include/gnu/stubs.h

# Continue building GCC
WORKDIR /home/develop/build-gcc
RUN make -j$(nproc) all-target-libgcc
RUN make install-target-libgcc

# Finish building GLIBC
WORKDIR /home/develop/build-glibc
RUN make -j$(nproc)
RUN make install

# Finish building GCC
WORKDIR /home/develop/build-gcc
RUN make -j$(nproc)
RUN make install

#RUN cp -r /opt/cross-pi-gcc /opt/cross-pi-${GCC_VERSION}
#
#WORKDIR /home/develop/build-gcc9
#RUN ../gcc-9.2.0/configure \
#        --prefix=/opt/cross-pi-gcc \
#        --target=arm-linux-gnueabihf \
#        --enable-languages=c,c++,fortran \
#        --with-arch=armv6 --with-fpu=vfp --with-float=hard \
#        --disable-multilib
#RUN make -j$(nproc) all-gcc
#RUN make install-gcc

# Compile opencv4
# https://solarianprogrammer.com/2018/12/18/cross-compile-opencv-raspberry-pi-raspbian/
# Install armhf needed libraries
RUN dpkg --add-architecture armhf
RUN apt-get update
RUN apt-get install -y pkg-config

# Opencv dependencies
RUN apt-get install -y libgtk-3-dev:armhf libcanberra-gtk3-dev:armhf
RUN apt-get install -y libtiff-dev:armhf zlib1g-dev:armhf
RUN apt-get install -y libjpeg-dev:armhf libpng-dev:armhf
RUN apt-get install -y libavcodec-dev:armhf libavformat-dev:armhf libswscale-dev:armhf libv4l-dev:armhf
RUN apt-get install -y libxvidcore-dev:armhf libx264-dev:armhf
RUN apt-get install -y libfreetype6-dev:armhf libharfbuzz-dev:armhf

# Download Opencv
RUN mkdir -p /home/develop/opencv_all
WORKDIR /home/develop/opencv_all
RUN wget -O opencv.tar.gz https://github.com/opencv/opencv/archive/4.1.0.tar.gz
RUN tar xf opencv.tar.gz
RUN wget -O opencv_contrib.tar.gz https://github.com/opencv/opencv_contrib/archive/4.1.0.tar.gz
RUN tar xf opencv_contrib.tar.gz
RUN rm *.tar.gz

# Set env
ENV PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig
ENV PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig
ENV LD_LIBRARY_PATH=/opt/cross-pi-gcc/lib:/usr/lib/arm-linux-gnueabihf:/lib/arm-linux-gnueabihf:/opt/opencv-4.1.0/lib
ENV LD_RUN_PATH=/usr/lib/arm-linux-gnueabihf:/lib/arm-linux-gnueabihf:/opt/opencv-4.1.0/lib

# Compile opencv
RUN mkdir -p /home/develop/opencv_all/opencv-4.1.0/build
WORKDIR /home/develop/opencv_all/opencv-4.1.0/build
RUN echo "tmp"
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_CXX_FLAGS=-mfloat-abi=hard -L/opt/cross-pi-gcc/arm-linux-gnueabihf/include/linux \
          -D CMAKE_INSTALL_PREFIX=/opt/opencv-4.1.0 \
          -D CMAKE_TOOLCHAIN_FILE=../platforms/linux/arm-gnueabi.toolchain.cmake \
          -D OPENCV_EXTRA_MODULES_PATH=/home/develop/opencv_all/opencv_contrib-4.1.0/modules \
          -D OPENCV_ENABLE_NONFREE=ON \
          -D ENABLE_NEON=ON \
          -D ENABLE_VFPV3=ON \
          -D BUILD_TESTS=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_OPENCV_PYTHON2=OFF \
          -D BUILD_OPENCV_PYTHON3=OFF \
          -D BUILD_EXAMPLES=OFF ..

#RUN find / -name "limits.h" -print
RUN sed -i -e 's@limits.h@linux/limits.h@g' /home/develop/opencv_all/opencv-4.1.0/3rdparty/libjasper/jasper/jas_stream.h
RUN sed -i -e 's@limits.h@linux/limits.h@g' /home/develop/opencv_all/opencv-4.1.0/modules/ts/src/ts_gtest.cpp
RUN sed -i -e 's@limits.h@linux/limits.h@g' /home/develop/opencv_all/opencv-4.1.0/3rdparty/ittnotify/src/ittnotify/ittnotify_static.c

RUN make -j$(nproc)
RUN make install/strip

# Load pkg_config
WORKDIR /home/develop
RUN git clone https://gist.github.com/sol-prog/ed383474872958081985de733eaf352d opencv_cpp_compile_settings
RUN cd opencv_cpp_compile_settings
RUN cp /home/develop/opencv_cpp_compile_settings/opencv.pc /usr/lib/arm-linux-gnueabihf/pkgconfig

# Compile Wiringpi
WORKDIR /home/develop
RUN git clone https://github.com/WiringPi/WiringPi.git
WORKDIR /home/develop/WiringPi
ENV WIRINGPI_SUDO=
RUN find . -name Makefile -exec sed -i -e "s@gcc@arm-linux-gnueabihf-gcc@g" {} \;
RUN sh build


#TODO Clean home

WORKDIR /home/develop
USER develop