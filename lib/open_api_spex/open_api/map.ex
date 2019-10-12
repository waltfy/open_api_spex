defmodule OpenApiSpex.OpenApi.Map do
  @moduledoc """
  This module exposes functionality to convert an arbitrary map into a OpenApi struct.
  """
  alias OpenApiSpex.{
    Components,
    Contact,
    Discriminator,
    Encoding,
    Example,
    ExternalDocumentation,
    Header,
    Info,
    License,
    Link,
    MediaType,
    OAuthFlow,
    OAuthFlows,
    OpenApi,
    Operation,
    Parameter,
    PathItem,
    Reference,
    RequestBody,
    Response,
    Schema,
    SecurityScheme,
    Server,
    ServerVariable,
    Tag,
    Xml
  }

  def decode(%{openapi: _openapi, info: _info, paths: _paths} = map) do
    map
    |> to_struct(OpenApi)
    |> to_struct(:info, Info)
    |> to_struct(:paths, PathItems)
    |> to_struct(:servers, Servers)
    |> to_struct(:components, Components)
    |> to_struct(:tags, Tag)
    |> to_struct(:externalDocs, ExternalDocumentation)
  end

  defp embedded_ref_or_struct(list, mod) when is_list(list) do
    list
    |> Enum.map(fn
      %{"$ref": _} = v -> struct(Reference, v)
      v -> to_struct(v, mod)
    end)
  end

  defp embedded_ref_or_struct(map, mod) when is_map(map) do
    map
    |> Map.new(fn
      {k, %{"$ref": _} = v} ->
        {k, struct(Reference, v)}

      {k, v} ->
        {k, to_struct(v, mod)}
    end)
  end

  defp convert_value_to_atom_if_present(map, key) do
    if Map.has_key?(map, key) do
      Map.update!(map, key, fn
        nil ->
          nil

        v ->
          String.to_atom(v)
      end)
    else
      map
    end
  end

  defp prepare_schema(map) do
    map
    |> convert_value_to_atom_if_present(:type)
    |> to_list_of_atoms(:required)
  end

  defp to_list_of_atoms(map, key) do
    if Map.has_key?(map, key) do
      Map.update!(map, key, fn
        nil ->
          nil

        v ->
          v
          |> Enum.map(&String.to_atom/1)
      end)
    else
      map
    end
  end

  defp to_struct(nil, _mod), do: nil

  defp to_struct(tag, Tag) when is_binary(tag), do: tag

  defp to_struct(map, Tag) when is_map(map) do
    Tag
    |> struct(map)
    |> to_struct(:externalDocs, ExternalDocumentation)
  end

  defp to_struct(list, Tag) when is_list(list) do
    list
    |> Enum.map(&to_struct(&1, Tag))
  end

  defp to_struct(map, Components) do
    # NOTE: need to conver all keys to strings at a lower level
    map =
      Map.new(map, fn
        {k, v} -> {k, v |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)}
      end)

    Components
    |> struct(map)
    |> to_struct(:schemas, Schemas)
    |> to_struct(:responses, Responses)
    |> to_struct(:parameters, Parameters)
    |> to_struct(:examples, Examples)
    |> to_struct(:requestBodies, RequestBodies)
    |> to_struct(:headers, Headers)
    |> to_struct(:securitySchemes, SecuritySchemes)
    |> to_struct(:links, Links)
    |> to_struct(:callbacks, Callbacks)
  end

  defp to_struct(map, Link) do
    Link
    |> struct(map)
    |> to_struct(:server, Server)
    |> to_struct(:requestBody, RequestBody)
    |> to_struct(:parameters, Parameters)
  end

  defp to_struct(map, Links), do: embedded_ref_or_struct(map, Link)

  defp to_struct(map, SecurityScheme) do
    SecurityScheme
    |> struct(map)
    |> to_struct(:flows, OAuthFlows)
  end

  defp to_struct(map, SecuritySchemes), do: embedded_ref_or_struct(map, SecurityScheme)

  defp to_struct(map, OAuthFlow) do
    struct(OAuthFlow, map)
  end

  defp to_struct(map, OAuthFlows) do
    OAuthFlows
    |> struct(map)
    |> to_struct(:implicit, OAuthFlow)
    |> to_struct(:password, OAuthFlow)
    |> to_struct(:clientCredentials, OAuthFlow)
    |> to_struct(:authorizationCode, OAuthFlow)
  end

  defp to_struct(%{"$ref": _} = map, Schema), do: struct(Reference, map)

  defp to_struct(%{type: "number"} = map, Schema) do
    map
    |> prepare_schema()
    |> (&struct(Schema, &1)).()
    |> to_struct(:xml, Xml)
  end

  defp to_struct(%{type: "integer"} = map, Schema) do
    map
    |> prepare_schema()
    |> (&struct(Schema, &1)).()
    |> to_struct(:xml, Xml)
  end

  defp to_struct(%{type: "boolean"} = map, Schema) do
    map
    |> prepare_schema()
    |> (&struct(Schema, &1)).()
    |> to_struct(:xml, Xml)
  end

  defp to_struct(%{type: "string"} = map, Schema) do
    map
    |> prepare_schema()
    |> (&struct(Schema, &1)).()
    |> to_struct(:xml, Xml)
  end

  defp to_struct(%{type: "array"} = map, Schema) do
    map
    |> prepare_schema()
    |> (&struct(Schema, &1)).()
    |> to_struct(:items, Schema)
  end

  defp to_struct(%{type: "object"} = map, Schema) do
    map
    |> prepare_schema()
    |> (&struct(Schema, &1)).()
    |> to_struct(:properties, Schemas)
    |> to_struct(:externalDocs, ExternalDocumentation)
  end

  defp to_struct(%{anyOf: _valid_schemas} = map, Schema) do
    Schema
    |> struct(map)
    |> to_struct(:anyOf, Schemas)
    |> to_struct(:discriminator, Discriminator)
  end

  defp to_struct(%{oneOf: _valid_schemas} = map, Schema) do
    Schema
    |> struct(map)
    |> to_struct(:oneOf, Schemas)
    |> to_struct(:discriminator, Discriminator)
  end

  defp to_struct(%{allOf: _valid_schemas} = map, Schema) do
    Schema
    |> struct(map)
    |> to_struct(:allOf, Schemas)
    |> to_struct(:discriminator, Discriminator)
  end

  defp to_struct(%{not: _valid_schemas} = map, Schema) do
    Schema
    |> struct(map)
    |> to_struct(:not, Schemas)
  end

  defp to_struct(map_or_list, Schemas), do: embedded_ref_or_struct(map_or_list, Schema)

  defp to_struct(map, OAuthFlow) do
    struct(OAuthFlow, map)
  end

  defp to_struct(map, Callback) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, PathItem)}
    end)
  end

  defp to_struct(map_or_list, Callbacks), do: embedded_ref_or_struct(map_or_list, Callback)

  defp to_struct(map, Operation) do
    Operation
    |> struct(map)
    |> to_struct(:tags, Tag)
    |> to_struct(:externalDocs, ExternalDocumentation)
    |> to_struct(:responses, Responses)
    |> to_struct(:parameters, Parameters)
    |> to_struct(:requestBody, RequestBody)
    |> to_struct(:callbacks, Callbacks)
    |> to_struct(:servers, Server)
  end

  defp to_struct(map, RequestBody) do
    RequestBody
    |> struct(map)
    |> to_struct(:content, Content)
  end

  defp to_struct(map, RequestBodies), do: embedded_ref_or_struct(map, RequestBody)

  defp to_struct(map, Parameter) do
    map
    # TODO: Must we do the below?
    # |> convert_value_to_atom_if_present(:name)
    |> convert_value_to_atom_if_present(:in)
    |> convert_value_to_atom_if_present(:style)
    |> (fn x -> struct(Parameter, x) end).()
    |> to_struct(:examples, Examples)
    |> to_struct(:content, Content)
    |> to_struct(:schema, Schema)
  end

  defp to_struct(map_or_list, Parameters), do: embedded_ref_or_struct(map_or_list, Parameter)

  defp to_struct(map, ServerVariable) do
    struct(ServerVariable, map)
  end

  defp to_struct(map, ServerVariables) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, ServerVariable)}
    end)
  end

  defp to_struct(map, Server) do
    Server
    |> struct(map)
    |> to_struct(:variables, ServerVariables)
  end

  defp to_struct(list, Servers) when is_list(list) do
    Enum.map(list, &to_struct(&1, Server))
  end

  defp to_struct(map, Response) do
    Response
    |> struct(map)
    |> to_struct(:headers, Headers)
    |> to_struct(:content, Content)
    |> to_struct(:links, Links)
  end

  defp to_struct(map, Responses), do: embedded_ref_or_struct(map, Response)

  defp to_struct(map, MediaType) do
    MediaType
    |> struct(map)
    |> to_struct(:examples, Examples)
    |> to_struct(:encoding, Encoding)
    |> to_struct(:schema, Schema)
  end

  defp to_struct(map, Content) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, MediaType)}
    end)
  end

  defp to_struct(map, Encoding) do
    map
    |> Map.new(fn {k, v} ->
      {k,
       Encoding
       |> struct(v)
       |> convert_value_to_atom_if_present(:style)
       |> to_struct(:headers, Headers)}
    end)
  end

  defp to_struct(map, Example), do: struct(Example, map)
  defp to_struct(map_or_list, Examples), do: embedded_ref_or_struct(map_or_list, Example)

  defp to_struct(map, Header) do
    Header
    |> struct(map)
    |> to_struct(:schema, Schema)
  end

  defp to_struct(map, Headers), do: embedded_ref_or_struct(map, Header)

  defp to_struct(map, PathItem) do
    PathItem
    |> struct(map)
    |> to_struct(:delete, Operation)
    |> to_struct(:get, Operation)
    |> to_struct(:head, Operation)
    |> to_struct(:options, Operation)
    |> to_struct(:patch, Operation)
    |> to_struct(:post, Operation)
    |> to_struct(:put, Operation)
    |> to_struct(:trace, Operation)
    |> to_struct(:parameters, Parameters)
    |> to_struct(:servers, Servers)
  end

  defp to_struct(map, PathItems) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, PathItem)}
    end)
  end

  defp to_struct(map, Info) do
    Info
    |> struct(map)
    |> to_struct(:contact, Contact)
    |> to_struct(:license, License)
  end

  defp to_struct(list, mod) when is_list(list) and is_atom(mod),
    do: Enum.map(list, &to_struct(&1, mod))

  defp to_struct(map, module) when is_map(map) and is_atom(module),
    do: struct(module, map)

  # TODO: Document to_struct/3
  defp to_struct(map, key, mod) when is_map(map) and is_atom(key) and is_atom(mod) do
    Map.update!(map, key, fn v ->
      to_struct(v, mod)
    end)
  end
end
