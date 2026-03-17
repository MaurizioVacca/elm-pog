module Main exposing (run)

import BackendTask
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import Pages.Script as Script exposing (Script)


run : Script
run =
    Script.withCliOptions program
        (\_ ->
            Script.log "Hello"
        )


type CliOptions
    = Init


program : Program.Config CliOptions
program =
    Program.config
        |> Program.add
            (OptionsParser.buildSubCommand "init" Init
                |> OptionsParser.withDescription "Initialize Pog by creating all required files and wiring in your project"
            )
