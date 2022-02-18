# [Catalog of Elixir-specific code smells][Elixir Smells]

## Table of Contents

* __[About](#about)__
* __[Design-related smells](#design-related-smells)__
  * [GenServer Envy](#genserver-envy)
  * [Agent Obsession](#agent-obsession)
  * [Unsupervised process](#unsupervised-process)
  * [Large messages between processes](#large-messages-between-processes)
  * [Complex multi-clause function](#complex-multi-clause-function)
  * [Complex API error handling](#complex-api-error-handling)
  * [Exceptions for control-flow](#exceptions-for-control-flow)
  * [Untested polymorphic behavior](#untested-polymorphic-behavior)
  * [Code organization by process](#code-organization-by-process)
  * [Data manipulation by migration](#data-manipulation-by-migration)
* __[Low-level concerns smells](#low-level-concerns-smells)__
  * [Working with invalid data](#working-with-invalid-data)
  * [Map/struct dynamic access](#mapstruct-dynamic-access)
  * [Unplanned value extraction](#unplanned-value-extraction)
  * [Modules with identical names](#modules-with-identical-names)
  * [Unnecessary macro](#unnecessary-macro)
  * [App configuration for code libs](#app-configuration-for-code-libs)
  * [Compile-time app configuration](#compile-time-app-configuration)
  * [Dependency with "use" when an "import" is enough](#dependency-with-use-when-an-import-is-enough)

## About

This is the first catalog of code smells specific for the [Elixir programming language][Elixir]. Originally created by Lucas Vegi and Marco Tulio Valente ([ASERG/DCC/UFMG][ASERG]), this catalog consists of 18 Elixir-specific smells.

To better organize the kinds of impacts caused by these smells, we classify them into two different groups: __design-related smells__ <sup>[link](#design-related-smells)</sup> and __low-level concerns smells__ <sup>[link](#low-level-concerns-smells)</sup>.

Please feel free to make pull requests and suggestions.

## Design-related smells

Design-related smells are more complex, affect a coarse-grained code element, and are therefore harder to detect. Next, all 10 different smells classified as design-related are explained and exemplified:

### GenServer Envy

TODO...

[▲ back to Index](#table-of-contents)
___

### Agent Obsession

TODO...

[▲ back to Index](#table-of-contents)
___

### Unsupervised process

TODO...

[▲ back to Index](#table-of-contents)
___

### Large messages between processes

TODO...

[▲ back to Index](#table-of-contents)
___

### Complex multi-clause function

* __Problem:__ Using multi-clause functions in Elixir, to group functions of the same name, is not a code smell in itself. However, due to the great flexibility provided by this programming feature, some developers may abuse the number of guard clauses and pattern matchings in defining these grouped functions.

* __Example:__ A recurrent example of abusive use of the multi-clause functions is when we’re trying to mix too much business logic into the function definitions. This makes it difficult to read and understand the logic involved in the functions, which may impair code maintainability. Some developers use documentation mechanisms such as <code>@doc</code> annotations to compensate for poor code readability, but unfortunately, with a multi-clause function, we can only use these annotations once per function name, particularly on the first or header function. As shown next, all other variations of the function need to be documented only with comments, a mechanism that cannot automate tests, leaving the code bug-proneness.

  ```elixir
  @doc """
    Update sharp product with 0 or empty count
    
    ## Examples

      iex> Namespace.Module.update(...)
      {...expected result...}
  """
  def update(%Product{count: nil, material: material})
    when name in ["metal", "glass"] do
    # ...
  end

  # update blunt product
  def update(%Product{count: count, material: material})
    when count > 0 and material in ["metal", "glass"] do
    # ...
  end

  # update animal...
  def update(%Animal{count: 1, skin: skin})
    when skin in ["fur", "hairy"] do
    # ...
  end
  ```

  Source: [link][MultiClauseExample]

[▲ back to Index](#table-of-contents)
___

### Complex API error handling

* __Problem:__ When a function alone assumes the responsibility of handling multiple possibilities of different errors returned by the same API endpoint, this function can become confusing.

* __Example:__ An example of this code smell is when a function uses the <code>case</code> control-flow structure to handle these multiple variations of response types from an endpoint. This practice can make it long and low readable, as shown next.

  ```elixir
  def get_customer(customer_id) do
    case get("/customers/#{customer_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{body: body}} -> {:error, body}
      {:error, _} = other -> other
    end
  end
  ```

* __Refactoring:__ As shown below, in this situation, instead of using the <code>case</code> control-flow structure, it is better to delegate the response variations handling to a specific function (multi-clause), using pattern matching for each API response variation.

  ```elixir
  def get_customer(customer_id) when is_integer(customer_id) do
    "/customers/" <> customer_id
    |> get()
    |> handle_3rd_party_api_response()
  end

  defp handle_3rd_party_api_response({:ok, %Tesla.Env{status: 200, body: body}}) do 
    {:ok, body}
  end

  defp handle_3rd_party_api_response({:ok, %Tesla.Env{body: body}}) do
    {:error, body}
  end

  defp handle_3rd_party_api_response({:error, _} = other) do 
    other
  end
  ```

  Source: [link][ComplexErrorHandleExample]

[▲ back to Index](#table-of-contents)
___

### Exceptions for control-flow

TODO...

[▲ back to Index](#table-of-contents)
___

### Untested polymorphic behavior

TODO...

[▲ back to Index](#table-of-contents)
___

### Code organization by process

TODO...

[▲ back to Index](#table-of-contents)
___

### Data manipulation by migration

TODO...

[▲ back to Index](#table-of-contents)

## Low-level concerns smells

Low-level concerns smells are more simple than design-related smells and affect a small part of the code. Next, all 8 different smells classified as low-level concerns are explained and exemplified:

### Working with invalid data

TODO...

[▲ back to Index](#table-of-contents)
___

### Map/struct dynamic access

TODO...

[▲ back to Index](#table-of-contents)
___

### Unplanned value extraction

TODO...

[▲ back to Index](#table-of-contents)
___

### Modules with identical names

TODO...

[▲ back to Index](#table-of-contents)
___

### Unnecessary macro

TODO...

[▲ back to Index](#table-of-contents)
___

### App configuration for code libs

TODO...

[▲ back to Index](#table-of-contents)
___

### Compile-time app configuration

TODO...

[▲ back to Index](#table-of-contents)
___

### Dependency with "use" when an "import" is enough

TODO...

[▲ back to Index](#table-of-contents)

<!-- Links -->
[Elixir Smells]: https://github.com/lucasvegi/Elixir-Code-Smells
[Elixir]: http://elixir-lang.org
[ASERG]: http://aserg.labsoft.dcc.ufmg.br/
[MultiClauseExample]: https://syamilmj.com/2021-09-01-elixir-multi-clause-anti-pattern/
[ComplexErrorHandleExample]: https://elixirforum.com/t/what-are-sort-of-smells-do-you-tend-to-find-in-elixir-code/14971
