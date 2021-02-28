# SoundsBoard

Soundboard is an iOS app and widget for creating custom sounds board. Sounds can be recorded directly from the app or created from audio and video files including Youtube videos.

## Features
- Sounds can be added from:
  - Recroder within the app.
  - Audio/video files.
  - Youtube videos.
- Vidoes will be converted autoamticlly.
- Name and thumbnail for each sound.
- Trim length of the sound.
- Shortcut to allow Siri to play any sound within the app.
- Widget to easily play favorite sounds.


## Project Build

### Using CocoaPods

First, install [CocoaPods](http://cocoapods.org) with the following command:

```bash
$ gem install cocoapods
```

Then, run the following command inside the project directory before opening the project with Xcode:

```bash
$ pod install
```

Then if Pod installation completed successfully, Open 'SoundsBoard.xcworkspace' via Xcode.

### App Group

In case you changed the app group name. Head to this [file](https://github.com/ghanem-mhd/SoundsBoardApp/blob/master/SBKit/utilities/Constants.swift) and change the appGroupID constant.
