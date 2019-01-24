# Pastecard for iOS

This is an experimental native app for [Pastecard](https://pastecard.net). It requires iOS 10 or later and is not guaranteed to always work or even be that nice.

To install this app on your own device:
1. Create a new project in Xcode and add all these files
2. Generate an iOS Development signing certificate in Xcode Preferences > Accounts
3. Connect your device and locate it in Window > Devices and Simulators
4. Make sure your device is the deployment target and Run the app
5. You may have to allow your certificate in Settings > General > Device Management

A few notes:
* The iOS app will go into the same __read-only mode__ as the web app when there's no internet connection
* __Swipe up__ on the card to force a refresh, share the entire card contents to another app, or sign out
* See [Pastecard Help](https://pastecard.net/help/) for more information
