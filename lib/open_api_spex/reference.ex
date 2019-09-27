defmodule OpenApiSpex.Reference do
  @moduledoc """
  Defines the `OpenApiSpex.Reference.t` type.
  """

  alias OpenApiSpex.Reference

  @enforce_keys :"$ref"
  defstruct [
    :"$ref"
  ]

  @typedoc """
  [Reference Object](https://swagger.io/specification/#referenceObject)

  A simple object to allow referencing other components in the specification, internally and externally.
  The Reference Object is defined by JSON Reference and follows the same structure, behavior and rules.
  """
  @type t :: %Reference{
          "$ref": String.t()
        }

  @doc """
  Resolve a `Reference` to the `Schema` it refers to.

  ## Examples

      iex> alias OpenApiSpex.{Reference, Schema}
      ...> schemas = %{"user" => %Schema{title: "user", type: :object}}
      ...> Reference.resolve_schema(%Reference{"$ref": "#/components/schemas/user"}, schemas)
      %OpenApiSpex.Schema{type: :object, title: "user"}
  """
  @spec resolve_schema(Reference.t(), %{String.t() => Schema.t()}) :: Schema.t() | nil
  def resolve_schema(%Reference{"$ref": "#/components/schemas/" <> name}, schemas) do
    name =
      name
      |> String.split("/")
      |> Enum.map(&String.to_atom/1)
      |> Enum.map(&Access.key/1)

    get_in(schemas, name)
  end

  @spec resolve_parameter(Reference.t(), %{String.t() => Parameter.t()}) :: Parameter.t() | nil
  def resolve_parameter(%Reference{"$ref": "#/components/parameters/" <> name}, parameters),
    do: parameters[name]
end
