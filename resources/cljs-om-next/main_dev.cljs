(ns ^:figwheel-no-load env.$PLATFORM$.main
  (:require [om.next :as om :refer-macros [defui]]
            [$PROJECT_NAME_HYPHENATED$.$PLATFORM$.core :as core]
            [figwheel.client :as figwheel :include-macros true]))

(enable-console-print!)

(defui Reloader
       Object
       (render [_] (core/app-root)))

(def reloader (om/factory Reloader))
(def root-el (reloader))

(figwheel/watch-and-reload
  :websocket-url "ws://localhost:3449/figwheel-ws"
  :heads-up-display true
  ;; :jsload-callback #(.forceUpdate Reloader)
  )

(core/init)