(ns env.require-img)

(defmacro require-img
  "Load image from local packager service"
  [src]
          {:uri (str "http://localhost:8081/" src)})
