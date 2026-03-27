module Main exposing (run)

import Ansi.Color
import Ansi.Font
import BackendTask exposing (BackendTask)
import BackendTask.File as File
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import FatalError
import Json.Decode as JD
import Pages.Script as Script exposing (Script)
import Pog


run : Script
run =
    Script.withCliOptions program
        (\options ->
            case options of
                Init ->
                    init

                Heartbeat ->
                    heartbeat
        )


type CliOptions
    = Init
    | Heartbeat


program : Program.Config CliOptions
program =
    Program.config
        |> Program.add
            (OptionsParser.buildSubCommand "init" Init
                |> OptionsParser.withDescription "Initialize Pog by creating all required files and wiring in your project"
            )
        |> Program.add
            (OptionsParser.buildSubCommand "heartbeat" Heartbeat
                |> OptionsParser.withDescription "Check configured database connectivity"
            )


newConfig : Pog.Config
newConfig =
    Pog.config


questions : List ( String, String )
questions =
    [ ( "Database name", Pog.viewDatabase newConfig )
    , ( "Database host", Pog.viewHost newConfig )
    , ( "Database port", Pog.viewPort newConfig )
    , ( "Database user", Pog.viewUser newConfig )
    , ( "Database password", Pog.viewPassword newConfig )
    ]


{-| Creates a new squalo.json configuration.
-}
init : BackendTask FatalError.FatalError ()
init =
    Script.log
        (logo
            ++ "\n🦈 Welcome to Squalo, the command line interface for configuring elm-pog in your project."
            ++ "\nYou're about to initialize a new elm-pog client.\nThe created configuration can be changed at any time running "
            ++ Ansi.Font.bold "squalo update config, "
            ++ "or by manually editing the "
            ++ Ansi.Font.bold "squalo.json "
            ++ "file."
            ++ "\nInsert your values of choice, or just press "
            ++ Ansi.Font.bold "ENTER"
            ++ " for using the "
            ++ Ansi.Color.fontColor (Ansi.Color.rgb { red = 128, green = 128, blue = 128 }) "[default]"
        )
        |> Script.doThen (askInteractive questions newConfig)
        |> BackendTask.andThen
            (\config ->
                Script.log
                    ("\nProposed configuration:\n"
                        ++ "  - Database name: "
                        ++ Pog.viewDatabase config
                        ++ "\n"
                        ++ "  - Database host: "
                        ++ Pog.viewHost config
                        ++ "\n"
                        ++ "  - Database port: "
                        ++ Pog.viewPort config
                        ++ "\n"
                        ++ "  - Database user: "
                        ++ Pog.viewUser config
                        ++ "\n"
                        ++ "  - Database password: "
                        ++ Pog.viewPassword config
                    )
                    |> Script.doThen (Script.log "\nDoes it look ok? [Y/n]: ")
                    |> BackendTask.andThen (\_ -> Script.readKeyWithDefault "y")
                    |> BackendTask.andThen
                        (\confirm ->
                            if String.toLower confirm == "y" then
                                File.rawFile ".env"
                                    |> BackendTask.allowFatal
                                    |> BackendTask.andThen
                                        (\rawFile ->
                                            Script.writeFile { path = ".env", body = rawFile ++ toEnvVariables config }
                                                |> BackendTask.allowFatal
                                        )
                                    |> BackendTask.andThen (\_ -> Script.log "✨ Done.")

                            else
                                Script.log "🦈 No changes applied."
                        )
            )


logo : String
logo =
    Ansi.Color.fontColor Ansi.Color.cyan
        """
                                                  ·●●·.●.
           ···                                  ·●.   .●█
          ··..●                               ·█.   ...·█
           .·. ●.●                           ●● .......·█.
           .● ●          ····●███████●····. ●●·........·█.
            ··.   .·●█●·.                 .··●█●●●···...█·
               ·█●.       .......................··█●●···●
            .██.......................................●█●█
     ..██●●·.         ...................................·█·
   .█·................................···...................●●.
   █..  ............................●█  ·█....................●█.
   █             ...................████·●·........●...·........●█.                    ..
   █                       ...       ●●●●.       ..●...·..█.......●●               .███●█.
   ·●               .●●●                           ·   ·..█........·█           ·█●.●●●█·
   .█.               ·●              .●●           ●  ·. .●  ........█.       ●█..●·●●█.
    ·●                                 ●█·●.       .  ●  ·      ......●●    ·█.......█.
     ·███·....                   .●█●█●●·         ●  ·.  ·         ....·█. █·.....  █
       ·█·█..●█●████████████●...·●●█●●█.         ●   ·   ·           ....██......  ●·
        ●████●●●█·█●●●█.·█●●●●██●●█●●█          ●   ●   █              ...●█·..   ·█
        ●█.·●●●●●●●●●●●●●●█████●●●·●.         .·   ·   ●                 ..·●●.   ●.
         ●·●·.·█●●█·····●█····· .█.              ●.  ·●                    ..·●..·●
          ●● .●●█●   ●·●.  .·█●.                   ·●                       ..·█●█·
           ·█·    .........                                                    ●·█·
             ·●.                                 ..                           ●..●·
              ●██·                              .....·●●                    ●█....●●
            ·█.  .●█●                     .·     ......·●·               .●█●....  ●●
           ●●    ....·█●·..               .●·    .......●█.          ..●●●  .█●..   ·●
          ●●     ........·●█●·.......     ..●·     ....·●██........·●█·..●●   .·█●·..█·
         ··      ......·●█.  .··██●··........·●.    ...·●●●●.··●█●·█·.....·█.      .··
        .●      ...·●●·              ····●██●███·     ..·●·●●        ··██●··█
        ●·..···●█··                             .█·     .·●●█·
         ··.                                      .●●.    .●·█.
                                                     ·█·    .██.
                                                        ●●█·..·█.
                                                             .·.
"""


askInteractive : List ( String, String ) -> Pog.Config -> BackendTask e Pog.Config
askInteractive qs config =
    case qs of
        [] ->
            BackendTask.succeed config

        ( question, default ) :: rest ->
            Script.question
                (Ansi.Color.fontColor Ansi.Color.green "? "
                    ++ Ansi.Font.bold question
                    ++ Ansi.Color.fontColor (Ansi.Color.rgb { red = 128, green = 128, blue = 128 })
                        (" ["
                            ++ default
                            ++ "]: "
                        )
                )
                |> BackendTask.andThen
                    (\answer ->
                        let
                            value =
                                if answer == "" then
                                    default

                                else
                                    answer

                            updatedConfig =
                                case question of
                                    "Database name" ->
                                        Pog.withDatabase value config

                                    "Database host" ->
                                        Pog.withHost value config

                                    "Database port" ->
                                        Pog.withPort (String.toInt value |> Maybe.withDefault Pog.defaultPort) config

                                    "Database user" ->
                                        Pog.withUser value config

                                    "Database password" ->
                                        Pog.withPassword value config

                                    _ ->
                                        config
                        in
                        askInteractive rest updatedConfig
                    )


toEnvVariables : Pog.Config -> String
toEnvVariables config =
    """

# ==========================================
# Postgres
# ==========================================
"""
        ++ (Pog.viewHost config |> (++) "\nPGHOST=")
        ++ (Pog.viewDatabase config |> (++) "\nPGDATABASE=")
        ++ (Pog.viewUser config |> (++) "\nPGUSER=")
        ++ (Pog.viewPassword config |> (++) "\nPGPASSWORD=")
        ++ (Pog.viewPort config |> (++) "\nPGPORT=")


{-| Runs small diagnostic on configured database.
-}
heartbeat : BackendTask FatalError.FatalError ()
heartbeat =
    Script.log "🦈 Checking database connectivity..."
        |> BackendTask.andThen
            (\_ ->
                Pog.query "SELECT NOW()::text"
                    |> Pog.decodeInto heartbeatDecoder
                    |> Pog.execute
                    |> BackendTask.allowFatal
            )
        |> BackendTask.andThen
            (\list ->
                Script.log (List.head list |> Maybe.withDefault "" |> (++) "❤️ Last beat: ")
            )


heartbeatDecoder : JD.Decoder (List String)
heartbeatDecoder =
    JD.field "rows" (JD.list nowDecoder)


nowDecoder : JD.Decoder String
nowDecoder =
    JD.field "now" JD.string
