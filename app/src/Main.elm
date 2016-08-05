module Main exposing (..)

import Html
import Html.App as App
import Http
import Task
import GraphQL.TodoMVC exposing (allTodos, AllTodosResult)


type Msg
    = GotTodos AllTodosResult
    | GraphQLError Http.Error


type alias Model =
    { result : Maybe AllTodosResult
    , error : Maybe Http.Error
    }


init : ( Model, Cmd Msg )
init =
    ( { result = Nothing, error = Nothing }
    , Task.perform GraphQLError GotTodos allTodos
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTodos r ->
            ( { result = Just r
              , error = Nothing
              }
            , Cmd.none
            )

        GraphQLError e ->
            ( { result = Nothing
              , error = Just e
              }
            , Cmd.none
            )


view : Model -> Html.Html Msg
view model =
    Html.pre [] [ Html.text (toString model) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Never
main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
