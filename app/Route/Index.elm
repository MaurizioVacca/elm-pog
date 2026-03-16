module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Json.Decode as JD
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Pog
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import UrlPath
import View exposing (View)


type alias Milkshake =
    { name : String
    }


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    { shakes : List Milkshake
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    BackendTask.map Data
        (Pog.query
            "SELECT * FROM milkshakes WHERE id=$1"
            |> Pog.withParams [ Pog.int 1 ]
            |> Pog.decodeInto milkshakesDecoder
            |> Pog.execute
        )
        |> BackendTask.allowFatal


milkshakesDecoder : JD.Decoder (List Milkshake)
milkshakesDecoder =
    JD.field "rows" (JD.list milkshakeDecoder)


milkshakeDecoder : JD.Decoder Milkshake
milkshakeDecoder =
    JD.map Milkshake (JD.field "name" JD.string)


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = [ "images", "icon-png.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Welcome to elm-pages!"
        , locale = Nothing
        , title = "elm-pages is running"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    { title = "elm-pages is running"
    , body =
        [ Html.h1 [] [ Html.text "ElmPog demo" ]
        , Html.div [] [ Html.text "Have a look on our milkshakes:", milkshakeOfTheDayView app.data.shakes ]
        ]
    }


milkshakeOfTheDayView : List Milkshake -> Html msg
milkshakeOfTheDayView shakes =
    Html.ul []
        (List.map
            (\shake -> Html.li [] [ Html.text shake.name ])
            shakes
        )
