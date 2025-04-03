# OData REST Client in Elixir

This project provides a dynamic OData REST client in Elixir, driven by a Postman collection. The client automatically generates functions based on the requests defined in the Postman collection, making it easy to interact with OData services.

## Features

- Dynamically generates functions based on a Postman collection
- Supports all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- Handles path and query parameters
- Supports request bodies for POST, PUT, and PATCH requests
- Can be extended with custom headers for authentication and concurrency control
- Agnostic to the specific OData service - just change the Postman collection to adapt to a different service

## Getting Started

### Prerequisites

- Elixir 1.13 or later
- Livebook 0.6 or later

### Usage

1. Open the `odata_poc.livemd` file in Livebook
2. Make sure the Postman collection file (`postman_collection_sap_odata.json`) is in the same directory or update the path in the Livebook
3. Run the Livebook cells to initialize the client and start making requests

## How It Works

The OData client works by:

1. Loading and parsing the Postman collection JSON file
2. Analyzing each request in the collection to extract:
   - HTTP method (GET, POST, PUT, PATCH, DELETE)
   - URL and URL parameters
   - Request body (if any)
   - Query parameters
3. Generating function metadata for each request
4. Providing an interface to execute these requests with dynamic parameters

## Example Usage

```elixir
# Initialize the client
client = ODataClient.new("postman_collection_sap_odata.json")

# List all available functions
ODataClient.list_functions(client)

# Execute a request
ODataClient.execute(client, :read_the_service_root)

# Execute a request with parameters
ODataClient.execute(client, :get_a_single_entity_from_an_entity_set, %{"russellwhyte" => "johndoe"})

# Execute a request with a filter
ODataClient.execute(client, :filter_a_collection, %{"$filter" => "FirstName eq 'Vincent'"})

# Create a new entity
new_person = %{
  "UserName" => "johndoe",
  "FirstName" => "John",
  "LastName" => "Doe",
  "Gender" => "Male"
}
ODataClient.execute(client, :create_an_entity, %{}, new_person)
```

## Customization

The client can be customized in several ways:

- Override the base URL by providing a `:base_url` option when initializing the client
- Extend the client with custom headers for authentication or concurrency control
- Modify the function name generation to match your preferred naming convention

## License

This project is licensed under the MIT License - see the LICENSE file for details.
