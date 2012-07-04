#!/bin/bash

log(){
    printf "\n\033[32m$*\033[00m\n"
    echo -e "Log: ${1}\n" >> install_gapps.log
}

push_files(){
    push_source="${1}"
    push_target="${2}"
    root_dir="${PWD}"

    echo "Pushing ${push_source}"
    cd "${push_source}"
    for file in `ls -1 .`
    do
        log "Pushing ${file} to ${push_target}"
        until $ADB_COMMAND push "${file}" "${push_target}"; do
            echo "$? - Trouble pushing file ${file} - please disconnect and re-connect your android device"
            until $ADB_COMMAND root; do
                echo 'Could not connect - sleeping 20 seconds before trying again...'
                sleep 20
            done
        done
        sleep 1
    done
    cd $root_dir
}


# rm platform-tools_r12-linux.zip
if test ! -e platform-tools_r12-linux.zip; then
    wget http://dl-ssl.google.com/android/repository/platform-tools_r12-linux.zip
fi
unzip -o -j platform-tools_r12-linux.zip platform-tools/adb
if [ $? -ne "0" ]; then
    exit; 
fi
mkdir ~/.android 2> /dev/null

if test ! -e ~/android/adb_usb.ini; then
    echo "0x2207" >> ~/.android/adb_usb.ini
fi


# rm gapps-ics-20120429-signed.zip
if test ! -e gapps-ics-20120429-signed.zip; then
    wget http://goo.im/gapps/gapps-ics-20120429-signed.zip
fi
unzip -q -o -d gapps gapps-ics-20120429-signed.zip system/*
if [ $? -ne "0" ]; then 
    exit 
fi

ADB_COMMAND="`pwd`/adb"

echo "ADB_COMMAND is $ADB_COMMAND"

$ADB_COMMAND root


## START For testing
$ADB_COMMAND shell 'if [ ! -e "/sdcard/mysystem" ]; then mkdir /sdcard/mysystem 2>/dev/null; echo "Created /sdcard/mysystem $?"; else echo "Directory /sdcard/mysystem already created";fi'
$ADB_COMMAND shell 'if [ ! -e "/sdcard/mysystem/framework" ]; then mkdir /sdcard/mysystem/framework 2>/dev/null; echo "Created /sdcard/mysystem/framework $?"; else echo "Directory /sdcard/mysystem/framework already created";fi'
$ADB_COMMAND shell 'if [ ! -e "/sdcard/mysystem/lib" ]; then mkdir /sdcard/mysystem/lib 2>/dev/null; echo "Created /sdcard/mysystem/lib $?"; else echo "Directory /sdcard/mysystem/lib already created";fi'
$ADB_COMMAND shell 'if [ ! -e "/sdcard/mysystem/etc" ]; then mkdir /sdcard/mysystem/etc 2>/dev/null; echo "Created /sdcard/mysystem/etc $?"; else echo "Directory /sdcard/mysystem/etc already created";fi'
$ADB_COMMAND shell 'if [ ! -e "/sdcard/mysystem/etc/permissions" ]; then mkdir /sdcard/mysystem/etc/permissions 2>/dev/null; echo "Created /sdcard/mysystem/etc/permissions $?"; else echo "Directory /sdcard/mysystem/etc/permissions already created";fi'
$ADB_COMMAND shell 'if [ ! -e "/sdcard/mysystem/app" ]; then mkdir /sdcard/mysystem/app 2>/dev/null; echo "Created /sdcard/mysystem/app $?"; else echo "Directory /sdcard/mysystem/app already created";fi'
TARGET_DIR='/sdcard/mysystem'
## End For Testing


## START For real...
TARGET_DIR='/system'
$ADB_COMMAND shell 'mount -o remount,rw,noatime,nodiratime,barrier=0,data=ordered /dev/block/mtdblock8 /system'
## End for real

echo "TARGET_DIR is $TARGET_DIR"

push_files "gapps/system/framework" "$TARGET_DIR/framework"
push_files "gapps/system/lib" "$TARGET_DIR/lib"
push_files "gapps/system/etc/permissions" "$TARGET_DIR/etc/permissions"
push_files "gapps/system/app" "$TARGET_DIR/app"

$ADB_COMMAND reboot
