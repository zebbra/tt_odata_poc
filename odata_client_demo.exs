#!/usr/bin/env elixir

# This script demonstrates how to use the OData client in a standalone Elixir script
# To run: elixir odata_client_demo.exs

# Install dependencies if not already installed
Mix.install([
  {:jason, "~> 1.4"},
  {:req, "~> 0.3.0"}
])

defmodule ODataClient do
  @moduledoc """
  A dynamic OData client that generates functions based on a Postman collection.
  """

  # Define a struct to hold the client configuration
  defstruct [:collection, :base_url, :functions]

  @doc """
  Initialize a new OData client from a Postman collection file.
  """
  def new(file_path, options \\ []) do
    collection = load_collection(file_path)
    base_url = Keyword.get(options, :base_url)
    functions = generate_functions(collection)

    %__MODULE__{
      collection: collection,
      base_url: base_url,
      functions: functions
    }
  end

  @doc """
  Load and parse a Postman collection from a file.
  """
  def load_collection(file_path) do
    file_path
    |> File.read!()
    |> Jason.decode!()
  end

  @doc """
  Generate function metadata from the Postman collection.
  """
  def generate_functions(collection) do
    collection["item"]
    |> Enum.map(fn item ->
      function_name = generate_function_name(item["name"])
      method = get_method(item)
      url = get_url(item)
      params = extract_params(url, item)
      body = get_body(item)

      %{
        name: function_name,
        original_name: item["name"],
        method: method,
        url: url,
        params: params,
        body: body,
        description: item["request"]["description"]
      }
    end)
  end

  @doc """
  Generate a function name from a request name.
  """
  def generate_function_name(name) do
    name
    |> String.downcase()
    # Remove leading numbers and dots
    |> String.replace(~r/^\d+\.\s+/, "")
    # Replace non-alphanumeric with spaces
    |> String.replace(~r/[^a-z0-9\s]/u, " ")
    |> String.split()
    |> Enum.join("_")
    |> String.to_atom()
  end

  @doc """
  Get the HTTP method from a request item.
  """
  def get_method(item) do
    item["request"]["method"]
    |> String.downcase()
    |> String.to_atom()
  end

  @doc """
  Get the URL from a request item.
  """
  def get_url(item) do
    case item["request"]["url"] do
      url when is_binary(url) -> url
      url when is_map(url) -> url["raw"]
    end
  end

  @doc """
  Extract parameters from a URL and request.
  """
  def extract_params(url, item) do
    # Extract path parameters (e.g., People('russellwhyte'))
    path_params =
      Regex.scan(~r/'([^']+)'/, url)
      |> Enum.map(fn [_, param] -> param end)

    # Extract query parameters if available
    query_params =
      case item["request"]["url"] do
        url when is_map(url) ->
          # Check if "query" exists and is a list inside the clause body
          case url["query"] do
            query_list when is_list(query_list) ->
              query_list
              |> Enum.map(fn param -> param["key"] end)

            # Handle cases where "query" is missing or not a list
            _ ->
              []
          end

        # Handle cases where item["request"]["url"] is not a map
        _ ->
          []
      end

    # Combine all parameters
    path_params ++ query_params
  end

  @doc """
  Get the request body if available.
  """
  def get_body(item) do
    case get_in(item, ["request", "body", "raw"]) do
      nil ->
        nil

      raw_body ->
        try do
          Jason.decode!(raw_body)
        rescue
          _ -> raw_body
        end
    end
  end

  @doc """
  Execute a request using the specified function name and parameters.
  """
  def execute(client, function_name, params \\ %{}, body \\ nil) do
    function = Enum.find(client.functions, fn f -> f.name == function_name end)

    unless function do
      raise "Function #{function_name} not found in the OData client"
    end

    # Prepare the URL with parameters
    url = prepare_url(function.url, params)

    # Prepare the request body
    request_body = body || function.body

    # Execute the request
    case function.method do
      :get -> Req.get!(url)
      :post -> Req.post!(url, json: request_body)
      :put -> Req.put!(url, json: request_body)
      :patch -> Req.patch!(url, json: request_body)
      :delete -> Req.delete!(url)
    end
  end

  @doc """
  Prepare a URL by replacing parameters with their values.
  """
  def prepare_url(url, params) do
    # Replace path parameters
    url =
      Regex.replace(~r/'([^']+)'/, url, fn _, param ->
        case Map.get(params, String.to_atom(param)) || Map.get(params, param) do
          # Keep original if not provided
          nil -> "'#{param}'"
          value -> "'#{value}'"
        end
      end)

    # Add query parameters, but only if they don't already exist in the URL
    query_params =
      for {key, value} <- params,
          is_binary(key) && String.starts_with?(key, "$"),
          # Skip if the parameter already exists in the URL
          not String.contains?(url, "#{key}="),
          do: "#{key}=#{URI.encode_www_form(value)}"

    if Enum.empty?(query_params) do
      url
    else
      if String.contains?(url, "?") do
        "#{url}&#{Enum.join(query_params, "&")}"
      else
        "#{url}?#{Enum.join(query_params, "&")}"
      end
    end
  end

  @doc """
  List all available functions in the client.
  """
  def list_functions(client) do
    client.functions
    |> Enum.map(fn function ->
      %{
        name: function.name,
        original_name: function.original_name,
        method: function.method,
        url: function.url,
        params: function.params
      }
    end)
  end

  @doc """
  Get detailed information about a specific function.
  """
  def get_function_info(client, function_name) do
    Enum.find(client.functions, fn f -> f.name == function_name end)
  end
end

# Main demo code
IO.puts("OData Client Demo")
IO.puts("----------------")

# Get the directory of the current script
script_dir = Path.dirname(__ENV__.file)

# Construct the absolute path to the Postman collection
collection_path = Path.join(script_dir, "postman_collection_sap_odata.json")

# Check if the file exists before trying to load it
unless File.exists?(collection_path) do
  # Display an error if the file is not found
  IO.puts(
    :stderr,
    "Error: Could not find postman_collection_sap_odata.json at #{collection_path}"
  )

  System.halt(1)
end

# Initialize the client
client = ODataClient.new(collection_path)

# List all available functions
IO.puts("\nAvailable functions:")

client.functions
|> Enum.map(fn function -> "- #{function.name}" end)
|> Enum.each(&IO.puts/1)

# Execute a request
IO.puts("\nExecuting request: read_the_service_root")
response = ODataClient.execute(client, :read_the_service_root)
IO.puts("Status: #{response.status}")
IO.puts("Body preview:")
IO.inspect(response.body, pretty: true, limit: 2)

# Execute a request with parameters
IO.puts("\nExecuting request: get_a_single_entity_from_an_entity_set")

response =
  ODataClient.execute(client, :get_a_single_entity_from_an_entity_set, %{
    "russellwhyte" => "russellwhyte"
  })

IO.puts("Status: #{response.status}")
IO.puts("Body preview:")
IO.inspect(response.body, pretty: true, limit: 2)

# Execute a request with a filter
IO.puts("\nExecuting request: read_an_entity_set with filter")

response =
  ODataClient.execute(client, :read_an_entity_set, %{"$filter" => "FirstName eq 'Scott'"})

IO.puts("Status: #{response.status}")
IO.puts("Body preview:")
IO.inspect(response.body, pretty: true, limit: 2)

IO.puts("\nDemo completed successfully!")
