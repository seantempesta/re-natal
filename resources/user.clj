(ns user
    (:use [figwheel-sidecar.repl-api :as ra]))
;; This namespace is loaded automatically by nREPL

;; read project.clj to get build configs
(def profiles (->> "project.clj"
                   slurp
                   read-string
                   (drop-while #(not= % :profiles))
                   (apply hash-map)
                   :profiles))

(def cljs-builds (get-in profiles [:dev :cljsbuild :builds]))

(defn figwheel-ios
      "Start figwheel for iOS build"
      []
      (ra/start-figwheel!
        {:build-ids  ["ios"]
         :all-builds cljs-builds})
      (ra/cljs-repl))

(defn figwheel-android
      "Start figwheel for Android build"
      []
      (ra/start-figwheel!
        {:build-ids  ["android"]
         :all-builds cljs-builds})
      (ra/cljs-repl))