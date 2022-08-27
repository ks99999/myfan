#!/bin/bash

URL=https://raw.githubusercontent.com/ks99999/myfan/main

error() {
        echo $1 | message error "Abort myfan installation."
        exit 1
}

cd /home/user
wget --no-cache -O hello "$URL/hello"
[[ $? -ne 0 ]] && error "Could not download hello"
wget --no-cache -O myfan.sh "$URL/myfan.sh"
[[ $? -ne 0 ]] && error "Could not download myfan.sh"
wget --no-cache -O myfan "$URL/myfan"
[[ $? -ne 0 ]] && error "Could not download myfan"
wget --no-cache -O ykeda_autofan "$URL/ykeda_autofan"
[[ $? -ne 0 ]] && error "Could not download ykeda_autofan"

chmod 755 hello
chmod 755 ykeda_autofan
chmod 755 myfan*
cp ykeda_autofan /hive/opt/ykeda/
cp hello /hive/bin/
rm ykeda_autofan
rm hello
hello
message info "myfan installation successful"
