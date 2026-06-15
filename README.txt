FoodSnap
========

A tiny no-framework Android Java app for food photo logging.

What it does
------------

- Opens directly to a camera viewfinder.
- Tapping the viewfinder or the "FoodSnap!" button takes one photo.
- Saves the photo under:

    Pictures/<save folder>/<yyyy-MM-dd>/

  Default:

    Pictures/FoodSnap/2026-06-14/

- Uses date/time filenames with before/after and food/weight labels.
- Closes after saving.
- Has a thumbnail of the latest FoodSnap image.
- Tapping the thumbnail opens a newest-first gallery.
- Tapping a gallery image shows it full screen.
- Long-pressing a gallery image gives Show / Comment / Delete.
- Settings page includes:
  - save folder name
  - date display format
  - file name format
  - show/hide before/after buttons
  - show/hide food/weight buttons

Important
---------

This project is intentionally old-school:

- Plain Java
- No Gradle
- No Android Studio project
- No external libraries
- Uses the old android.hardware.Camera API
- minSdkVersion 14
- targetSdkVersion 22

You still need the Android SDK command-line tools because Android APKs require
aapt, dex conversion, APK signing, and android.jar.

Icon
----

You said your icon is named:

    FoodSnap.png

Put that file in the project root, next to build.bat. The build script copies it
to the correct Android resource name:

    res/drawable/foodsnap.png

Android resource filenames must be lowercase, so do not put FoodSnap.png
directly inside res/drawable.

Build on Windows cmd.exe
------------------------

From inside the FoodSnap folder:

    build.bat

The script expects either ANDROID_HOME or ANDROID_SDK_ROOT to point at your
Android SDK folder.

It also expects this SDK platform to exist:

    platforms\android-22\android.jar

And it expects a build-tools folder containing:

    aapt.exe
    d8.bat or dx.bat
    zipalign.exe
    apksigner.bat

Install
-------

After building:

    install.bat

Or manually:

    adb install -r build\FoodSnap-debug.apk

Notes on newer Android
----------------------

This app targets API 22 on purpose, which keeps the old install-time permission
model for old/simple devices. On newer Android versions, external storage rules
can be different depending on the device. The app is designed primarily for old
Android phones and sideloading.

License
-------

0BSD. See LICENSE.txt.
