#!/bin/bash

#cmake ../ -DCMAKE_TOOLCHAIN_FILE=/usr/share/ECM/toolchain/Android.cmake -DCMAKE_BUILD_TYPE=Release -DECM_ADDITIONAL_FIND_ROOT_PATH=$Qt5_android -DCMAKE_INSTALL_PREFIX=../import -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DCMAKE_SYSROOT=$CMAKE_SYSROOT -DCMAKE_ANDROID_API=29 -DQTANDROID_EXPORTED_TARGET=minuet -DANDROID_APK_DIR=../android/ -DANDROID_ABI=arm64-v8a

# A diretiva -DQTANDROID_EXPORTED_TARGET esta gerando erro na execucao do cmake: nao encontra o cmake do Qt5Core
#cmake -DCMAKE_TOOLCHAIN_FILE=/usr/share/ECM/toolchain/Android.cmake -DCMAKE_BUILD_TYPE=Release -DECM_ADDITIONAL_FIND_ROOT_PATH="${Qt5_android}" -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DQTANDROID_EXPORTED_TARGET=minuet -DANDROID_APK_DIR=../android/ -DCMAKE_SYSROOT=/data/android-ndk-r10e/platforms/android-29/arch-arm/ ../

cmake ../ -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DCMAKE_SYSROOT=$CMAKE_SYSROOT -DCMAKE_ANDROID_API=21 -DANDROID_PLATFORM=21 -DANDROID_ABI=arm64-v8a -DECM_DIR=/usr/share/ECM/cmake/ -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH -DCMAKE_PREFIX_PATH=$Qt5_android

make

mkdir -p "${INSTALL_DIR}"/share
mkdir -p "${INSTALL_DIR}"/lib/qml

make install/strip

make minuet-apk
