# OData REST Client in Elixir

This project provides a dynamic OData REST client in Elixir, driven by a Postman collection. The client automatically generates functions based on the requests defined in the Postman collection, making it easy to interact with OData services.

## What It Does

The OData client:

1. **Parses a Postman collection** to understand the available OData operations
2. **Dynamically generates functions** corresponding to each request in the collection
3. **Executes OData requests** with proper parameter handling and error management
4. **Adapts automatically** to changes in the Postman collection

This approach allows you to define your OData operations once in Postman (which has a user-friendly interface) and then use them programmatically in Elixir without having to manually code each endpoint.

## Features

- Dynamically generates functions based on a Postman collection
- Supports all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- Handles path parameters (e.g., `People('russellwhyte')`)
- Manages query parameters (e.g., `$filter`, `$select`, `$expand`)
- Supports request bodies for POST, PUT, and PATCH requests
- Can be extended with custom headers for authentication and concurrency control
- Agnostic to the specific OData service - just change the Postman collection to adapt to a different service
- Robust file path handling for both Livebook and standalone script usage

## Key Components

The client consists of several key components:

- **ODataClient Module**: The core module that handles parsing the collection and executing requests
- **Function Generation**: Converts Postman requests into callable Elixir functions
- **Parameter Extraction**: Identifies path and query parameters from request URLs
- **URL Preparation**: Handles parameter substitution and query string building
- **Request Execution**: Makes HTTP requests using the Req library

## Getting Started

### Prerequisites

- Elixir 1.13 or later
- Livebook 0.6 or later (for the Livebook interface)

### Usage

#### Using the Livebook Interface

1. Open the `odata_poc.livemd` file in Livebook
2. Make sure the Postman collection file (`postman_collection_sap_odata.json`) is in the same directory
3. Run the Livebook cells to initialize the client and start making requests

#### Using the Standalone Script

1. Run the script with `elixir odata_client_demo.exs`
2. Make sure the Postman collection file (`postman_collection_sap_odata.json`) is in the same directory

## How It Works

The OData client works by:

1. **Loading and parsing** the Postman collection JSON file
2. **Analyzing each request** in the collection to extract:
   - HTTP method (GET, POST, PUT, PATCH, DELETE)
   - URL structure and parameters
   - Request body schema (if any)
   - Query parameters
3. **Generating function metadata** for each request, including:
   - Function name (derived from the request name)
   - Required parameters
   - Default values
4. **Executing requests** by:
   - Finding the appropriate function metadata
   - Preparing the URL with parameters
   - Setting up the request body
   - Making the HTTP request
   - Returning the response

## Example Usage

```elixir
# Initialize the client with proper path handling
livebook_dir = __DIR__
collection_path = Path.join(livebook_dir, "postman_collection_sap_odata.json")
client = ODataClient.new(collection_path)

# List all available functions
ODataClient.list_functions(client)

# Execute a request
ODataClient.execute(client, :read_the_service_root)

# Execute a request with parameters
ODataClient.execute(client, :get_a_single_entity_from_an_entity_set, %{"russellwhyte" => "russellwhyte"})

# Execute a request with a filter
ODataClient.execute(client, :read_an_entity_set, %{"$filter" => "FirstName eq 'Scott'"})  # Using the entity set with a filter parameter

# Create a new entity
new_person = %{
  "UserName" => "johndoe",
  "FirstName" => "John",
  "LastName" => "Doe",
  "Gender" => "Male"
}
ODataClient.execute(client, :create_an_entity, %{}, new_person)
```

## Advanced Usage: Custom Headers and Authentication

```elixir
# Update with concurrency control
headers = [
  {"If-Match", "W/\"08D2931BACB7D7FD\""},
  {"Content-Type", "application/json"}
]

update_data = %{
  "Emails" => ["johndoe@contoso.com", "johndoe@example.com"]
}

ODataClientExtended.execute_with_headers(
  client,
  :update_an_entity,
  headers,
  %{"miathompson" => "johndoe"},
  update_data
)
```

## Customization

The client can be customized in several ways:

- Override the base URL by providing a `:base_url` option when initializing the client
- Extend the client with custom headers for authentication or concurrency control
- Modify the function name generation to match your preferred naming convention
- Add custom error handling or logging

## License

This project is licensed under the MIT License - see the LICENSE file for details.
