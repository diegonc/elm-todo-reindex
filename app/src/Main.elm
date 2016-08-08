module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App
import Http
import String
import Task
import GraphQL.TodoMVC
    exposing
        ( allTodos
        , AllTodosResult
        , addTodo
        , AddTodoResult
        )


-- Model


type alias TodoItem =
    { id : String
    , text : String
    , complete : Bool
    }


type Filter
    = Active
    | Completed
    | All


type alias Model =
    { todos : List TodoItem
    , error : Maybe Http.Error
    , filter : Filter
    , input : String
    , ongoingRequest : Bool
    }


initialFetch : Cmd Msg
initialFetch =
    Task.perform InitialFetchError InitialFetchResult allTodos


init : ( Model, Cmd Msg )
init =
    ( Model [] Nothing All "" True, initialFetch )


filterTodos : Filter -> List TodoItem -> List TodoItem
filterTodos filter all =
    case filter of
        Active ->
            List.filter (\t -> not t.complete) all

        Completed ->
            List.filter (\t -> t.complete) all

        All ->
            all



-- Update


type Msg
    = InitialFetchResult AllTodosResult
    | InitialFetchError Http.Error
    | ChooseFilter Filter
    | Input String
    | RequestTodoCreation
    | OnTodoCreated AddTodoResult
    | OnTodoCreationFailure Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitialFetchResult r ->
            ( { model
                | error = Nothing
                , todos = r.viewer.allTodos.nodes
                , ongoingRequest = False
              }
            , Cmd.none
            )

        InitialFetchError e ->
            ( { model
                | error = Just e
                , ongoingRequest = False
              }
            , Cmd.none
            )

        ChooseFilter filter ->
            ( { model | filter = filter }, Cmd.none )

        Input text ->
            ( { model | input = text }, Cmd.none )

        RequestTodoCreation ->
            if model.ongoingRequest || (String.isEmpty model.input) then
                ( model, Cmd.none )
            else
                ( { model | ongoingRequest = True }
                , createTodoCmd model.input
                )

        OnTodoCreated r ->
            ( { model
                | ongoingRequest = False
                , error = Nothing
                , input = ""
                , todos = List.append model.todos [ r.createTodo.changedTodo ]
              }
            , Cmd.none
            )

        OnTodoCreationFailure err ->
            ( { model
                | ongoingRequest = False
                , error = Just err
              }
            , Cmd.none
            )


createTodoCmd : String -> Cmd Msg
createTodoCmd text =
    { text = text }
        |> addTodo
        |> Task.perform OnTodoCreationFailure OnTodoCreated



-- View


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ div [ class "app" ]
            [ renderHeader
            , renderInputSection model
            , renderTodoList model
            , renderFooter model
            ]
        , div [ class "debugging" ]
            [ pre [] [ text (toString model) ] ]
        ]


renderHeader : Html Msg
renderHeader =
    header []
        [ span [ class "header-text" ] [ text "todos" ] ]


renderInputSection : Model -> Html Msg
renderInputSection model =
    section [ class "input" ]
        [ Html.form
            [ onSubmit RequestTodoCreation ]
            [ input [ type' "checkbox", class "check" ] []
            , input
                [ type' "text"
                , class "text"
                , placeholder "What needs to be done?"
                , value model.input
                , onInput Input
                ]
                []
            ]
        ]


renderTodoList : Model -> Html Msg
renderTodoList model =
    section [ class "todo-list" ]
        [ model.todos
            |> filterTodos model.filter
            |> List.map renderTodoItem
            |> ul []
        ]


renderTodoItem : TodoItem -> Html Msg
renderTodoItem item =
    li [ classList [ ( "todo-item", True ), ( "completed", item.complete ) ] ]
        [ input [ type' "checkbox", class "check", checked item.complete ]
            []
        , label []
            [ text item.text ]
        ]


renderFooter : Model -> Html Msg
renderFooter model =
    let
        count =
            model.todos
                |> filterTodos Active
                |> List.length

        hasCompleted =
            model.todos
                |> List.filter (\t -> t.complete)
                |> List.isEmpty
                |> not
    in
        footer [ hidden (count == 0) ]
            [ renderFilters model.filter
            , renderTodoCount count
            , renderClearCompleted hasCompleted
            ]


renderTodoCount : Int -> Html Msg
renderTodoCount count =
    div [ class "todo-count" ]
        [ text <| (toString count) ++ " items left" ]


renderFilters : Filter -> Html Msg
renderFilters current =
    [ All, Active, Completed ]
        |> List.map (renderFilter current)
        |> ul [ class "todo-filters" ]


renderFilter : Filter -> Filter -> Html Msg
renderFilter active current =
    let
        makeList b =
            [ ( "active", b ) ]
    in
        li
            [ classList <| makeList <| active == current
            , onClick (ChooseFilter current)
            ]
            [ a [] [ text <| toString current ] ]


renderClearCompleted : Bool -> Html Msg
renderClearCompleted visible =
    div
        [ class "clear-completed"
        , hidden (not visible)
        ]
        [ button [ type' "button" ] [ text "Clear completed" ] ]



-- Subscriptions


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
