(use freja/flow)
(use ./state)
(use ./render)

(defn update-cross
  [self]
  (when (self :cooldown)
    (update self :cooldown - (get-frame-time))
    (when (neg? (self :cooldown))
      (put self :cooldown nil)))

  (def {:pos pos
        :speed speed
        :dir dir} self)

  (if (self :cooldown)
    (update self :speed - (* 100 (get-frame-time)))
    (update self :speed * 0.9))

  (update self :pos v/v+ (v/v* dir
                               (* speed (get-frame-time))))

  (let [{:pos pos :size size :offset offset} self]
    (loop [go :in gos
           :when (not= go self)
           :when (go :damage)
           :when
           (check-collision-recs [;(v/v- (scale-pos pos) offset) ;size]
                                 [;(v/v- (scale-pos (go :pos)) (go :offset))
                                  ;(go :size)])]
      (if (= go steve)
        (do
          (put steve :has-cross true)
          (put self :remove true))

        (do
          (:damage go self))))))

(defn render-cross
  [self]
  (draw-sprite (scale-pos (self :pos))
               :cross
               (mod
                 (* 600
                    (get self :cooldown 0))
                 360)
               [1 1 1 1]))

(defn new-cross
  [pos dir]
  @{:pos (v/v+ pos (v/v* dir 10))
    :attack-cooldown 0.25
    :cooldown 2
    :hp 3
    :dir dir
    :dmg 3
    :offset [4 4]
    :size [8 8]
    :speed 80
    :update |(update-cross $)
    :render |(render-cross $)})
