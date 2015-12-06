(ns env.require-img)

(defmacro require-img
  "Load image from local packager service"
  [src]
          {:uri (str "http://$DEV_HOST$:8081/" src)})
