{-
   This file is automatically generated by elm-graphql. Do not modify!
-}


module GraphQL.TodoMVC exposing (allTodos, AllTodosResult, addTodo, AddTodoResult, markTodo, MarkTodoResult, deleteTodo, DeleteTodoResult, ReindexGranteeType, ReindexOrder, ReindexTriggerType, ReindexLogEventType, ReindexLogLevel, ReindexProviderType)

import Task exposing (Task)
import Json.Decode exposing (..)
import Json.Encode exposing (encode)
import Http
import GraphQL exposing (apply, maybeEncode, ID)


type ReindexProviderType
    = Auth0
    | Facebook
    | Github
    | Google
    | Twitter


type ReindexLogLevel
    = None
    | All
    | Error


type ReindexLogEventType
    = Error'
    | Success


type ReindexTriggerType
    = AfterCreate
    | AfterUpdate
    | AfterDelete


type ReindexOrder
    = ASC
    | DESC


type ReindexGranteeType
    = USER
    | AUTHENTICATED
    | EVERYONE


endpointUrl : String
endpointUrl =
    "https://rare-neon-623.myreindex.com/graphql"


type alias AllTodosResult =
    { viewer :
        { allTodos :
            { nodes :
                List
                    { id : String
                    , text : String
                    , complete : Bool
                    }
            }
        }
    }


allTodos : Task Http.Error AllTodosResult
allTodos =
    let
        graphQLQuery =
            """query allTodos { viewer { allTodos { nodes { id text complete } } } }"""
    in
        let
            graphQLParams =
                Json.Encode.object
                    []
        in
            GraphQL.query "POST" endpointUrl graphQLQuery "allTodos" graphQLParams allTodosResult


allTodosResult : Decoder AllTodosResult
allTodosResult =
    map AllTodosResult
        ("viewer"
            := (map (\allTodos -> { allTodos = allTodos })
                    ("allTodos"
                        := (map (\nodes -> { nodes = nodes })
                                ("nodes"
                                    := (list
                                            (map (\id text complete -> { id = id, text = text, complete = complete }) ("id" := string)
                                                `apply` ("text" := string)
                                                `apply` ("complete" := bool)
                                            )
                                       )
                                )
                           )
                    )
               )
        )


type alias AddTodoResult =
    { createTodo :
        { changedTodo :
            { id : String
            , text : String
            , complete : Bool
            }
        }
    }


addTodo :
    { text : String
    }
    -> Task Http.Error AddTodoResult
addTodo params =
    let
        graphQLQuery =
            """mutation AddTodo($text: String!) { createTodo(input: {text: $text, complete: false}) { changedTodo { id text complete } } }"""
    in
        let
            graphQLParams =
                Json.Encode.object
                    [ ( "text", Json.Encode.string params.text )
                    ]
        in
            GraphQL.mutation endpointUrl graphQLQuery "AddTodo" graphQLParams addTodoResult


addTodoResult : Decoder AddTodoResult
addTodoResult =
    map AddTodoResult
        ("createTodo"
            := (map (\changedTodo -> { changedTodo = changedTodo })
                    ("changedTodo"
                        := (map (\id text complete -> { id = id, text = text, complete = complete }) ("id" := string)
                                `apply` ("text" := string)
                                `apply` ("complete" := bool)
                           )
                    )
               )
        )


type alias MarkTodoResult =
    { updateTodo :
        { changedTodo :
            { id : String
            , text : String
            , complete : Bool
            }
        }
    }


markTodo :
    { id : String
    , completed : Bool
    }
    -> Task Http.Error MarkTodoResult
markTodo params =
    let
        graphQLQuery =
            """mutation MarkTodo($id: ID!, $completed: Boolean!) { updateTodo(input: {id: $id, complete: $completed}) { changedTodo { id text complete } } }"""
    in
        let
            graphQLParams =
                Json.Encode.object
                    [ ( "id", Json.Encode.string params.id )
                    , ( "completed", Json.Encode.bool params.completed )
                    ]
        in
            GraphQL.mutation endpointUrl graphQLQuery "MarkTodo" graphQLParams markTodoResult


markTodoResult : Decoder MarkTodoResult
markTodoResult =
    map MarkTodoResult
        ("updateTodo"
            := (map (\changedTodo -> { changedTodo = changedTodo })
                    ("changedTodo"
                        := (map (\id text complete -> { id = id, text = text, complete = complete }) ("id" := string)
                                `apply` ("text" := string)
                                `apply` ("complete" := bool)
                           )
                    )
               )
        )


type alias DeleteTodoResult =
    { deleteTodo :
        { changedTodo :
            { id : String
            }
        }
    }


deleteTodo :
    { id : String
    }
    -> Task Http.Error DeleteTodoResult
deleteTodo params =
    let
        graphQLQuery =
            """mutation DeleteTodo($id: ID!) { deleteTodo(input: {id: $id}) { changedTodo { id } } }"""
    in
        let
            graphQLParams =
                Json.Encode.object
                    [ ( "id", Json.Encode.string params.id )
                    ]
        in
            GraphQL.mutation endpointUrl graphQLQuery "DeleteTodo" graphQLParams deleteTodoResult


deleteTodoResult : Decoder DeleteTodoResult
deleteTodoResult =
    map DeleteTodoResult
        ("deleteTodo"
            := (map (\changedTodo -> { changedTodo = changedTodo })
                    ("changedTodo"
                        := (map (\id -> { id = id }) ("id" := string))
                    )
               )
        )


reindexgranteetype : Decoder ReindexGranteeType
reindexgranteetype =
    customDecoder string
        (\s ->
            case s of
                "USER" ->
                    Ok USER

                "AUTHENTICATED" ->
                    Ok AUTHENTICATED

                "EVERYONE" ->
                    Ok EVERYONE

                _ ->
                    Err "Unknown ReindexGranteeType"
        )


reindexorder : Decoder ReindexOrder
reindexorder =
    customDecoder string
        (\s ->
            case s of
                "ASC" ->
                    Ok ASC

                "DESC" ->
                    Ok DESC

                _ ->
                    Err "Unknown ReindexOrder"
        )


reindextriggertype : Decoder ReindexTriggerType
reindextriggertype =
    customDecoder string
        (\s ->
            case s of
                "afterCreate" ->
                    Ok AfterCreate

                "afterUpdate" ->
                    Ok AfterUpdate

                "afterDelete" ->
                    Ok AfterDelete

                _ ->
                    Err "Unknown ReindexTriggerType"
        )


reindexlogeventtype : Decoder ReindexLogEventType
reindexlogeventtype =
    customDecoder string
        (\s ->
            case s of
                "error" ->
                    Ok Error'

                "success" ->
                    Ok Success

                _ ->
                    Err "Unknown ReindexLogEventType"
        )


reindexloglevel : Decoder ReindexLogLevel
reindexloglevel =
    customDecoder string
        (\s ->
            case s of
                "none" ->
                    Ok None

                "all" ->
                    Ok All

                "error" ->
                    Ok Error

                _ ->
                    Err "Unknown ReindexLogLevel"
        )


reindexprovidertype : Decoder ReindexProviderType
reindexprovidertype =
    customDecoder string
        (\s ->
            case s of
                "auth0" ->
                    Ok Auth0

                "facebook" ->
                    Ok Facebook

                "github" ->
                    Ok Github

                "google" ->
                    Ok Google

                "twitter" ->
                    Ok Twitter

                _ ->
                    Err "Unknown ReindexProviderType"
        )
