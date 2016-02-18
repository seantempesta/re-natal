# Re-Natal
### Bootstrap ClojureScript-based React Native apps with Reagent and re-frame
Artur Girenko, MIT License
[@drapanjanas](https://twitter.com/drapanjanas)

---

This project is a fork of [dmotz/natal](https://github.com/dmotz/natal) by Dan Motzenbecker with
the goal of generating skeleton of native app for iOS and Android based on
[Reagent](https://github.com/reagent-project/reagent) and [re-frame](https://github.com/Day8/re-frame)
or [Om.Next](https://github.com/omcljs/om/wiki/Quick-Start-(om.next)).

The support of Figwheel is based on brilliant solution developed by Will Decker [decker405/figwheel-react-native](https://github.com/decker405/figwheel-react-native)
which works in both platforms.

Re-Natal is a simple command-line utility that automates most of the process of
setting up a React Native app running on ClojureScript with Reagent an re-frame.

Generated project works in iOS and Android devices.

For more ClojureScript React Native resources visit [cljsrn.org](http://cljsrn.org).

Contributions are welcome.

## State
- Uses React Native v0.20.0
- Same codebase for iOS and Android
- Figwheel used for REPL and live coding.
  - Works in iOS (real device and simulator).
  - Works in real Android device
  - Works in Android simulator Genymotion (with re-natal use-android-device genymotion)
  - Works in stock Android emulator (with re-natal use-android-device avd)
  - Figwheel REPL can be started within nREPL
  - Simultaneous development of iOS and Android apps is supported
  - You can reload app any time, no problem.
  - Custom react-native components are supported (with re-natal use-component <name>)
  - Source maps are available when you "Debug in Chrome" (with re-natal enable-source-maps)
- Optimizations :simple is used to compile "production" index.ios.js and index.android.js
- [Unified way of using static images of rn 0.14+](https://facebook.github.io/react-native/docs/images.html) works
- Works on Linux and Windows (Android only)

## Usage

Before getting started, make sure you have the
[required dependencies](#dependencies) installed.

Then, install the CLI using npm:

```
$ npm install -g re-natal
```

To bootstrap a new app, run `re-natal init` with your app's name as an argument:

```
$ re-natal init FutureApp
```
Or, for Om.Next project:

```
$ re-natal init FutureApp -i om-next
```

If your app's name is more than a single word, be sure to type it in CamelCase.
A corresponding hyphenated Clojure namespace will be created.

If all goes well you should see printed out basic instructions how to run in iOS simulator.

```
$ cd future-app
```
To run in iOS:
```
$ react-native run-ios
```
To run in Android, connect your device and:
```
$ adb reverse tcp:8081 tcp:8081
$ react-native run-android
```

Initially the ClojureScript is compiled in "prod" profile, meaning `index.*.js` files
are compiled with `optimizations :simple`.
Development in such mode is not fun because of slow compilation and long reload time.

Luckily, this can be improved by compiling with `optimizations :none` and using
Figwheel.

#### Using Figwheel in iOS simulator
Start your app from Xcode, or just run `react-native run-ios`

Then, to start development mode execute commands:
```
$ re-natal use-figwheel
$ lein figwheel ios
```
This will generate index.ios.js and index.android.js which works with compiler mode`optimizations :none`.

#### Using Figwheel in real Android device
To run figwheel with real Android device please read [Running on Device](https://facebook.github.io/react-native/docs/running-on-device-android.html#content).
To make it work on USB connected device I had also to do the following:
```
$ adb reverse tcp:8081 tcp:8081
$ adb reverse tcp:3449 tcp:3449
```
Then:
```
$ re-natal use-figwheel
$ lein figwheel android
```
And deploy your app:
```
$ react-native run-android
```
#### Using Figwheel in Genymotion simulator
With genymotion Android simulator you have to use IP "10.0.3.2" in urls to refer to your local machine.
To specify this use:
```
$ re-natal use-android-device genymotion
$ re-natal use-figwheel
$ lein figwheel android
```
Start your simulator and deploy your app:
```
$ react-native run-android
```

#### Using Figwheel in stock Android emulator (AVD)
With stock Android emulator you have to use IP "10.0.2.2" in urls to refer to your local machine.
To specify this use:
```
$ re-natal use-android-device avd
$ re-natal use-figwheel
$ lein figwheel android
```
Start your simulator and deploy your app:
```
$ react-native run-android
```
#### Swiching between Android devices
Run `use-android-device` to configure device type you want to use in development:
```
$ re-natal use-android-device <real|genymotion|avd>
$ re-natal use-figwheel
$ lein figwheel android
```

#### Developing iOS and Android apps simultaneously
```
$ re-natal use-figwheel
$ lein figwheel ios android
```
Then start iOS app from xcode, and Android by executing `react-native run-android`

#### Starting Figwheel REPL from nREPL
To start Figwheel within nREPL session:
```
$ lein repl
```
Then in the nREPL prompt type:
```
user=> (start-figwheel "ios")
```
Or, for Android build type:
```
user=> (start-figwheel "android")
```
Or, for both type:
```
user=> (start-figwheel "ios" "android")
```

## REPL
You have to reload your app, and should see the REPL coming up with the prompt.

At the REPL prompt, try loading your app's namespace:

```clojure
(in-ns 'future-app.ios.core)
```

Changes you make via the REPL or by changing your `.cljs` files should appear live
in the simulator.

Try this command as an example:

```clojure
(dispatch [:set-greeting "Hello Native World!"])
```
## Running on Linux
In addition to the instructions above on Linux you might need to
start React Native packager manually with command `react-native start`.
This was reported in [#3](https://github.com/drapanjanas/re-natal/issues/3)

See also [Linux and Windows support](https://facebook.github.io/react-native/docs/linux-windows-support.html)
in React Native docs.

## "Prod" build
Do this with command:
```
$ lein prod-build
```
It will clean and rebuild index.ios.js and index.android.js with `optimizations :simple`

Having index.ios.js and index.android.js build this way, you should be able to
follow the RN docs to proceed with the release.

## Using external React Native Components

Lets say you have installed an external library from npm like this:
```
$ npm i some-library --save
```

And you want to use a component called 'some-library/Component':
```clojure
(def Component (js/require "some-library/Component"))
```
This would work when you do `lein prod-build` and run your app, but will fail when you run with figwheel.
React Native packager statically scans for all calls to `require` function and prepares the required
code to be available at runtime. But, dynamically loaded (by figwheel) code bypass this scan
and therefore require of custom component fails.

To overcome this execute command:
```
$ re-natal use-component some-library/Component
```
Then, regenerate index.\*.js files:
```
$ re-natal use-figwheel
```
And last thing, probably, you will have to restart the packager and refresh your app.

NOTE: if you mistyped something, or no longer use the component and would like to remove it,
please, manually open .re-natal file and fix it there (its just a list of names in json format, so should be straight forward)

## Static Images
Since version 0.14 React Native supports a [unified way of referencing static images](https://facebook.github.io/react-native/docs/images.html)

In Re-Natal skeleton images are stored in "images" directory. Place your images there and reference them from cljs code:
```clojure
(def my-img (js/require "./images/my-img.png"))
```
#### Adding an image during development
When you have dropped a new image to "images" dir, you need to restart RN packager and re-run command:
```
$ re-natal use-figwheel
```
This is needed to regenerate index.\*.js files which includes `require` calls to all local images.
After this you can use a new image in your cljs code.

## Upgrading existing Re-Natal project
Do this if you want to use newer version of re-natal.

Commit or backup your current project, so that you can restore it in case of any problem ;)

Upgrade re-natal npm package
```
$ npm upgrade -g re-natal
```
In root directory of your project run
```
$ re-natal upgrade
```
This will overwrite only some files which usually contain fixes in newer versions of re-natal,
and are unlikely to be changed by the user. No checks are done, these files are just overwritten:
  - files in /env directory
  - figwheel-bridge.js

Then to continue development using figwheel
```
$ re-natal use-figwheel
```

To upgrade React Native to newer version please follow the official
[Upgrading](https://facebook.github.io/react-native/docs/upgrading.html) guide of React Native.
Re-Natal makes almost no changes to the files generated by react-native so the official guide should be valid.

### Enabling source maps when debugging in chrome
To make source maps available in "Debug in Chrome" mode re-natal patches
the react native packager to serve \*.map files from file system and generate only index.\*.map file.
To achieve this [this line](https://github.com/facebook/react-native/blob/master/packager/react-packager/src/Server/index.js#L413)
of file "node_modules/react-native/packager/react-packager/src/Server/index.js" is modified to match only index.\*.map

To do this run: `re-natal enable-source-maps` and restart packager.

You can undo this any time by deleting `node_modules` and running `re-natal deps`

## Example Apps
* [Luno](https://github.com/alwx/luno-react-native) is a demo mobile application written in ClojureScript.

## Tips
- Having `rlwrap` installed is optional but highly recommended since it makes
the REPL a much nicer experience with arrow keys.

- Running multiple React Native apps at once can cause problems with the React
Packager so try to avoid doing so.

- You can launch your app on the simulator without opening Xcode by running
`react-native run-ios` in your app's root directory (since RN 0.19.0).

- To change advanced settings run `re-natal xcode` to quickly open the Xcode project.

- If you have customized project layout and `re-natal upgrade` does not fit you well,
then these commands might be useful for you:
    * `re-natal copy-figwheel-bridge` - just copies figwheel-bridge.js from current re-natal

## Dependencies
As Re-Natal is the orchestration of many individual tools, there are quite a few dependencies.
If you've previously done React Native or Clojure development, you should hopefully
have most installed already. Platform dependencies are listed under their respective
tools.

- [npm](https://www.npmjs.com) `>=1.4`
    - [Node.js](https://nodejs.org) `>=4.0.0`
- [react-native-cli](https://www.npmjs.com/package/react-native-cli) `>=0.1.7` (install with `npm install -g react-native-cli`)
- [Leiningen](http://leiningen.org) `>=2.5.3`
    - [Java 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
- [Xcode](https://developer.apple.com/xcode) (+ Command Line Tools) `>=6.3` (optional for Android)
    - [OS X](http://www.apple.com/osx) `>=10.10`

