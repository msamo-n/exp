#!/bin/bash

echo "I am gradlew, I am doing $@"
sleep 20
if [[ "$1" == lint* ]]; then
    echo "I am gradlew, I am failing"
    exit 1
fi
if [[ "$1" == assemble* ]]; then
    VAR="${1##assemble}"
    MODNAME="base"
    APK_DIR="$MODNAME/build/outputs/apk/${VAR,}"
    mkdir -p "$APK_DIR"
    echo "Content of APK" > "$APK_DIR/app.apk"
fi
echo "I am gradlew, I am done"
exit 0