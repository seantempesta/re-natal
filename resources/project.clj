(defproject $PROJECT_NAME_HYPHENATED$ "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.7.0"]
                 [org.clojure/clojurescript "1.7.145"]
                 [reagent "0.5.1" :exclusions [cljsjs/react]]
                 [org.omcljs/ambly "0.6.0"]
                 [re-frame "0.5.0"]]
 :plugins [[lein-cljsbuild "1.1.0"]]
            :cljsbuild {:builds {:dev     {:source-paths ["src"]
                                           :compiler     {:output-to     "target/out/main.js"
                                                          :output-dir    "target/out"
                                                          :optimizations :none}}
                                 :android {:source-paths ["src"]
                                           :compiler     {:output-to     "native/index.android.js"
                                                          :output-dir    "target/android"
                                                          :optimizations :simple}}}})