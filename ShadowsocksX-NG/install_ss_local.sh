#!/bin/sh

#  install_ss_local.sh
#  ShadowsocksX-NG
#
#  Created by 邱宇舟 on 16/6/6.
#  Copyright © 2016年 qiuyuzhou. All rights reserved.


cd `dirname "${BASH_SOURCE[0]}"`
ssLocalVersion=3.3.5_4.static
mkdir -p "$HOME/Library/Application Support/ShadowsocksX-NG-R/ss-local-$ssLocalVersion"
cp -f ss-local "$HOME/Library/Application Support/ShadowsocksX-NG-R/ss-local-$ssLocalVersion/"
rm -f "$HOME/Library/Application Support/ShadowsocksX-NG-R/ss-local"
ln -s "$HOME/Library/Application Support/ShadowsocksX-NG-R/ss-local-$ssLocalVersion/ss-local" "$HOME/Library/Application Support/ShadowsocksX-NG-R/ss-local"

cp -f libcrypto.1.0.0.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-R/"

echo done
