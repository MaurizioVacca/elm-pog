module Pog exposing
    ( connect
    , defaultConfig
    , withDatabaseName
    , withDatabasePort
    , withHost
    , withPassword
    , withPoolSize
    , withSSL
    , withUsername
    )


type alias Config =
    { poolName : String
    , host : String
    , databaseName : String
    , databasePort : Int
    , username : String
    , password : Maybe String
    , ssl : Bool
    , poolSize : Int
    }


type Connection
    = Connection


defaultPort : Int
defaultPort =
    5432


{-| Creates a new default PostgreSQL configuration for a given pool name.
-}
defaultConfig : String -> Config
defaultConfig poolName =
    Config
        -- pool name
        poolName
        -- host
        "127.0.0.1"
        -- name
        "postgres"
        -- port
        defaultPort
        -- username
        "postgres"
        -- password
        Nothing
        -- ssl
        False
        -- pool size
        10


{-| Updates host.
-}
withHost : Config -> String -> Config
withHost config host =
    { config | host = host }


{-| Updates configured database name.
-}
withDatabaseName : Config -> String -> Config
withDatabaseName config name =
    { config | databaseName = name }


{-| Updates configured database port.
-}
withDatabasePort : Config -> Int -> Config
withDatabasePort config databasePort =
    { config
        | databasePort = databasePort
    }


{-| Updates configured database username.
-}
withUsername : Config -> String -> Config
withUsername config username =
    { config | username = username }


{-| Updates configured database password.
-}
withPassword : Config -> String -> Config
withPassword config password =
    { config | password = Just password }


{-| Updates configured SSL preferences.
-}
withSSL : Config -> Bool -> Config
withSSL config ssl =
    { config | ssl = ssl }


{-| Updates configured pool side.
-}
withPoolSize : Config -> Int -> Config
withPoolSize config poolSize =
    { config | poolSize = poolSize }


{-| Connects to configured database.
-}
connect : Config -> Connection
connect config =
    Connection
