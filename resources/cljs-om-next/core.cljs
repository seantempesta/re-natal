(ns $PROJECT_NAME_HYPHENATED$.$PLATFORM$.core
  (:require-macros [natal-shell.components :refer [view text image touchable-highlight]]
                   [natal-shell.alert :refer [alert]])
  (:require [om.next :as om :refer-macros [defui]]))

(set! js/React (js/require "react-native"))

(def app-registry (.-AppRegistry js/React))
(def logo-img (js/require "./images/cljs.png"))

(defui AppRoot
       Object
       (render [this]
               (view {:style {:flexDirection "column" :margin 40 :alignItems "center"}}
                     (text {:style {:fontSize 30 :fontWeight "100" :marginBottom 20 :textAlign "center"}} "Hello World!")
                     (image {:source logo-img
                             :style  {:width 80 :height 80 :marginBottom 30}})
                     (touchable-highlight {:style {:backgroundColor "#999" :padding 10 :borderRadius 5}
                                           :onPress #(alert "HELLO!")}
                                          (text {:style {:color "white" :textAlign "center" :fontWeight "bold"}} "press me")))))

(def app-root (om/factory AppRoot))

(defn init []
      (.registerComponent app-registry "ReagentApp" #(app-root)))