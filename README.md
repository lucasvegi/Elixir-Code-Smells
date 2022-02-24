# [Catalog of Elixir-specific code smells][Elixir Smells]

[![GitHub last commit](https://img.shields.io/github/last-commit/lucasvegi/Elixir-Code-Smells)](https://github.com/lucasvegi/Elixir-Code-Smells/commits/main)
[![Twitter URL](https://img.shields.io/twitter/url?style=social&url=https%3A%2F%2Fgithub.com%2Flucasvegi%2FElixir-Code-Smells)](https://twitter.com/intent/tweet?text=Catalog%20of%20Elixir-specific%20code%20smells:&url=https%3A%2F%2Fgithub.com%2Flucasvegi%2FElixir-Code-Smells)

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

* __Category:__ Design-related smell.

* __Problem:__ Using multi-clause functions in Elixir, to group functions of the same name, is not a code smell in itself. However, due to the great flexibility provided by this programming feature, some developers may abuse the number of guard clauses and pattern matchings in defining these grouped functions.

* __Example:__ A recurrent example of abusive use of the multi-clause functions is when we’re trying to mix too much business logic into the function definitions. This makes it difficult to read and understand the logic involved in the functions, which may impair code maintainability. Some developers use documentation mechanisms such as ``@doc`` annotations to compensate for poor code readability, but unfortunately, with a multi-clause function, we can only use these annotations once per function name, particularly on the first or header function. As shown next, all other variations of the function need to be documented only with comments, a mechanism that cannot automate tests, leaving the code bug-proneness.

  ```elixir
  @doc """
    Update sharp product with 0 or empty count
    
    ## Examples

      iex> Namespace.Module.update(...)
      expected result...   
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

  These examples are based on codes written by Syamil MJ. Source: [link][MultiClauseExample]

[▲ back to Index](#table-of-contents)
___

### Complex API error handling

* __Category:__ Design-related smell.

* __Problem:__ When a function alone assumes the responsibility of handling multiple possibilities of different errors returned by the same API endpoint, this function can become confusing.

* __Example:__ An example of this code smell is when a function uses the ``case`` control-flow structure to handle these multiple variations of response types from an endpoint. This practice can make it long and low readable, as shown next.

  ```elixir
  def get_customer(customer_id) do
    case get("/customers/#{customer_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{body: body}} -> {:error, body}
      {:error, _} = other -> other
    end
  end
  ```

* __Refactoring:__ As shown below, in this situation, instead of using the ``case`` control-flow structure, it is better to delegate the response variations handling to a specific function (multi-clause), using pattern matching for each API response variation.

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

  These examples are based on codes written by Zack <sup>[MrDoops][MrDoops]</sup> and Dimitar Panayotov <sup>[dimitarvp][dimitarvp]</sup>. Source: [link][ComplexErrorHandleExample]

[▲ back to Index](#table-of-contents)
___

### Exceptions for control-flow

* __Category:__ Design-related smell.

* __Problem:__ This smell refers to codes that force developers to handle exceptions for control-flow. An exception handling itself does not represent a code smell, but when developers are deprived of the freedom to use other programming mechanisms to control-flow of your applications in the event of errors, this is considered a code smell.

* __Example:__ An example of this code smell, as shown below, is when a library forces its clients to use ``try .. rescue`` statements to capture and evaluate errors, thus controlling the logical flow of their applications.

  ```elixir
  # Avoid using errors for control-flow.
  try do
    {:ok, value} = MyModule.janky_function()
    "All good! #{value}."
  rescue
    e in RuntimeError ->
      reason = e.message
      "Uh oh! #{reason}."
  end
  ```

* __Refactoring:__ A library author shall guarantee that clients are not required to use exceptions for control-flow in their applications. As shown below, this can be done by replacing exceptions with specific control-flow structures, such as the ``case`` statement along with pattern matchings. This refactoring gives clients more freedom to decide how to proceed in the event of errors, defining what is exceptional or not in different situations.

  ```elixir
  # Rather, use control-flow structures for control-flow.
  case MyModule.janky_function() do
    {:ok, value} -> "All good! #{value}."
    {:error, reason} -> "Uh oh! #{reason}."
  end
  ```

  These code examples are written by Tim Austin <sup>[neenjaw][neenjaw]</sup> and Angelika Tyborska <sup>[angelikatyborska][angelikatyborska]</sup>. Source: [link][ExceptionsForControlFlowExamples]

[▲ back to Index](#table-of-contents)
___

### Untested polymorphic behavior

* __Category:__ Design-related smell.

* __Problem:__ This code smell refers to functions that take protocol-dependent parameters and are therefore polymorphic. A polymorphic function itself does not represent a code smell, but some developers implement these more generic functions without accompanying guard clauses to verify that the types of parameters received implemented the required protocols.

* __Example:__ An example of this code smell is when a function uses internally the function ``to_string()`` to convert data received by parameter. The function ``to_string()`` uses the protocol ``String.Chars`` for conversions. Many Elixir's data types like ``BitString``, ``Integer``, ``Float``, and ``URI`` implement this protocol. However, as shown below, other Elixir's data types such as ``Map`` do not implement this protocol, thus making the behavior of the ``dasherize/1`` function unpredictable.

  ```elixir
  defmodule CodeSmells do
    def dasherize(data) do
      to_string(data)
      |> String.replace("_", "-")
    end
  end

  #...Use examples...

  iex(1)> CodeSmells.dasherize("Lucas_Vegi")
  "Lucas-Vegi"

  iex(2)> CodeSmells.dasherize(10)
  "10"

  iex(3)> CodeSmells.dasherize(URI.parse("http://www.code_smells.com"))
  "http://www.code-smells.com"

  iex(4)> CodeSmells.dasherize(%{last_name: "vegi", first_name: "lucas"})
  ** (Protocol.UndefinedError) protocol String.Chars not implemented 
  for %{first_name: "lucas", last_name: "vegi"} of type Map
  ```

* __Refactoring:__ There are two main ways to improve the internal quality of code affected by this smell. 1) Write test cases (via ``@doc``) that validate the function for data types that implement the desired protocol; and 2) Implement the function as multi-clause, directing its behavior through guard clauses, as shown below.

  ```elixir
  defmodule CodeSmells do
    @doc """
      Function that converts underscores to dashes.
      Created to illustrate "Untested polymorphic behavior".

      ## Examples

          iex> CodeSmells.dasherize(%{last_name: "vegi", first_name: "lucas"})
          "first-name, last-name"

          iex> CodeSmells.dasherize("Lucas_Vegi")
          "Lucas-Vegi"

          iex> CodeSmells.dasherize(10)
          "10"
    """
    def dasherize(data) when is_map(data) do
      Map.keys(data)
      |> Enum.map(fn key -> "#{key}" end)
      |> Enum.join(", ")
      |> dasherize()
    end

    def dasherize(data) do
      to_string(data)
      |> String.replace("_", "-")
    end
  end

  #...Uses example...

  iex(1)> CodeSmells.dasherize(%{last_name: "vegi", first_name: "lucas"})
  "first-name, last-name"
  ```

  These examples are based on codes written by José Valim. Source: [link][JoseValimExamples]

[▲ back to Index](#table-of-contents)
___

### Code organization by process

* __Category:__ Design-related smell.

* __Problem:__ This smell refers to codes unnecessarily organized by processes. A process itself does not represent a code smell, but it should only be used to model runtime properties (e.g., concurrency, access to shared resources, and event scheduling). When a process is used for code organization, it can create bottlenecks in the system.

* __Example:__ An example of this code smell, as shown below, is a library that implements calculator operations (e.g., add, and subtract) by means of a ``GenSever`` process<sup>[link][GenServer]</sup>. If the number of calls to this single process grows, this code organization can compromise the system performance, become a bottleneck.

  ```elixir
  defmodule Calculator do
    use GenServer

    @moduledoc """
      Calculator that performs two basic arithmetic operations.
      This code is unnecessarily organized by a GenServer process.
    """

    @doc """
      Function to perform the sum of two values.
    """
    def add(a, b, pid) do
      GenServer.call(pid, {:add, a, b})
    end

    @doc """
      Function to perform subtraction of two values.
    """
    def subtract(a, b, pid) do
      GenServer.call(pid, {:subtract, a, b})
    end

    def init(init_arg) do
      {:ok, init_arg}
    end

    def handle_call({:add, a, b}, _from, state) do
      {:reply, a + b, state}
    end

    def handle_call({:subtract, a, b}, _from, state) do
      {:reply, a - b, state}
    end
  end

  # Start a generic server process
  iex(1)> {:ok, pid} = GenServer.start_link(Calculator, :init) 
  {:ok, #PID<0.132.0>}

  #...Use examples...
  iex(2)> Calculator.add(1, 5, pid)
  6

  iex(3)> Calculator.subtract(2, 3, pid)
  -1
  ```

* __Refactoring:__ In Elixir, as shown next, code organization must be done only by modules and functions. Whenever possible, a library should not be organized imposing specific behavior such as parallelization to its clients. It is better to delegate this kind of code behavioral decision to the developers of clients, thus increasing the potential for code reuse of a library.

  ```elixir
  defmodule Calculator do
    def add(a, b) do
      a + b
    end

    def subtract(a, b) do
      a - b
    end
  end

  #...Use examples...

  iex(1)> Calculator.add(1, 5)
  6

  iex(2)> Calculator.subtract(2, 3)
  -1
  ```
  
  These examples are based on codes written in Elixir's official documentation. Source: [link][CodeOrganizationByProcessExample]

[▲ back to Index](#table-of-contents)
___

### Data manipulation by migration

* __Category:__ Design-related smell.

* __Problem:__ This code smell refers to modules that perform both data and structural changes in a database schema via ``Ecto.Migration``<sup>[link][Migration]</sup>. Migrations must be used exclusively to modify a database schema over time (e.g., including or excluding columns and tables). When this responsibility is mixed with the responsibility to manipulate data, the module becomes low cohesive, more difficult to test, and therefore more bug-proneness.

* __Example:__ An example of this code smell is when an ``Ecto.Migration`` is used simultaneously to alter a table, adding a new column to it, and also to update all pre-existing data in that table, assigning a value to this new column. As shown below, in addition to adding the ``is_custom_shop`` column in the ``guitars`` table, this ``Ecto.Migration`` changes the value of this column for data of some specific guitar models.

  ```elixir
  defmodule GuitarStore.Repo.Migrations.AddIsCustomShopToGuitars do
    use Ecto.Migration

    import Ecto.Query
    alias GuitarStore.Inventory.Guitar
    alias GuitarStore.Repo

    @doc """
      A function that modifies the structure of table "guitars", 
      adding column "is_custom_shop" to it. By default, all data 
      pre-stored in this table will have the value false stored 
      in this new column.

      Also, this function updates the "is_custom_shop" column value 
      of some guitar models to true.
    """
    def change do
      alter table("guitars") do
        add :is_custom_shop, :boolean, default: false
      end
      create index("guitars", ["is_custom_shop"])
      
      custom_shop_entries()
      |> Enum.map(&update_guitars/1)
    end

    @doc """
      A function that updates values of column "is_custom_shop" to true.
    """
    defp update_guitars({make, model, year}) do
      from(g in Guitar,
        where: g.make == ^make and g.model == ^model and g.year == ^year,
        select: g
      )
      |> Repo.update_all(set: [is_custom_shop: true])
    end

    @doc """
      Function that defines which guitar models that need to have the values 
      of the "is_custom_shop" column updated to true.
    """
    defp custom_shop_entries() do
      [
        {"Gibson", "SG", 1999},
        {"Fender", "Telecaster", 2020}
      ]
    end
  end
  ```

  You can run this smelly migration above by going to the root of your project and typing the next command via console:
  
  ```elixir
    mix ecto.migrate
  ```
  
* __Refactoring:__ To remove this code smell is necessary to separate the data manipulation in a ``mix task`` <sup>[link][MixTask]</sup> different from the module that performs the structural changes of the database via ``Ecto.Migration``. This separation of responsibilities is a best practice for increasing code testability. As shown below, the module ``AddIsCustomShopToGuitars`` now use ``Ecto.Migration`` only to perfom structural changes in the database schema:

  ```elixir
  defmodule GuitarStore.Repo.Migrations.AddIsCustomShopToGuitars do
    use Ecto.Migration

    @doc """
      A function that modifies the structure of table "guitars", 
      adding column "is_custom_shop" to it. By default, all data 
      pre-stored in this table will have the value false stored 
      in this new column.
    """
    def change do
      alter table("guitars") do
        add :is_custom_shop, :boolean, default: false
      end

      create index("guitars", ["is_custom_shop"])
    end
  end
  ```

  The new mix task ``PopulateIsCustomShop``, shown next, has only the responsibility to perform data manipulation, thus improving the code testability:

  ```elixir
  defmodule Mix.Tasks.PopulateIsCustomShop do
    @shortdoc "Populates is_custom_shop column"

    use Mix.Task

    import Ecto.Query
    alias GuitarStore.Inventory.Guitar
    alias GuitarStore.Repo

    @requirements ["app.start"]

    def run(_) do
      custom_shop_entries()
      |> Enum.map(&update_guitars/1)
    end

    defp update_guitars({make, model, year}) do
      from(g in Guitar,
        where: g.make == ^make and g.model == ^model and g.year == ^year,
        select: g
      )
      |> Repo.update_all(set: [is_custom_shop: true])
    end

    defp custom_shop_entries() do
      [
        {"Gibson", "SG", 1999},
        {"Fender", "Telecaster", 2020}
      ]
    end
  end
  ```  

  You can run this ``mix task`` above typing the next command via console:
  
  ```elixir
    mix populate_is_custom_shop
  ```
  
  These examples are based on codes written by Carlos Souza. Source: [link][DataManipulationByMigrationExamples]

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
[JoseValimExamples]: http://blog.plataformatec.com.br/2014/09/writing-assertive-code-with-elixir/
[dimitarvp]: https://elixirforum.com/u/dimitarvp
[MrDoops]: https://elixirforum.com/u/MrDoops
[neenjaw]: https://exercism.org/profiles/neenjaw
[angelikatyborska]: https://exercism.org/profiles/angelikatyborska
[ExceptionsForControlFlowExamples]: https://exercism.org/tracks/elixir/concepts/try-rescue
[DataManipulationByMigrationExamples]: https://www.idopterlabs.com.br/post/criando-uma-mix-task-em-elixir
[Migration]: https://hexdocs.pm/ecto_sql/Ecto.Migration.html
[MixTask]: https://hexdocs.pm/mix/Mix.html#module-mix-task
[CodeOrganizationByProcessExample]: https://hexdocs.pm/elixir/master/library-guidelines.html#avoid-using-processes-for-code-organization
[GenServer]: https://hexdocs.pm/elixir/master/GenServer.html
