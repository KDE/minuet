#!/bin/bash

cd ../Csound/Android/
export NDK_MODULE_PATH=$PWD/../../Csound-build/android/
export ANDROID_NDK_ROOT=$ANDROID_NDK
./downloadDependencies.sh
sh build-all.sh
