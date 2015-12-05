 (ns ^:figwheel-no-load env.$PLATFORM$.main
  (:require [$PROJECT_NAME_HYPHENATED$.$PLATFORM$.core :as core]))

 (enable-console-print!)

 (core/init)
 (core/mount-root)


