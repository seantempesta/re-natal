(ns user
    (:use [figwheel-sidecar.repl-api :as ra]))
;; This namespace is loaded automatically by nRepl
;; copy of dev builds in project.cjs
(def builds {:ios     {:source-paths ["src" "env/dev"]
                       :figwheel     true
                       :compiler     {:output-to     "target/ios/not-used.js"
                                      :main          "env.ios.main"
                                      :output-dir    "target/ios"
                                      :optimizations :none}}
             :android {:source-paths ["src" "env/dev"]
                       :figwheel     true
                       :compiler     {:output-to     "target/android/not-used.js"
                                      :main          "env.android.main"
                                      :output-dir    "target/android"
                                      :optimizations :none}}})

(defn figwheel-ios
      "Start figwheel for iOS build"
      []
      (ra/start-figwheel!
       {:build-ids  ["ios"]
        :all-builds builds})
      (ra/cljs-repl))

(defn figwheel-android
      "Start figwheel for Android build"
      []
      (ra/start-figwheel!
       {:build-ids  ["android"]
        :all-builds builds})
      (ra/cljs-repl))