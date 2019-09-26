defmodule OpenApiSpex.Decoding do
  @moduledoc """
  Provides the entry-points for defining schemas, validating and casting.
  """
  alias OpenApiSpex.{
    Callback,
    OAuthFlow,
    Components,
    Contact,
    Encoding,
    Example,
    ExternalDocumentation,
    Header,
    Info,
    License,
    Link,
    MediaType,
    OpenApi,
    Operation,
    Operation2,
    Parameter,
    PathItem,
    Reference,
    RequestBody,
    Response,
    Schema,
    SchemaException,
    SchemaResolver,
    SecurityScheme,
    Server,
    ServerVariable,
    Tag
  }

  @moduledoc """
  Defines the `OpenApiSpex.Decoding.t` type.
  """
  # alias OpenApiSpex.{Header, Reference, Parameter}

  # defstruct [
  #   :contentType,
  #   :headers,
  #   :style,
  #   :explode,
  #   :allowReserved
  # ]

  # @typedoc """
  # [Encoding Object](https://swagger.io/specification/#encodingObject)

  # A single encoding definition applied to a single schema property.
  # """
  # @type t :: %__MODULE__{
  #         contentType: String.t() | nil,
  #         headers: %{String.t() => Header.t() | Reference.t()} | nil,
  #         style: Parameter.style() | nil,
  #         explode: boolean | nil,
  #         allowReserved: boolean | nil
  #       }
  def decode(map) do
    map
    |> to_struct(OpenApi)
    |> to_struct(:info, Info)
    |> to_struct(:servers, Server)
    |> to_struct(:paths, PathItem)
    |> to_struct(:components, Components)
    |> to_struct(:security, SecurityRequirement)
    |> to_struct(:tags, Tag)
    |> to_struct(:externalDocs, ExternalDocumentation)
  end

  def to_struct(nil, _mod), do: nil

  def to_struct(map, Tag) when is_map(map) do
    Tag
    |> struct(map)
    |> to_struct(:externalDocs, ExternalDocumentation)
  end

  def to_struct(list, Tag) when is_list(list) do
    list
    |> Enum.map(fn tag ->
      to_struct(tag, Tag)
    end)
  end

  def to_struct(map, Components) do
    Components
    |> struct(map)
    |> to_struct(:schemas, Schemas)
    |> to_struct(:responses, Response)
    |> to_struct(:parameters, Parameter)
    |> to_struct(:examples, Example)
    |> to_struct(:requestBodies, RequestBodies)
    |> to_struct(:headers, Header)
    |> to_struct(:securitySchemes, SecurityScheme)
    |> to_struct(:links, Link)
    |> to_struct(:callbacks, Callback)
  end

  def to_struct(map, Schema) do
    Schema
    |> struct(map)
    |> Map.update!(:type, &String.to_atom/1)
  end

  def to_struct(map, InlineSchema) do
    to_struct(map, Schema)
    |> to_struct(:properties, Schemas)
    |> to_struct(:externalDocs, ExternalDocumentation)
  end

  def to_struct(map, Schemas) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        {k, to_struct(v, InlineSchema)}
    end)
  end

  def to_struct(map, OAuthFlow) do
    struct(OAuthFlow, map)
  end

  def to_struct(map, SecurityScheme) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        res =
          SecurityScheme
          |> struct(v)
          |> to_struct(:flows, OAuthFlow)

        {k, res}
    end)
  end

  def to_struct(map, Callback) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        res =
          v
          |> Map.new(fn {k, v} ->
            {k, to_struct(v, PathItem)}
          end)
          |> (fn m -> struct(Callback, m) end).()

        {k, res}
    end)
  end

  def to_struct(map, Operation) do
    Operation
    |> struct(map)
    |> to_struct(:tags, Tag)
    |> to_struct(:externalDocs, ExternalDocumentation)
    |> to_struct(:responses, Response)
    |> to_struct(:parameters, Parameter)
    |> to_struct(:requestBody, RequestBody)
    |> to_struct(:callbacks, Callback)
    |> to_struct(:security, SecurityRequirement)
    |> to_struct(:servers, Server)
  end

  def to_struct(map, RequestBodies) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        {k, to_struct(RequestBody, v)}
    end)
  end

  def to_struct(%{"$ref": _} = map, RequestBody) do
    Reference
    |> struct(map)
  end

  def to_struct(map, RequestBody) do
    RequestBody
    |> struct(map)
    |> to_struct(:content, MediaType)
  end

  def to_struct(list, Parameter) do
    list
    |> Enum.map(fn
      %{"$ref": _} = param ->
        struct(Reference, param)

      param ->
        struct(Parameter, param)
        |> to_struct(:examples, Example)
        |> to_struct(:content, MediaType)
        |> to_struct(:schema, Schema)
    end)
  end

  def to_struct(map, ServerVariable) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, ServerVariable)}
    end)
  end

  def to_struct(list, Server) do
    list
    |> Enum.map(fn s ->
      struct(Server, s)
      |> to_struct(:variables, ServerVariable)
    end)
  end

  def to_struct(list, SecurityRequirement) do
    Enum.map(list, &struct(SecurityRequirement, &1))
  end

  def to_struct(map, Response) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        res =
          Response
          |> struct(v)
          |> to_struct(:headers, Header)
          |> to_struct(:content, MediaType)

        {k, res}
    end)
  end

  def to_struct(map, MediaType) do
    map
    |> Map.new(fn {k, v} ->
      res =
        MediaType
        |> struct(v)
        |> to_struct(:examples, Example)
        |> to_struct(:encoding, Encoding)
        |> to_struct(:schema, InlineSchema)

      {k, res}
    end)
  end

  def to_struct(map, Encoding) do
    map
    |> Map.new(fn {k, v} ->
      res =
        Encoding
        |> struct(v)

      {k, res}
    end)
  end

  def to_struct(map, Example) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        res =
          Example
          |> struct(v)

        {k, res}
    end)
  end

  def to_struct(map, Header) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        res =
          Header
          |> struct(v)

        {k, res}
    end)
  end

  def to_struct(map, Link) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        {k, struct(Link, v)}
    end)
  end

  def to_struct(map, PathItem) do
    map
    |> Map.new(fn {k, v} ->
      res =
        PathItem
        |> struct(v)
        |> to_struct(:delete, Operation)
        |> to_struct(:get, Operation)
        |> to_struct(:head, Operation)
        |> to_struct(:options, Operation)
        |> to_struct(:patch, Operation)
        |> to_struct(:post, Operation)
        |> to_struct(:put, Operation)
        |> to_struct(:trace, Operation)
        |> to_struct(:parameters, Parameter)
        |> to_struct(:servers, Server)

      {k, res}
    end)
  end

  def to_struct(map, Info) do
    Info
    |> struct(map)
    |> to_struct(:contact, Contact)
    |> to_struct(:license, License)
  end

  def to_struct(list, mod) when is_list(list) and is_atom(mod),
    do: Enum.map(list, &to_struct(&1, mod))

  def to_struct(map, module) when is_map(map) and is_atom(module),
    do: struct(module, map)

  def to_struct(map, key, mod) when is_map(map) and is_atom(key) and is_atom(mod) do
    Map.update!(map, key, fn v ->
      to_struct(v, mod)
    end)
  end
end
