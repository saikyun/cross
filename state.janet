(use freja/flow)

(def game-size [128 128])

(def scaling 5)

(var tiles nil)

(var steve nil)

(def sprites
  {:steve-attack [16 0 16 16]
   :steve-stand [0 0 16 16]
   :steve-dead [0 16 16 16]
   :cross [32 0 16 16]
   :skel-stand [48 0 16 16]})

(def gos @[])

(defn scale-pos
  [pos]
  (def scaling 1)
  (map (comptime |(math/floor (* scaling (math/floor (/ $ scaling))))) pos))

(var death-timer 0)
