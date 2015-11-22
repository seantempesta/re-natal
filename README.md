# Re-Natal
### Bootstrap ClojureScript-based React Native apps with Reagent and re-frame
Artur Girenko, MIT License
[@drapanjanas](https://twitter.com/drapanjanas)

---

This project is a fork of [dmotz/natal](https://github.com/dmotz/natal) by Dan Motzenbecker with
the goal of generating skeleton of native app for iOS and Android based on
[Reagent](https://github.com/reagent-project/reagent) and [re-frame](https://github.com/Day8/re-frame).

Re-Natal is a simple command-line utility that automates most of the process of
setting up a React Native app running on ClojureScript with Reagent an re-frame.

It stands firmly on the shoulders of giants, specifically those of
[Mike Fikes](http://blog.fikesfarm.com) who created
[Ambly](https://github.com/omcljs/ambly) and the
[documentation](http://cljsrn.org/ambly.html)
on setting up a ClojureScript React Native app.

Generated project works in iOS and Android devices.

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
If all goes well your app should compile and boot in the iOS simulator.

From there you can begin an interactive workflow by starting the REPL.

```
$ cd future-app
$ re-natal repl
```

If there are no issues, the REPL should connect to the simulator automatically.
To manually choose which device it connects to, you can run `re-natal repl --choose`.

At the prompt, try loading your app's namespace:

```clojure
(in-ns 'future-app.ios.core)
```

Changes you make via the REPL or by changing your `.cljs` files should appear live
in the simulator.

Try this command as an example:

```clojure
(dispatch [:set-greeting "Hello Native World!"])
```

When the REPL connects to the simulator it will print the location of its
compilation log. It's useful to tail it to see any errors, like so:

```
$ tail -f /Volumes/Ambly-81C53995/watch.log
```

## Running in Android

Connect start Android simulator or connect your device.
Close React packager window of iOS app, if running.

```
$ cd future-app
$ re-natal run-android
```
This will build and run app in Android
using [React Native](https://facebook.github.io/react-native/docs/getting-started.html#content) CLI.

To enable "live coding"
bring up the menu in Android app, go to "Dev Settings" and enable
"Auto reload on JS change"

Then run Leiningen build
```
$ lein cljsbuild auto android
```
Changes in .cljs files should be reflected in running application.

Current limitation that this will reload whole application meaning the app-db
will be restored to initial state.

The REPL in android is not available... Contributions are welcome.

## Tips
- Having `rlwrap` installed is optional but highly recommended since it makes
the REPL a much nicer experience with arrow keys.

- Don't press ⌘-R in the simulator; code changes should be reflected automatically.
See [this issue](https://github.com/omcljs/ambly/issues/97) in Ambly for details.

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
As Natal is the orchestration of many individual tools, there are quite a few dependencies.
If you've previously done React Native or Clojure development, you should hopefully
have most installed already. Platform dependencies are listed under their respective
tools.

- [npm](https://www.npmjs.com) `>=1.4`
    - [Node.js](https://nodejs.org) `>=4.0.0`
- [Leiningen](http://leiningen.org) `>=2.5.3`
    - [Java 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
- [CocoaPods](https://cocoapods.org) `>=0.38.2`
    - [Ruby](https://www.ruby-lang.org) `>=2.0.0`
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
