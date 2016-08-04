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
