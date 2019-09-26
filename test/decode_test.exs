defmodule OpenApiSpex.DecodeTest do
  use ExUnit.Case
  use Plug.Test

  alias OpenApiSpex.OpenApi

  test "Decode JSON" do
    json_spec = """
    {
        "components": {
            "schemas": {
                "User": {
                    "example": {
                        "first_name": "Jane",
                        "id": 42,
                        "last_name": "Doe",
                        "phone_number": null
                    },
                    "properties": {
                        "first_name": {
                            "type": "string"
                        },
                        "id": {
                            "type": "integer"
                        },
                        "last_name": {
                            "type": "string"
                        },
                        "phone_number": {
                            "nullable": true,
                            "type": "string"
                        }
                    },
                    "type": "object"
                }
            }
        },
        "info": {
            "title": "Duffel Technology Ltd.",
            "version": "1.0.0",
            "contact": {},
            "description": "Travel",
            "license": {}
        },
        "openapi": "3.0.0",
        "paths": {
            "/example": {
                "get": {
                    "callbacks": {},
                    "deprecated": false,
                    "parameters": [
                        {
                            "name": "myParam",
                            "in": "query",
                            "description": "My very own parameter",
                            "required": true,
                            "deprecated": false,
                            "allowEmptyValue": false,
                            "schema": {
                              "type": "string",
                              "maxLength": 10
                            }
                        }
                    ],
                    "requestBody": {
                        "content": {
                            "application/json": {
                                "schema": {
                                    "properties": {
                                        "first_name": {
                                            "type": "string",
                                            "maxLength": 10
                                        },
                                        "given_name": {
                                            "type": "string",
                                            "maxLength": 32
                                        },
                                        "phone_number": {
                                            "$ref": "#/components/schemas/User/properties/phone_number"
                                        }
                                    },
                                    "required": [
                                        "given_name"
                                    ],
                                    "type": "object"
                                },
                                "examples": {
                                    "user": {
                                        "summary": "User Example",
                                        "externalValue": "http://foo.bar/examples/user-example.json"
                                    }
                                }
                            }
                        }
                    },
                    "responses": {
                        "200": {
                            "content": {
                                "application/json": {
                                    "example": {
                                        "first_name": "John",
                                        "id": 678,
                                        "last_name": "Doe",
                                        "phone_number": null
                                    }
                                }
                            },
                            "description": "An example"
                        }
                    }
                }
            }
        },
        "security": [],
        "servers": [
            {
              "url": "https://development.gigantic-server.com/v1",
              "description": "Development server"
            }
        ],
        "tags": [
        ]
    }
    """

    spec =
      json_spec
      |> Jason.decode!(keys: :atoms)
      |> OpenApiSpex.import()

    # TODO: Remove comment
    # IO.inspect(spec, label: "spec")

    assert %OpenApi{
             components: components,
             extensions: extensions,
             externalDocs: externalDocs,
             info: info,
             openapi: openapi,
             paths: paths,
             security: security,
             servers: servers,
             tags: tags
           } = spec

    assert %OpenApiSpex.Info{
             title: "Duffel Technology Ltd.",
             version: "1.0.0",
             description: "Travel",
             contact: contact,
             license: license
           } = info

    assert %OpenApiSpex.Contact{} = contact
    assert %OpenApiSpex.License{} = license

    assert %{
             "/example": %OpenApiSpex.PathItem{
               get: %OpenApiSpex.Operation{
                 parameters: [
                   %OpenApiSpex.Parameter{}
                 ]
               }
             }
           } = paths

    my_conn =
      conn(:get, "/example?myParam=1", %{
        "first_name" => "Walter lak",
        "given_name" => "Carvalho",
        phone_number: "+447916844123"
      })
      |> put_req_header("content-type", "application/json")

    validation_result =
      OpenApiSpex.validate(
        spec,
        spec.paths."/example".get,
        my_conn,
        # NOTE: Why do we have to pass the content type here? As we're already passing the
        #       conn. What is Operation2?
        :"application/json"
      )

    # decoded =
    #   OpenApiSpex.resolve_schema_modules(spec)
    #   |> Jason.encode!(pretty: true)

    # IO.puts(decoded)

    # assert json_spec == decoded

    assert :ok = validation_result
  end
end
