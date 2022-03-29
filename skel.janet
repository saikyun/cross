(use freja/flow)
(use ./state)
(use ./render)

(defn update-skel
  [self]
  (when (self :cooldown)
    (update self :cooldown - (get-frame-time))
    (when (neg? (self :cooldown))
      (put self :cooldown nil)))

  (when (self :invul)
    (update self :invul - (get-frame-time))
    (when (neg? (self :invul))
      (put self :invul nil)))

  (def cant-move
    (and (self :invul)
         (pos? (- (self :invul) (self :cant-move-time)))
         (- (self :invul) (self :cant-move-time))))

  (cond cant-move
    (when-let [dir (self :shove-dir)]
      (update self :pos v/v+
              (v/v* dir (* (self :shove-speed)
                           cant-move
                           (if (self :dead)
                             3
                             1)
                           (get-frame-time)))))

    (not (or (self :dead)
             (steve :dead)))
    (unless (self :cooldown)
      (def {:pos pos
            :speed speed} self)
      (def dir (-> (v/v- (steve :pos) pos)
                   v/normalize))
      (update self :pos v/v+ (v/v* dir
                                   (* speed (get-frame-time))))

      (let [{:pos pos :size size :offset offset} self]
        (when (check-collision-recs [;(v/v- (scale-pos pos) offset) ;size]
                                    [;(v/v- (scale-pos (steve :pos)) (steve :offset))
                                     ;(steve :size)])

          (:damage steve self)
          (put self :cooldown (self :attack-cooldown)))))))

(defn render-skel
  [self]
  (draw-sprite
    (scale-pos (self :pos))
    :skel-stand
    (if (self :dead)
      90
      0)
    (if-let [i (and (not (self :dead))
                    (self :invul))]
      [1 1 1 (mod (math/round (* 5 i)) 2)]

      [1 1 1

       (if-let [cd (self :cooldown)]
         (lerp 0.5 1 (- 1 (clamp (/ cd (self :attack-cooldown)))))
         1)])))

(defn damage-skel
  [self {:dmg dmg :pos enemy-pos}]
  (unless (self :invul)
    (put self :invul (self :invul-time))
    (put self :shove-speed (* 200 dmg))
    (put self :shove-dir (-> (v/v- (self :pos) enemy-pos) v/normalize))
    (update self :hp - dmg)
    (when (<= (self :hp) 0)
      (put self :dead true))))

(defn new-skel
  [pos]
  @{:pos pos
    :invul-time 0.6
    :cant-move-time 0.4
    :attack-cooldown 0.5
    :cooldown 0
    :hp 5
    :dmg 3
    :offset [5 4]
    :size [8 8]
    :speed 10
    :damage (fn [self enemy] (damage-skel self enemy))
    :update |(update-skel $)
    :render |(render-skel $)})
