# Pastecard for iOS

This is an experimental native app for [Pastecard](http://pastecard.net), written in Swift. It requires iOS 11.2 or later, is intended for iPhones only (no iPads), and is not guaranteed to always work or even be that nice.

To install this app on your own device:
1. Create a new project in Xcode and add all these files
2. Generate an iOS Development signing certificate in Xcode Preferences > Accounts
3. Connect your iPhone and locate it in Window > Devices and Simulators
4. Make sure your iPhone is the deployment target and Run the app
5. You may have to allow your certificate in Settings > General > Device Management
6. You may have to add pastecard.net as an [exception domain](https://stackoverflow.com/questions/31254725/transport-security-has-blocked-a-cleartext-http) in Xcode 

A few notes:
* The iOS app will go into the same __read-only mode__ as the web app when there's no internet connection
* __Swipe up__ on the card to force a refresh or sign out
* See [Pastecard Help](http://pastecard.net/help/) for more information
