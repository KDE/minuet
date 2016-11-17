#!/bin/bash

cmake ../ -DCMAKE_TOOLCHAIN_FILE=/usr/share/ECM/toolchain/Android.cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${Qt5_android}" -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DQTANDROID_EXPORTED_TARGET=minuet -DANDROID_APK_DIR=../android/

make

mkdir -p "${INSTALL_DIR}"/share
mkdir -p "${INSTALL_DIR}"/lib/qml

make install/strip

make create-apk-minuet
