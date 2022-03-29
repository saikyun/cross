(declare-project
  :name "Cross"
  :author "Jona Ekenberg <saikyun@gmail.com>"
  :dependencies [## using my own fork due to additions to jaylib
                 "https://github.com/saikyun/freja-jaylib"

                 # for vector math
                 "https://github.com/saikyun/freja"])

(declare-executable
  :name "Cross"
  :entry "cross.janet")
