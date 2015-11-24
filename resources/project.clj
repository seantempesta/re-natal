(defproject $PROJECT_NAME_HYPHENATED$ "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.7.0"]
                 [org.clojure/clojurescript "1.7.170"]
                 [reagent "0.5.1" :exclusions [cljsjs/react]]
                 [re-frame "0.5.0"]]
 :plugins [[lein-cljsbuild "1.1.1"]]
            :cljsbuild {:builds {:dev     {:source-paths ["src"]
                                           :compiler     {:output-to     "index.ios.js"
                                                          :main          "$PROJECT_NAME_HYPHENATED$.ios.core"
                                                          :output-dir    "target/out"
                                                          :optimizations :simple}}
                                 :android {:source-paths ["src"]
                                           :compiler     {:output-to     "index.android.js"
                                                          :main          "$PROJECT_NAME_HYPHENATED$.android.core"
                                                          :output-dir    "target/android"
                                                          :optimizations :simple}}}})