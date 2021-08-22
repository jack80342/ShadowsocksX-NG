# ShadowsocksX-NG

[![Build Status](https://travis-ci.org/shadowsocksr/ShadowsocksX-NG.svg?branches=develop)](https://travis-ci.org/shadowsocksr/ShadowsocksX-NG)

Next Generation of Shadowsocks(R) macOS client.

## Why?

The original implement embed ss-local source. This makes it hard to update ss-local.

Now I just copy the [ss-local](https://formulae.brew.sh/formula/shadowsocks-libev) from Homebrew. Run ss-local executable as a Launch Agent in background. 
Serve pac js file as a file url. So only some souce code related to GUI left. 

## Requirements

### Running

- macOS Sierra(v11.0+)

### Building

- Xcode 12.0+

## Features

- SS support
- limited SSR support
- subscription support (Clash and Shadowrocket)
- find QR code on your screen


## Differences from original ShadowsocksX

Run ss-local as backgroud service through launchd, not in app process.
So after you quit the app, the ss-local maybe is still running. 

Add a manual mode which won't configure the system proxy settings. 
Then you could configure your apps to use socks5 proxy manual.

## License

The project is released under the terms of GPLv3.
