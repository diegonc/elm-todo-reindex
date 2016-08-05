{-
   This file is automatically generated by elm-graphql. Do not modify!
-}


module GraphQL.TodoMVC exposing (allTodos, AllTodosResult, ReindexGranteeType, ReindexOrder, ReindexTriggerType, ReindexLogEventType, ReindexLogLevel, ReindexProviderType)

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
            GraphQL.query "POST" endpointUrl graphQLQuery "allTodos" (encode 0 graphQLParams) allTodosResult


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
