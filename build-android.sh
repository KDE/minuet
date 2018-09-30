#!/bin/bash

cmake ../ -DCMAKE_TOOLCHAIN_FILE=/usr/share/ECM/toolchain/Android.cmake -DCMAKE_BUILD_TYPE=Release -DECM_ADDITIONAL_FIND_ROOT_PATH=$Qt5_android -DCMAKE_INSTALL_PREFIX=../import -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DCMAKE_SYSROOT=/data/android-ndk-r10e/platforms/android-17/arch-arm -DCMAKE_ANDROID_API=17

# A diretiva -DQTANDROID_EXPORTED_TARGET esta gerando erro na execucao do cmake: nao encontra o cmake do Qt5Core
#cmake -DCMAKE_TOOLCHAIN_FILE=/usr/share/ECM/toolchain/Android.cmake -DCMAKE_BUILD_TYPE=Release -DECM_ADDITIONAL_FIND_ROOT_PATH="${Qt5_android}" -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DQTANDROID_EXPORTED_TARGET=minuet -DANDROID_APK_DIR=../android/ -DCMAKE_SYSROOT=/data/android-ndk-r10e/platforms/android-17/arch-arm/ ../

make

mkdir -p "${INSTALL_DIR}"/share
mkdir -p "${INSTALL_DIR}"/lib/qml

make install/strip

make create-apk-minuet
