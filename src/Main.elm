module Main exposing (..)

import Browser
import Html exposing (Html, a, div, h1, h3, img, p, text)
import Html.Attributes exposing (href, id, src, target)
import Html.Events exposing (on)
import Http
import Json.Decode exposing (Decoder, Error(..), field, map4, maybe, string, succeed)
import Task
import Time exposing (Month(..), Weekday(..))



-- MAIN


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { time : TimeData
    , loadedPhoto : LoadedPhoto
    , clientId : String
    }


type alias TimeData =
    { zone : Time.Zone
    , time : Time.Posix
    }


type LoadedPhoto
    = Failure
    | Loading
    | Success Photo


type alias Photo =
    { url : String
    , photographerName : String
    , photographerPortfolio : String
    , location : Maybe String
    }


init : String -> ( Model, Cmd Msg )
init clientId =
    ( { time =
            { zone = Time.utc
            , time = Time.millisToPosix 0
            }
      , loadedPhoto = Loading
      , clientId = clientId
      }
    , adjustTimeZone
    )



-- UPDATE


type Msg
    = GotPhoto (Result Http.Error Photo)
    | AdjustTimeZone Time.Zone
    | Tick Time.Posix
    | ImageLoadFailed
    | ImageLoading


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPhoto result ->
            gotPhoto model result

        AdjustTimeZone newZone ->
            ( { model | time = TimeData newZone model.time.time }
            , getRandomPhoto model.clientId
            )

        Tick newTime ->
            ( { model | time = TimeData model.time.zone newTime }
            , Cmd.none
            )

        ImageLoadFailed ->
            ( { model | loadedPhoto = Failure }, Cmd.none )

        ImageLoading ->
            ( { model | loadedPhoto = Loading }, Cmd.none )


gotPhoto : Model -> Result error Photo -> ( Model, Cmd Msg )
gotPhoto model result =
    case result of
        Ok photo ->
            ( { model | loadedPhoto = Success photo }, Cmd.none )

        Err _ ->
            ( { model
                | loadedPhoto = Failure
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ viewImage model.loadedPhoto, viewTime model.time ]


viewImage : LoadedPhoto -> Html Msg
viewImage loadedPhoto =
    case loadedPhoto of
        Loading ->
            img [ src "./img/loading.jpg" ] []

        Failure ->
            img [ src "./img/error.jpg" ] []

        Success photo ->
            div []
                [ img [ src photo.url, on "error" (succeed ImageLoadFailed) ] []
                , div [ id "moreInfo" ]
                    [ a [ href photo.photographerPortfolio, target "_blank" ] [ text ("Photo by " ++ photo.photographerName) ]
                    , p [] [ text (Maybe.withDefault "" photo.location) ]
                    ]
                ]


viewTime : TimeData -> Html Msg
viewTime time =
    let
        hour =
            String.fromInt (Time.toHour time.zone time.time)

        minute =
            String.fromInt (Time.toMinute time.zone time.time)

        weekday =
            toEnglishWeekday (Time.toWeekday time.zone time.time)

        month =
            toEnglishMonth (Time.toMonth time.zone time.time)

        date =
            String.fromInt (Time.toDay time.zone time.time)
    in
    div [ id "timeDisplay" ]
        [ h1 [] [ text (hour ++ ":" ++ minute) ]
        , h3 [] [ text (weekday ++ ", " ++ month ++ " " ++ date) ]
        ]



-- HTTP


getRandomPhoto : String -> Cmd Msg
getRandomPhoto clientId =
    Http.get
        { url = "https://api.unsplash.com/photos/random?orientation=landscape&client_id=" ++ clientId
        , expect = Http.expectJson GotPhoto imageDataDecoder
        }


imageDataDecoder : Decoder Photo
imageDataDecoder =
    map4 Photo
        (field "urls" (field "raw" string))
        (field "user" (field "name" string))
        (field "user" (field "links" (field "html" string)))
        (field "location" (maybe (field "title" string)))



-- TIME


adjustTimeZone : Cmd Msg
adjustTimeZone =
    Task.perform AdjustTimeZone Time.here


toEnglishWeekday : Weekday -> String
toEnglishWeekday weekday =
    case weekday of
        Mon ->
            "Monday"

        Tue ->
            "Tuesday"

        Wed ->
            "Wednsday"

        Thu ->
            "Thursday"

        Fri ->
            "Friday"

        Sat ->
            "Saturday"

        Sun ->
            "Sunday"


toEnglishMonth : Month -> String
toEnglishMonth month =
    case month of
        Jan ->
            "January"

        Feb ->
            "Feburary"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"
