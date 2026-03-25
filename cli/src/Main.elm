module Main exposing (run)

import BackendTask exposing (BackendTask)
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import FatalError
import Json.Encode as Encode
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
    Script.log """
    Creating a new Squalo configuration.
    Enter the new value, or press ENTER for using the default
    """
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
                                Script.writeFile { path = "squalo.json", body = Encode.encode 4 (encodeConfig config) }
                                    |> BackendTask.allowFatal
                                    |> BackendTask.andThen (\_ -> Script.log "Configuration completed.")

                            else
                                Script.log "Configuration canceled."
                        )
            )


askInteractive : List ( String, String ) -> Pog.Config -> BackendTask e Pog.Config
askInteractive qs config =
    case qs of
        [] ->
            BackendTask.succeed config

        ( question, default ) :: rest ->
            Script.question ("? " ++ question ++ " [" ++ default ++ "]: ")
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


encodeConfig : Pog.Config -> Encode.Value
encodeConfig config =
    Encode.object
        [ ( "user", Encode.string <| Pog.viewUser config )
        , ( "password", Encode.string <| Pog.viewPassword config )
        , ( "host", Encode.string <| Pog.viewHost config )
        , ( "port", Encode.string <| Pog.viewPort config )
        , ( "database", Encode.string <| Pog.viewDatabase config )
        ]


{-| Runs small diagnostic on configured database.
-}
heartbeat : BackendTask FatalError.FatalError ()
heartbeat =
    Script.log "Heartbeat"
