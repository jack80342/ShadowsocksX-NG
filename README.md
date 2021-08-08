# ShadowsocksX-NG-R

[![Build Status](https://travis-ci.org/shadowsocksr/ShadowsocksX-NG.svg?branches=develop)](https://travis-ci.org/shadowsocksr/ShadowsocksX-NG)

Next Generation of Shadowsocks(R) macOS client.

## Why?

The original implement embed ss-local source. This makes it hard to update ss-local.

Now I just copy the [ss-local](https://formulae.brew.sh/formula/shadowsocks-libev) from Homebrew. Run ss-local executable as a Launch Agent in background. 
Serve pac js file as a file url. So only some souce code related to GUI left. 

## Requirements

### Running

- macOS Sierra(v10.12+)

### Building

- Xcode 12.0+

## Features

- New Subscription URL support (Clash and Shadowrocket)
- Show up/down speed
- Limited SSR support
- White domain list & white IP list
- Use ss-local from shadowsocks-libev 3.3.5_3
- Auto update PAC by download GFW List from GitHub. (You can even customize your list)
- Auto update ACL white list from GutHub. (You can even customize your list)
- Show QRCode for current server profile
- Scan QRCode from screen
- Import config.json to config all your servers
- Auto launch at login
- User rules for PAC

## Differences from original ShadowsocksX

Run ss-local as backgroud service through launchd, not in app process.
So after you quit the app, the ss-local maybe is still running. 

Add a manual mode which won't configure the system proxy settings. 
Then you could configure your apps to use socks5 proxy manual.

## License

The project is released under the terms of GPLv3.

