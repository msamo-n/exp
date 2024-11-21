#!/bin/bash

echo "I am gradlew, I am doing $@"
sleep 10
if [[ "$1" == lint* ]]; then
    echo "I am gradlew, I am failing"
    exit 1
fi
if [[ "$1" == assemble* ]]; then
    VAR="${1##assemble}"
    APK_DIR_NAME="${VAR,}"
    mkdir -p "build/outputs/apk/$APK_DIR_NAME"
    echo "Content of APK" > "build/outputs/apk/$APK_DIR_NAME/app.apk"
fi
echo "I am gradlew, I am done"
exit 0