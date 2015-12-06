 (ns ^:figwheel-no-load env.$PLATFORM$.main
  (:require [$PROJECT_NAME_HYPHENATED$.$PLATFORM$.core :as core]
            [figwheel.client :as figwheel :include-macros true]))

 (enable-console-print!)

(figwheel/watch-and-reload
 :websocket-url "ws://$DEV_HOST$:3449/figwheel-ws"
 :heads-up-display false
 :jsload-callback core/mount-root)

 (core/init)
 (core/mount-root)


