# Re-Natal
### Bootstrap ClojureScript-based React Native apps with Reagent and re-frame
Artur Girenko, MIT License
[@drapanjanas](https://twitter.com/drapanjanas)

---

This project is a fork of [dmotz/natal](https://github.com/dmotz/natal) by Dan Motzenbecker with
the goal of generating skeleton of native app for iOS and Android based on
[Reagent](https://github.com/reagent-project/reagent) and [re-frame](https://github.com/Day8/re-frame).

The support of figwheel is based on solution developed by [decker405/figwheel-react-native](https://github.com/decker405/figwheel-react-native)
There are lots of limitations currently, but IMHO this is the right way to go in order to support both platforms.

Re-Natal is a simple command-line utility that automates most of the process of
setting up a React Native app running on ClojureScript with Reagent an re-frame.

Generated project works in iOS and Android devices.

## State
- Same codebase for iOS and Android
- Figwheel used for REPL and live coding.
  - Only works in "Debug in Chrome" mode
  - Works in iOS (tested using simulator).
  - Works in Android (tested on real device, encountered connection problem using Android simulator genymotion)
  - You can reload app any time, no problem.
- Optimizations :simple is used to compile "production" index.ios.js and index.android.js
- [Unified way of using static images of rn 0.14](https://facebook.github.io/react-native/docs/images.html) works

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

If your app's name is more than a single word, be sure to type it in CamelCase.
A corresponding hyphenated Clojure namespace will be created.

Re-Natal will create a simple skeleton based on the current
version of [Reagent](https://github.com/reagent-project/reagent) and [Day8/re-frame](https://github.com/Day8/re-frame).
If all goes well you should see printed out basic instructions how to run in iOS simulator.

```
$ cd future-app
```
To run in iOS:
```
$ cd re-natal xcode
```
and then run your app from Xcode normally.

To run in Android, run your simulator first or connect device and:
```
$ react-native run-android
```

Initially the ClojureScript is compiled in "prod" profile, meaning `index.*.js` files
are compiled with `optimizations :simple`.
Development in such mode is not fun because of slow compilation and long reload time.

Luckily, this can be improved by compiling with `optimizations :none` and using
figwheel.

To start development in `optimizations :none` mode you have to start "Debug in Chrome"
in your React Native application.

Then execute commands:
```
$ re-natal use-figwheel
$ lein figwheel ios
```
or for usage without figwheel:
```
$ re-natal use-reload
$ lein cljsbuild auto android
```

This will generate index.ios.js and index.android.js which works with compiler mode`optimizations :none`.

To run figwheel with real Android device please read [Running on Device](https://facebook.github.io/react-native/docs/running-on-device-android.html#content).
To make it work on USB connected device I had also to do the following:
```
$ adb reverse tcp:8081 tcp:8081
$ adb reverse tcp:3449 tcp:3449
```

You have to reload your app, and should see the REPL coming up with the prompt.

## REPL
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

## "Prod" build
Do this with command:
```
$ lein prod-build
```
It will clean and rebuild index.ios.js and index.android.js with `optimizations :simple`
After this you can reload the app and exit "Debug in Chrome".

Having index.ios.js and index.android.js build this way, you should be able to
follow the RN docs to proceed with the release.

## Tips
- Having `rlwrap` installed is optional but highly recommended since it makes
the REPL a much nicer experience with arrow keys.

- Running multiple React Native apps at once can cause problems with the React
Packager so try to avoid doing so.

- You can launch your app on the simulator without opening Xcode by running
`re-natal launch` in your app's root directory.

- By default new Natal projects will launch on the iPhone 6 simulator. To change
which device `re-natal launch` uses, you can run `re-natal listdevices` to see a list
of available simulators, then select one by running `re-natal setdevice` with the
index of the device on the list.

- To change advanced settings run `re-natal xcode` to quickly open the Xcode project.

- The Xcode-free workflow is for convenience. If you're encountering app crashes,
you should open the Xcode project and run it from there to view errors.


## Dependencies
As Re-Natal is the orchestration of many individual tools, there are quite a few dependencies.
If you've previously done React Native or Clojure development, you should hopefully
have most installed already. Platform dependencies are listed under their respective
tools.

- [npm](https://www.npmjs.com) `>=1.4`
    - [Node.js](https://nodejs.org) `>=4.0.0`
- [Leiningen](http://leiningen.org) `>=2.5.3`
    - [Java 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
- [Xcode](https://developer.apple.com/xcode) (+ Command Line Tools) `>=6.3`
    - [OS X](http://www.apple.com/osx) `>=10.10`
- [Watchman](https://facebook.github.io/watchman) `>=3.7.0`


## Aspirations
- [x] Xcode-free workflow with CLI tools
- [x] Templates for other ClojureScript React wrappers
- [ ] Automatic wrapping of all React Native component functions for ClojureScript
- [ ] Automatically run React packager in background
- [ ] Automatically tail cljs build log and report compile errors
- [ ] Working dev tools
- [ ] Automatic bundling for offline device usage and App Store distribution
- [x] Android support


Contributions are welcome.

For more ClojureScript React Native resources visit [cljsrn.org](http://cljsrn.org).
