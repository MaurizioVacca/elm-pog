module Main exposing (run)

import Ansi.Color
import Ansi.Font
import BackendTask exposing (BackendTask)
import BackendTask.File as File
import Cli.Extra
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


{-| Creates a new configuration.
-}
init : BackendTask FatalError.FatalError ()
init =
    Script.log
        (Cli.Extra.logo
            ++ (Cli.Extra.prependNewLine <| Cli.Extra.info "Welcome to Squalo, the command line interface for configuring elm-pog in your project.")
            ++ (Cli.Extra.prependNewLine <| "You're about to initialize a new elm-pog client.")
            ++ (Cli.Extra.prependNewLine <|
                    ("The created configuration can be changed at any time running " ++ Ansi.Font.bold "squalo update config, " ++ "or by manually editing the ")
                        ++ Ansi.Font.bold ".env "
                        ++ "file."
               )
            ++ (Cli.Extra.prependNewLine <|
                    "Insert your values of choice, or just press "
                        ++ Ansi.Font.bold "ENTER"
                        ++ " for using the "
                        ++ Ansi.Color.fontColor (Ansi.Color.rgb { red = 128, green = 128, blue = 128 }) "[default]"
               )
        )
        |> Script.doThen (askInteractive questions newConfig)
        |> BackendTask.andThen
            (\config ->
                Script.log
                    (("Proposed configuration:" |> Cli.Extra.prependNewLine |> Cli.Extra.appendNewLine)
                        ++ ("Database name: " ++ Pog.viewDatabase config |> Cli.Extra.succeed |> Cli.Extra.appendNewLine)
                        ++ ("Database host: " ++ Pog.viewHost config |> Cli.Extra.succeed |> Cli.Extra.appendNewLine)
                        ++ ("Database port: " ++ Pog.viewPort config |> Cli.Extra.succeed |> Cli.Extra.appendNewLine)
                        ++ ("Database user: " ++ Pog.viewUser config |> Cli.Extra.succeed |> Cli.Extra.appendNewLine)
                        ++ ("Database password: " ++ Pog.viewPassword config |> Cli.Extra.succeed)
                    )
                    |> Script.doThen (Script.log "Does it look ok? [Y/n]: ")
                    |> Script.doThen (Script.readKeyWithDefault "y")
                    |> BackendTask.andThen
                        (\confirm ->
                            if String.toLower confirm == "y" then
                                checkEnvFile
                                    |> BackendTask.andThen
                                        (\envFileExists ->
                                            let
                                                elmPogEnvVariables =
                                                    toEnvVariables config
                                            in
                                            if envFileExists then
                                                Script.log ("found existing .env file. Appending new content..." |> Cli.Extra.succeed |> Cli.Extra.appendNewLine)
                                                    |> BackendTask.andThen (\_ -> File.rawFile ".env")
                                                    |> BackendTask.allowFatal
                                                    |> BackendTask.andThen
                                                        (\rawFile ->
                                                            writeToEnvFile (Just rawFile) elmPogEnvVariables
                                                        )

                                            else
                                                Script.log ("missing .env file. Creating new one..." |> Cli.Extra.failed |> Cli.Extra.appendNewLine)
                                                    |> Script.doThen (writeToEnvFile Nothing elmPogEnvVariables)
                                        )
                                    |> Script.doThen (Script.log "✨ Done.")

                            else
                                Script.log ("No changes applied." |> Cli.Extra.info)
                        )
            )


checkEnvFile : BackendTask error Bool
checkEnvFile =
    Script.log ("Looking for " ++ Ansi.Font.bold ".env" |> Cli.Extra.info)
        |> BackendTask.andThen (\_ -> File.exists ".env")


writeToEnvFile : Maybe String -> String -> BackendTask FatalError.FatalError ()
writeToEnvFile exisingEnv pogEnv =
    Script.writeFile { path = ".env", body = pogEnv |> (++) (Maybe.withDefault "" exisingEnv) }
        |> BackendTask.allowFatal


askInteractive : List ( String, String ) -> Pog.Config -> BackendTask e Pog.Config
askInteractive qs config =
    case qs of
        [] ->
            BackendTask.succeed config

        ( question, default ) :: rest ->
            Script.question
                (Ansi.Color.fontColor Ansi.Color.yellow "? "
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


{-| Converts `Pog.Config` to a string that
can be written on `.env` file
-}
toEnvVariables : Pog.Config -> String
toEnvVariables config =
    (Cli.Extra.divider |> Cli.Extra.appendNewLine)
        ++ ("# Postgres" |> Cli.Extra.appendNewLine)
        ++ (Cli.Extra.divider |> Cli.Extra.appendNewLine)
        ++ (Pog.viewHost config |> (++) "PGHOST=" |> Cli.Extra.appendNewLine)
        ++ (Pog.viewDatabase config |> (++) "PGDATABASE=" |> Cli.Extra.appendNewLine)
        ++ (Pog.viewUser config |> (++) "PGUSER=" |> Cli.Extra.appendNewLine)
        ++ (Pog.viewPassword config |> (++) "PGPASSWORD=" |> Cli.Extra.appendNewLine)
        ++ (Pog.viewPort config |> (++) "PGPORT=" |> Cli.Extra.appendNewLine)


{-| Runs small diagnostic on configured database.
-}
heartbeat : BackendTask FatalError.FatalError ()
heartbeat =
    Script.log "🦈  Checking database connectivity..."
        |> BackendTask.andThen
            (\_ ->
                Pog.query "SELECT NOW()::text"
                    |> Pog.decodeInto heartbeatDecoder
                    |> Pog.execute
                    |> BackendTask.allowFatal
            )
        |> BackendTask.andThen
            (\list ->
                Script.log (List.head list |> Maybe.withDefault "" |> (++) "❤️  Last beat: ")
            )


heartbeatDecoder : JD.Decoder (List String)
heartbeatDecoder =
    JD.field "rows" (JD.list nowDecoder)


nowDecoder : JD.Decoder String
nowDecoder =
    JD.field "now" JD.string
