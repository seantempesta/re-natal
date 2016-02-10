(ns ^:figwheel-no-load env.$PLATFORM$.main
  (:require [om.next :as om]
            [$PROJECT_NAME_HYPHENATED$.$PLATFORM$.core :as core]
            [$PROJECT_NAME_HYPHENATED$.state :as state]
            [figwheel.client :as figwheel :include-macros true]))

(enable-console-print!)

(figwheel/watch-and-reload
  :websocket-url "ws://localhost:3449/figwheel-ws"
  :heads-up-display true
  :jsload-callback #(om/add-root! state/reconciler core/AppRoot 1))

(core/init)

(def root-el (core/app-root))