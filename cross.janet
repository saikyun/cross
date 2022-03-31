(import ./state :prefix "" :fresh true)
(use freja/flow)
(use ./steve)
(use ./skel)
(use ./render)
(import freja-jaylib :as fj)

#
#
##
# initialization

(defn init
  []
  (set death-timer 0)
  (array/clear gos)
  (set tiles (load-texture "tiles.png"))

  (set steve (new-steve [32 32]))
  (array/push gos steve)

  (array/push gos (new-skel [64 64])))

###
#
#
#

(defn render-ui
  []
  (def {:max-hp max-hp
        :last-hp last-hp
        :invul invul} steve)
  (defer (rl-pop-matrix)
    (rl-push-matrix)
    (rl-translatef 4 4 0)
    (rl-translatef -1 -1 0)
    (draw-rectangle 0 0 (+ max-hp 2) 7 :white)
    (rl-translatef 1 1 0)
    (draw-rectangle 0 0 max-hp 5 :black)
    (draw-rectangle 0 0
                    (math/round
                      (if invul
                        (lerp 0
                              max-hp
                              (/ (lerp (steve :hp)
                                       (steve :last-hp)
                                       (clamp (steve :invul)))
                                 (steve :max-hp)))
                        (lerp 0
                              max-hp
                              (/ (steve :hp)
                                 (steve :max-hp)))))
                    5 :white)))

(var render-offset @[0 0])

(defn render
  [el]
  (def {:width rw
        :height rh} el)
  (def rs [rw rh])

  (set render-offset
       (->> (-> (v/v* rs 0.5)
                (v/v- (v/v* game-size (* 0.5 scaling))))
            (map math/floor)))

  (try
    (do

      (when (steve :dead)
        (+= death-timer (get-frame-time)))

      (if (> death-timer 5)
        (do
          (draw-rectangle 0 0 2000 2000 :black)
          (fj/draw-text "You died. Press R." 10 10 12 :white))

        (defer (rl-pop-matrix)
          (rl-push-matrix)

          (draw-rectangle 0 0 ;game-size :black)

          (def nof-living (length (filter |(not ($ :dead)) gos)))
          (when (and (< nof-living (+ 15 (max 0 (* 2 (- (length gos) 15)))))
                     (> (- (+ 0.01 (* 0.001 (length gos)))
                           (* 0.001 nof-living))
                        (math/random)))

            (var pos [(* (game-size 0) (math/random))
                      (* (game-size 1) (math/random))])
            (while (< (v/dist pos (steve :pos)) 40)
              (set pos [(* (game-size 0) (math/random))
                        (* (game-size 1) (math/random))]))

            (array/push gos (new-skel pos)))

          (loop [go :in gos]
            (:update go)
            (unless (go :dead)
              (update go :pos
                      (fn [p]
                        (def [x y] p)
                        (if (tuple? p)
                          [(max 0 (min (game-size 0) x))
                           (max 0 (min (game-size 1) y))]
                          (do (put p 0 (max 0 (min (game-size 0) x)))
                            (put p 1 (max 0 (min (game-size 1) y)))))))))

          (var i 0)
          (while (< i (length gos))
            (if ((gos i) :remove)
              (array/remove gos i)
              (++ i)))

          (loop [go :in gos]
            (:render go))

          (render-ui)

          (when (steve :dead)
            (draw-rectangle 0 0 ;game-size [0 0 0 (clamp (/ death-timer 5))])))))
    ([err fib]
      (debug/stacktrace fib err ""))))

(def key-down
  {:w [[:in 1] dec]
   :a [[:in 0] dec]
   :s [[:in 1] inc]
   :d [[:in 0] inc]})

(def key-up
  {:w [[:in 1] inc]
   :a [[:in 0] inc]
   :s [[:in 1] dec]
   :d [[:in 0] dec]})

(defn on-event
  [el ev]
  (match ev
    {:mouse/down p}
    (:throw steve
            (-> (v/v- p (steve :pos))
                v/normalize))

    ({:key/down k} (key-down k))
    (update-in steve ;(key-down k))

    ({:key/release k} (key-up k))
    (update-in steve ;(key-up k))))

(when (dyn :freja/loading-file)
  (start-game {:render render
               :on-event on-event
               :size game-size
               :scale scaling
               :border :gray})

  (init))

(def ks [:1 :2 :w :s :a :d])

(defn main
  [& _]
  (print "main????")

  (init-window ;(v/v* game-size scaling) "Cross")

  '(toggle-fullscreen)

  (init)

  (set-target-fps 60)

  (var last-mp nil)

  (with-dyns [:offset-x 0 :offset-y 0]
    (while (not (window-should-close))
      (when (key-down? :r)
        (init))

      (begin-drawing)

      (defer (rl-pop-matrix)
        (rl-push-matrix)
        (rl-scalef scaling scaling 1)

        (clear-background :white)

        (def el {:width (get-screen-width)
                 :height (get-screen-height)
                 :render-x 0
                 :render-y 0
                 :focused? true})

        (let [new-mp (get-mouse-position)]
          (unless (= new-mp last-mp)
            (set last-mp new-mp)
            (on-event el {:mouse/move new-mp})))

        (loop [k :in ks]
          (when (key-pressed? k) (on-event el {:key/down k}))
          (when (key-released? k) (on-event el {:key/release k})))

        (loop [mb :in [0]]
          (when (mouse-button-pressed? mb)
            (on-event el {:mouse/down (v/v* last-mp (/ 1 scaling))})))

        (render el))
      (end-drawing)))

  (close-window))
