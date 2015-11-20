(ns $PROJECT_NAME_HYPHENATED$.ios.core
  (:require [reagent.core :as r :refer [atom]]
            [re-frame.core :refer [subscribe dispatch dispatch-sync]]
            [commutewise-app.handlers]
            [commutewise-app.subs]))

(set! js/React (js/require "react-native"))

(def text (r/adapt-react-class (.-Text js/React)))
(def view (r/adapt-react-class (.-View js/React)))
(def image (r/adapt-react-class (.-Image js/React)))
(def touchable-highlight (r/adapt-react-class (.-TouchableHighlight js/React)))

(defn widget []
  (let [greeting (subscribe [:get-greeting])]
    (fn []
      [view {:style {:flexDirection "column" :margin 40 :alignItems "center"}}
       [text {:style {:fontSize 30 :fontWeight "100" :marginBottom 20 :textAlign "center"}} @greeting]
       [image {:source {:uri "https://raw.githubusercontent.com/cljsinfo/logo.cljs/master/cljs.png"}
               :style  {:width 80 :height 80 :marginBottom 30}}]
       [touchable-highlight {:style {:backgroundColor "#999" :padding 10 :borderRadius 5}}
        [text {:style {:color "white" :textAlign "center" :fontWeight "bold"}} "press me"]]])))

(r/render [widget] 1)

(defn ^:export init []
  (dispatch-sync [:initialize-db])
  ((fn render []
     (.requestAnimationFrame js/window render))))
