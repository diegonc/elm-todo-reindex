module GraphQL exposing (..)

{-| Todo: Write documentation for this module.

# Todo: Exports
@docs query, queryResult, apply
-}

import Task exposing (Task)
import Json.Decode exposing (..)
import Json.Encode
import Http


{-| Todo: document this
-}
type alias ID =
    String


{-| Todo: document this function.
-}
query : String -> String -> String -> String -> String -> Decoder a -> Task Http.Error a
query method url query operation variables decoder =
    fetch method url query operation variables decoder


{-| Todo: document this function.
-}
mutation : String -> String -> String -> String -> Decoder a -> Task Http.Error a
mutation url query operation variables decoder =
    fetch "POST" url query operation variables decoder


{-| Todo: document this function.
-}
fetch : String -> String -> String -> String -> String -> Decoder a -> Task Http.Error a
fetch verb url query operation variables decoder =
    let
        params =
            [ ( "query", query )
            , ( "operationName", operation )
            , ( "variables", variables )
            ]

        body =
            case verb of
                "GET" ->
                    Http.empty

                _ ->
                    params
                        |> List.map
                            (\p ->
                                case p of
                                    ( name, value ) ->
                                        ( name, Json.Encode.string value )
                            )
                        |> Json.Encode.object
                        |> Json.Encode.encode 0
                        |> Http.string

        url =
            case verb of
                "GET" ->
                    Http.url url params

                _ ->
                    Http.url url []

        payloadHeaders =
            case verb of
                "GET" ->
                    []

                _ ->
                    [ ( "Content-Type", "application/json" ) ]

        request =
            { verb = verb
            , headers =
                ( "Accept", "application/json" ) :: payloadHeaders
            , url = url
            , body = body
            }
    in
        Http.fromJson (queryResult decoder) (Http.send Http.defaultSettings request)


{-| Todo: document this function.
-}
queryResult : Decoder a -> Decoder a
queryResult decoder =
    -- todo: check for success/failure of the query
    oneOf
        [ at [ "data" ] decoder
        , fail "Expected 'data' field"
          -- todo: report failure reason from server
        ]


{-| Todo: document this function.
-}
apply : Decoder (a -> b) -> Decoder a -> Decoder b
apply func value =
    object2 (<|) func value


{-| Todo: document this function.
-}
maybeEncode : (a -> Value) -> Maybe a -> Value
maybeEncode e v =
    case v of
        Nothing ->
            Json.Encode.null

        Just a ->
            e a
