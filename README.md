# [Reindex.io](http://reindex.io) backed Todo application written in [Elm](http://elm-lang.org)

## 1. Fetching the schema

    $ reindex login <URL> <token>
    $ reindex schema-fetch reindex/ReindexSchema.json5

## 2. Creating the Elm project

    $ cd app
    $ elm package install

## 3. Adding the Todo object to the schema

The TodoMVC application consist of a list of tasks that
are either complete or incomplete and have a textual
description.

We add an object named `Todo` with `text` and `complete`
fields and, as we want to be able to update one Todo, an
`id` field too.

Also by declaring the `Node` interface Reindex will allow
us to fetch Todo objects through its `node` root field.

    {
      name: "Todo",
      kind: "OBJECT",
      interfaces: [
        "Node"
      ],
      fields: [
        {
          name: "id",
          type: "ID",
          nonNull: true,
          unique: true
        },
        {
          name: "text",
          type: "String",
          nonNull: true
        },
        {
          name: "complete",
          type: "Boolean",
          nonNull: true
        }
      ]
    }

After adding the object definition above to the schema file
we push it to Reindex.

    $ reindex schema-push reindex/ReindexSchema.json5

Reindex should have created `getTodo` and `todoById` fields
in the root query to find a Todo object given its id; and the
`viewer` field gains a subfield `allTodos` which allows us to
query for a paginated collection of all Todo objects. There
should also be new mutations `createTodo`, `updateTodo`,
`replaceTodo` and `deleteTodo`.

Thus, Todo objects can be listed using the query below:

    query allTodos {
      viewer {
        allTodos {
          nodes {
            id,
            text,
            complete
          }
        }
      }
    }

and a Todo object may be created with the following mutation:

    mutation AddTodo {
      createTodo(input: {text: "New Todo Item", complete: false}) {
        changedTodo {
          id
          text
          complete
        }
      }
    }

## 4. Setting up `elm-graphql`

> elm-graphql aims to generate Elm code for making GraphQL queries in a type-safe manner.

`elm-graphql` generates the Elm types corresponding to a
GraphQL schema obtained by instrospection of a live server.

    $ cd tools
    $ git clone https://github.com/jahewson/elm-graphql.git
    $ cd elm-graphql/tool
    $ npm install

> **Important Note**
>
>    While the repository used above is the one true source
>    of the `elm-graphql` package, I had to make some changes
>    for it to work with Reindex.
>
>    I hope those changes will eventually be merged by @jahewson
>    But in the meanwhile, you can use my fork located at:
>        https://github.com/diegonc/elm-graphql.git
>
>    Make sure you checkout the `t/add-option-for-http-method`
>    branch.

## 5. Writing the GraphQL queries we'll use

`elm-graphql` requires the queries our application
will use to be written before any Elm code is generated.

> **Note:**
>
>    The [How elm graphql works](https://github.com/jahewson/elm-graphql/wiki/How-elm-graphql-works) wiki page has
>    more details about why it is that way.

We will use the query shown previously in section `3` and
save it in `app/src/GraphQL/TodoMVC.graphql`.

## 6. Running `elm-graphql` code generator

With the tool installed, we now need to run it against
Reindex's GraphQL server and the queries file generated
in the previous section.

    $ cd app
    $ ../tools/elm-graphql/tool/bin/make src/GraphQL/TodoMVC.graphql <URL>/graphql --method=POST

> **Note:**
>
>        make is a bash script that calls node
>        When running on Windows just invoke it
>        by hand replacing the make command with
>
>        node ../tools/elm-graphql/tool/lib/query-to-elm.js

Now we have to patch the generated file `app/src/GraphQL/TodoMVC.elm`.
The schema extracted form Reindex URL contains two types that cause
some trouble to elm graphql code generator due to enums with the same
value.

Just add a quote at the end of the `Error` tag in `ReindexLogEventType`
and to its reference in `reindexlogeventtype`.

We also have to copy the `GraphQL.elm` file from our `tools/elm-graphql/src`
directory to `app/src` and install the `evancz/elm-http` package.

> **Note:**
>
>    The last couple of steps should not be necessary anymore
>    when the conflicting types problem is solved and the
>    package finally published.

## 7. Writing a quick test of the generated module

We are going to write a quick and dirty test for the module generated
in the previous step.

But first, launch graphiql and add some todo items using the mutation
showed in section *3*.

    $ reindex graphiql

Now that our backend has some data we can query it using the `allTodos`
task exposed by the `GraphQL.TodoMVC` module.

Check the `app/src/Main.elm` file for the implementation.

## 8. A barebones view

A lot of work has been done in the backend side of the project and
now there's enough infrastructure to make some progress on the frontend.

The UI is composed of the following components which will be
implemented by separate functions or variables.

    * View root
        * Header
        * Todo input
        * Todo item list
            * Todo item
        * Footer
            * Active item count
            * Filters
            * Clear completed

The model contains an array of todo items fetched from the server, an
optional error message received from the server, the filtering status
and the contents of the input field.

Finally, for the time being, the application can receive the following
messages:

* InitialFetchResult AllTodosResult : when the initial fetch completes
successfully.
* InitialFetchError Http.Error : when the initial fetch fails

We will not bother to poll the server for new items after the initial
fetch.

> **Note:**
>
>    A Gulp based build prcess is introduced in this section
>    which is based on what James Moore used in his
>    `Elm For Beginners` tutorial.
>
>    http://courses.knowthen.com/courses/elm-for-beginners/lectures/1254148

## 9. Implementing filtering behavior

The last thing we can progress with before diving into GraphQL mutations
is the filtering of the todo list.

Section 8 introduced the function `filterTodos` which will be very useful
for doing just that.

```elm
filterTodos : Filter -> List TodoItem -> List TodoItem
```

The filter selection buttons will generate a new message type with the
chosen filter selected, named `ChooseFilter`, while the todo list view
must use the currently selected filter to compute the shown items.

## 10. Implementing todos creation

Using the mutation shown in section `3` as a building block we are going
to implement the creation of new todo items. The queries file created in
section `5` needs to be updated with the new mutation which will have one
parameter for specifying the item's text.

```
mutation AddTodo($text: String!) {
  createTodo(input: {text: $text, complete: false}) {
    changedTodo {
      id
      text
      complete
    }
  }
}
```

The code generator then needs to be invoked again; remember to fix the
conflicting types this time too.

Four new messages will be created to implement this feature.

* Input String: to receive new texts entered by the user
* RequestTodoCreation: to initiate the GraphQL mutation
* OnTodoCreated AddTodoResult: to receive the result of the mutation
* OnTodoCreationFailure Http.Error: for handling server errors

Whenever a user presses the `Enter` key a `RequestTodoCreation` messages
is delivered, which initiates a roundtrip to the server, and the UI is
disabled until either the result or error comes back. To simplify things,
optimistic updates will not be performed.

## 11. Marking a todo as completed/active

A new mutation needs to be added to the queries file to allow the application
to toggle the completeness of a todo item. We'll use the `updateTodo` mutation
provided by Reindex.

```
mutation MarkTodo($id: ID!, $completed: Boolean!) {
  updateTodo(input: {id: $id, complete: $completed}) {
    changedTodo {
      id
      text
      complete
    }
  }
}
```

The code generator then needs to be invoked again; remember to fix the
conflicting types this time too.

Three new messages will be created to implement this feature.

* RequestToggle TodoItem: to initiate the GraphQL mutation
* OnToggled MarkTodoResult: to receive the result of the mutation
* OnToggleFailure Http.Error: for handling server errors

Whenever a user changes the state of the check boxes a
`RequestToggle` messages is delivered, which initiates a roundtrip to the
server, and the UI is disabled until either the result or error comes back.
