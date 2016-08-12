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
        , markTodo
        , MarkTodoResult
        , deleteTodo
        , DeleteTodoResult
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


type OngoingRequestReason
    = Idle
    | InitialFetch
    | AppAction
    | ItemAction TodoItem


type alias Model =
    { todos : List TodoItem
    , error : Maybe Http.Error
    , filter : Filter
    , input : String
    , ongoingRequest : OngoingRequestReason
    , massToggleChecked : Maybe Bool
    }


initialFetch : Cmd Msg
initialFetch =
    Task.perform InitialFetchError InitialFetchResult allTodos


init : ( Model, Cmd Msg )
init =
    ( Model [] Nothing All "" InitialFetch Nothing, initialFetch )


filterTodos : Filter -> List TodoItem -> List TodoItem
filterTodos filter all =
    case filter of
        Active ->
            List.filter (\t -> not t.complete) all

        Completed ->
            List.filter (\t -> t.complete) all

        All ->
            all


markOneTodo : String -> Bool -> List TodoItem -> List TodoItem
markOneTodo id complete todos =
    let
        mark item =
            if item.id == id then
                { item | complete = complete }
            else
                item
    in
        List.map mark todos



-- Update


type Msg
    = InitialFetchResult AllTodosResult
    | InitialFetchError Http.Error
    | ChooseFilter Filter
    | Input String
    | RequestTodoCreation
    | OnTodoCreated AddTodoResult
    | OnTodoCreationFailure Http.Error
    | RequestToggle TodoItem
    | OnToggled MarkTodoResult
    | OnToggleFailure Http.Error
    | RequestToggleAll
    | OnToggledAll (List MarkTodoResult)
    | OnToggleAllFailure Http.Error
    | RequestClearCompleted
    | OnClearedCompleted (List DeleteTodoResult)
    | OnClearCompletedFailure Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitialFetchResult r ->
            let
                todos =
                    r.viewer.allTodos.nodes
            in
                ( { model
                    | error = Nothing
                    , todos = todos
                    , ongoingRequest = Idle
                    , massToggleChecked = Just <| List.all .complete todos
                  }
                , Cmd.none
                )

        InitialFetchError e ->
            ( { model
                | error = Just e
                , ongoingRequest = Idle
                , massToggleChecked = Nothing
              }
            , Cmd.none
            )

        ChooseFilter filter ->
            ( { model | filter = filter }, Cmd.none )

        Input text ->
            ( { model | input = text }, Cmd.none )

        RequestTodoCreation ->
            if model.ongoingRequest /= Idle || (String.isEmpty model.input) then
                ( model, Cmd.none )
            else
                ( { model | ongoingRequest = AppAction }
                , createTodoCmd model.input
                )

        OnTodoCreated r ->
            ( { model
                | ongoingRequest = Idle
                , error = Nothing
                , input = ""
                , todos = List.append model.todos [ r.createTodo.changedTodo ]
                , massToggleChecked = Just False
              }
            , Cmd.none
            )

        OnTodoCreationFailure err ->
            ( { model
                | ongoingRequest = Idle
                , error = Just err
              }
            , Cmd.none
            )

        RequestToggle item ->
            if model.ongoingRequest /= Idle then
                ( model, Cmd.none )
            else
                ( { model | ongoingRequest = ItemAction item }
                , createToggleCmd item
                )

        OnToggled result ->
            let
                { id, complete } =
                    result.updateTodo.changedTodo

                todos =
                    markOneTodo id complete model.todos
            in
                ( { model
                    | todos = todos
                    , ongoingRequest = Idle
                    , error = Nothing
                    , massToggleChecked = Just <| List.all .complete todos
                  }
                , Cmd.none
                )

        OnToggleFailure err ->
            ( { model
                | ongoingRequest = Idle
                , error = Just err
              }
            , Cmd.none
            )

        RequestToggleAll ->
            if model.ongoingRequest /= Idle then
                ( model, Cmd.none )
            else
                let
                    ( newMassToggleChecked, cmd ) =
                        createToggleAllCmd model.todos
                in
                    ( { model
                        | ongoingRequest = AppAction
                        , massToggleChecked = Just newMassToggleChecked
                      }
                    , cmd
                    )

        OnToggledAll rs ->
            ( { model
                | ongoingRequest = Idle
                , todos = applyToggleAllResults rs model.todos
              }
            , Cmd.none
            )

        OnToggleAllFailure err ->
            ( { model
                | ongoingRequest = Idle
                , error = Just err
              }
            , Cmd.none
            )

        RequestClearCompleted ->
            if model.ongoingRequest /= Idle then
                ( model, Cmd.none )
            else
                ( { model
                    | ongoingRequest = AppAction
                  }
                , createClearCompletedCmd model.todos
                )

        OnClearedCompleted rs ->
            ( { model
                | ongoingRequest = Idle
                , error = Nothing
                , todos = applyClearCompletedResults rs model.todos
              }
            , Cmd.none
            )

        OnClearCompletedFailure err ->
            ( { model
                | ongoingRequest = Idle
                , error = Just err
              }
            , Cmd.none
            )


applyToggleAllResults : List MarkTodoResult -> List TodoItem -> List TodoItem
applyToggleAllResults rs todos =
    let
        handleResult result todos =
            let
                item =
                    result.updateTodo.changedTodo
            in
                markOneTodo item.id item.complete todos
    in
        List.foldl handleResult todos rs


applyClearCompletedResults : List DeleteTodoResult -> List TodoItem -> List TodoItem
applyClearCompletedResults rs todos =
    let
        removed =
            List.map (.deleteTodo >> .changedTodo >> .id) rs
    in
        todos
            |> List.filter (.id >> (flip List.member) removed >> not)


createTodoCmd : String -> Cmd Msg
createTodoCmd text =
    { text = text }
        |> addTodo
        |> Task.perform OnTodoCreationFailure OnTodoCreated


createToggleCmd : TodoItem -> Cmd Msg
createToggleCmd item =
    { id = item.id, completed = not item.complete }
        |> markTodo
        |> Task.perform OnToggleFailure OnToggled


createToggleAllCmd : List TodoItem -> ( Bool, Cmd Msg )
createToggleAllCmd todos =
    let
        hasCompleted =
            List.any .complete todos

        hasActive =
            List.any (.complete >> not) todos

        newCompleted =
            hasActive
    in
        ( newCompleted
        , todos
            |> List.map (\item -> { id = item.id, completed = newCompleted })
            |> List.map markTodo
            |> Task.sequence
            |> Task.perform OnToggleAllFailure OnToggledAll
        )


createClearCompletedCmd : List TodoItem -> Cmd Msg
createClearCompletedCmd todos =
    todos
        |> List.filter .complete
        |> List.map (\item -> { id = item.id })
        |> List.map deleteTodo
        |> Task.sequence
        |> Task.perform OnClearCompletedFailure OnClearedCompleted



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
    let
        spinnerVisible =
            model.ongoingRequest
                == InitialFetch
                || model.ongoingRequest
                == AppAction
    in
        section [ class "input" ]
            [ Html.form
                [ onSubmit RequestTodoCreation ]
                [ input
                    [ type' "checkbox"
                    , classList [ ( "check", True ), ( "hidden", spinnerVisible ) ]
                    , checked <| Maybe.withDefault False model.massToggleChecked
                    , onCheck <| always RequestToggleAll
                    , disabled <| model.massToggleChecked == Nothing
                    ]
                    []
                , spinner [ ( "hidden", not spinnerVisible ) ]
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
            |> List.map (renderTodoItem model.ongoingRequest)
            |> ul []
        ]


renderTodoItem : OngoingRequestReason -> TodoItem -> Html Msg
renderTodoItem orr item =
    let
        spinnerVisible =
            case orr of
                ItemAction { id } ->
                    id == item.id

                _ ->
                    False
    in
        li
            [ classList [ ( "todo-item", True ), ( "completed", item.complete ) ] ]
            [ spinner [ ( "hidden", not spinnerVisible ) ]
            , input
                [ type' "checkbox"
                , classList [ ( "check", True ), ( "hidden", spinnerVisible ) ]
                , checked item.complete
                , onCheck <| \_ -> RequestToggle item
                ]
                []
            , label []
                [ text item.text ]
            ]


spinner : List ( String, Bool ) -> Html Msg
spinner extraClasses =
    i
        [ classList <|
            List.append
                [ ( "fa", True )
                , ( "fa-spinner", True )
                , ( "fa-spin", True )
                ]
                extraClasses
        ]
        []


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
        [ button
            [ type' "button"
            , onClick RequestClearCompleted
            ]
            [ text "Clear completed" ]
        ]



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
