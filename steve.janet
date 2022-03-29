(use freja/flow)
(use ./render)
(use ./state)
(use ./cross-thing)

(defn damage-steve
  [self {:dmg dmg :pos enemy-pos}]
  (put self :last-hp (self :hp))
  (update self :hp - dmg)
  (put self :invul (self :invul-time))
  (put self :shove-speed (* 200 dmg))
  (put self :shove-dir (-> (v/v- (self :pos) enemy-pos) v/normalize)))

(defn update-steve
  [self]
  (when (<= (self :hp) 0)
    (put self :dead true))

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

    (not (self :dead))

    (let [{:in in
           :speed speed} self]
      (update self :pos v/v+
              (v/v* in (* speed (get-frame-time)))))))

(defn render-steve
  [self]
  (let [sprite (cond (self :dead)
                 :steve-dead

                 (not (self :has-cross))
                 :steve-attack

                 :steve-stand)]
    (draw-sprite (scale-pos (self :pos))
                 sprite 0
                 (if-let [i (and (not (self :dead))
                                 (self :invul))]
                   [1 1 1 (mod (math/round (* 5 i)) 2)]
                   :white))))

(defn steve-throw
  [self dir]
  (unless (or (not (self :has-cross))
              (self :dead)
              # cant move
              (and (self :invul)
                   (pos? (- (self :invul) (self :cant-move-time)))
                   (- (self :invul) (self :cant-move-time))))
    (put self :has-cross false)
    (array/push gos (new-cross @[;(self :pos)]
                               dir))))

(defn new-steve
  [pos]
  @{:pos pos
    :invul-time 0.6
    :cant-move-time 0.4
    :hp 10
    :max-hp 10
    :offset [2 2]
    :has-cross true
    :size [6 8]
    :in @[0 0]
    :speed 30
    :throw |(steve-throw $ $1)
    :damage (fn [self enemy] (damage-steve self enemy))
    :render |(render-steve $)
    :update |(update-steve $)})
