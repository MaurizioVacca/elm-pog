module Pog exposing
    ( Config
    , bool
    , config
    , decodeInto
    , defaultPort
    , execute
    , float
    , int
    , query
    , string
    , viewDatabase
    , viewHost
    , viewPassword
    , viewPort
    , viewUser
    , withDatabase
    , withHost
    , withParams
    , withPassword
    , withPort
    , withUser
    )

{-| Allow to perform safely statically typed query.

    import Pog

    type alias Milkshake =
        { name : String
        }

    rows : List Milkshake
    rows =
        Pog.query "SELECT * FROM milkshakes WHERE name = $1"
            |> Pog.withParams (Pog.string "strawberrysome")
            |> Pog.decodeInto milkshakeDecoder
            |> Pog.execute

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode exposing (Decoder, fail)
import Json.Encode as Encode


type Value
    = IntVal Int
    | StringVal String
    | BoolVal Bool
    | FloatVal Float
    | NullVal


type Query a
    = Query
        { sql : String
        , params : List Value
        , rowDecoder : Decoder a
        , timeout : Int
        }


type Config
    = Config
        { user : String
        , password : Maybe String
        , host : String
        , port_ : Int
        , database : String
        }


defaultPort : Int
defaultPort =
    5432


defaultConfig : Config
defaultConfig =
    Config
        { user = "postgres"
        , password = Nothing
        , host = "localhost"
        , port_ = defaultPort
        , database = "postgres"
        }


config : Config
config =
    defaultConfig


viewUser : Config -> String
viewUser (Config c) =
    c.user


viewPassword : Config -> String
viewPassword (Config c) =
    case c.password of
        Just pwd ->
            pwd

        Nothing ->
            ""


viewHost : Config -> String
viewHost (Config c) =
    c.host


viewPort : Config -> String
viewPort (Config c) =
    String.fromInt c.port_


viewDatabase : Config -> String
viewDatabase (Config c) =
    c.database


withUser : String -> Config -> Config
withUser user (Config c) =
    Config { c | user = user }


withPassword : String -> Config -> Config
withPassword pwd (Config c) =
    Config { c | password = Just pwd }


withHost : String -> Config -> Config
withHost host (Config c) =
    Config { c | host = host }


withPort : Int -> Config -> Config
withPort port_ (Config c) =
    Config { c | port_ = port_ }


withDatabase : String -> Config -> Config
withDatabase database (Config c) =
    Config { c | database = database }


query : String -> Query a
query sql =
    Query
        { sql = sql
        , params = []
        , rowDecoder = fail "No decoder attached yet — pipe through Db.run"
        , timeout = 5000
        }


string : String -> Value
string val =
    StringVal val


int : Int -> Value
int val =
    IntVal val


float : Float -> Value
float val =
    FloatVal val


bool : Bool -> Value
bool val =
    BoolVal val


null : Value
null =
    NullVal


withParams : List Value -> Query a -> Query a
withParams params (Query q) =
    Query { q | params = params }


decodeInto : Decoder a -> Query a -> Query a
decodeInto decoder (Query q) =
    Query { q | rowDecoder = decoder }


encodeValue : Value -> Encode.Value
encodeValue val =
    case val of
        IntVal anInt ->
            Encode.int anInt

        StringVal aString ->
            Encode.string aString

        BoolVal aBool ->
            Encode.bool aBool

        FloatVal aFloat ->
            Encode.float aFloat

        NullVal ->
            Encode.null


execute : Query a -> BackendTask { fatal : FatalError, recoverable : BackendTask.Custom.Error } a
execute (Query q) =
    let
        preparedStatement =
            Encode.object [ ( "sql", Encode.string q.sql ), ( "params", Encode.list encodeValue q.params ) ]
    in
    BackendTask.Custom.run "executeQuery" preparedStatement q.rowDecoder
