(ns $PROJECT_NAME_HYPHENATED$.handlers
  (:require
    [re-frame.core :refer [register-handler path trim-v after dispatch]]))

(def app-db {:greeting "Hello Clojure in iOS and Android!"})

(register-handler
  :initialize-db
  (fn [_ _]
    app-db))

(register-handler
  :set-greeting
  (fn [db [_ value]]
    (assoc db :greeting value)))