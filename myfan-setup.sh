#!/bin/bash

URL=https://raw.githubusercontent.com/ks99999/myfan/main

error() {
        echo $1 | message error "Abort myfan installation."
        exit 1
}

wget -O hello "$URL/hello"
[[ $? -ne 0 ]] && error "Could not download hello"
wget -O myfan.sh "$URL/myfan.sh"
[[ $? -ne 0 ]] && error "Could not download myfan.sh"
wget -O myfan "$URL/myfan"
[[ $? -ne 0 ]] && error "Could not download myfan"
wget -O ykeda_autofan "$URL/ykeda_autofan"
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
