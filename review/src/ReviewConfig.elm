module ReviewConfig exposing (config)

import NoDebug.Log
import NoExposingEverything
import NoPrematureLetComputation
import Review.Rule exposing (Rule)
import Simplify


config : List Rule
config =
    [ NoDebug.Log.rule
    , NoExposingEverything.rule
    , NoPrematureLetComputation.rule
    , Simplify.rule Simplify.defaults
    ]
