(use freja/flow)
(use ./state)

(defn draw-sprite
  [pos id rotation color]
  (draw-texture-pro
    tiles
    (sprites id)
    [;pos 16 16]
    [8 8]
    rotation
    color))

(defn clamp
  [v]
  (min 1 (max 0 v)))

(defn lerp
  [start stop t]
  (+ start (* t (- stop start))))

