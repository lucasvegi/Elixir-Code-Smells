# [Catalog of Elixir-specific code smells][Elixir Smells]

[![GitHub last commit](https://img.shields.io/github/last-commit/lucasvegi/Elixir-Code-Smells)](https://github.com/lucasvegi/Elixir-Code-Smells/commits/main)
[![Twitter URL](https://img.shields.io/twitter/url?style=social&url=https%3A%2F%2Fgithub.com%2Flucasvegi%2FElixir-Code-Smells)](https://twitter.com/intent/tweet?url=https%3A%2F%2Fgithub.com%2Flucasvegi%2FElixir-Code-Smells&via=lucasvegi&text=Catalog%20of%20Elixir-specific%20code%20smells%3A&hashtags=MyElixirStatus%2CElixirLang)

## Table of Contents

* __[Introduction](#introduction)__
* __[Design-related smells](#design-related-smells)__
  * [GenServer Envy](#genserver-envy)
  * [Agent Obsession](#agent-obsession)
  * [Unsupervised process](#unsupervised-process)
  * [Large messages between processes](#large-messages-between-processes)
  * [Complex multi-clause function](#complex-multi-clause-function)
  * [Complex extraction in clauses](#complex-extraction-in-clauses) [^**]
  * [Complex branching](#complex-branching)
  * [Complex else clauses in with](#complex-else-clauses-in-with) [^**]
  * [Exceptions for control-flow](#exceptions-for-control-flow)
  * [Untested polymorphic behavior](#untested-polymorphic-behavior)
  * [Alternative return types](#alternative-return-types) [^**]
  * [Code organization by process](#code-organization-by-process)
  * [Data manipulation by migration](#data-manipulation-by-migration)
* __[Low-level concerns smells](#low-level-concerns-smells)__
  * [Working with invalid data](#working-with-invalid-data)
  * [Map/struct dynamic access](#mapstruct-dynamic-access)
  * [Unplanned value extraction](#unplanned-value-extraction)
  * [Modules with identical names](#modules-with-identical-names)
  * [Unnecessary macro](#unnecessary-macro)
  * [Large code generation](#large-code-generation) [^**]
  * [App configuration for code libs](#app-configuration-for-code-libs)
  * [Compile-time app configuration](#compile-time-app-configuration)
  * [Dependency with "use" when an "import" is enough](#dependency-with-use-when-an-import-is-enough)
* __[About](#about)__

[^**]: These code smells were suggested by the Elixir community.

## Introduction

[Elixir][Elixir] is a new functional programming language whose popularity is rising in the industry <sup>[link][ElixirInProduction]</sup>. However, there are few works in the scientific literature focused on studying the internal quality of systems implemented in this language.

In order to better understand the types of sub-optimal code structures that can harm the internal quality of Elixir systems, we scoured websites, blogs, forums, and videos (grey literature review), looking for specific code smells for Elixir that are discussed by its developers.

As a result of this investigation, we have initially proposed a catalog of 18 new smells that are specific to Elixir systems. Other smells are being suggested by the community, so this catalog is constantly being updated __(currently 22 smells)__. These code smells are categorized into two different groups ([design-related](#design-related-smells) and [low-level concerns](#low-level-concerns-smells)), according to the type of impact and code extent they affect. This catalog of Elixir-specific code smells is presented below. Each code smell is documented using the following structure:

* __Name:__ Unique identifier of the code smell. This name is important to facilitate communication between developers;
* __Category:__ The portion of code affected by smell and its severity;
* __Problem:__ How the code smell can harm code quality and what impacts this can have for developers;
* __Example:__ Code and textual descriptions to illustrate the occurrence of the code smell;
* __Refactoring:__ Ways to change smelly code in order to improve its qualities. Examples of refactored code are presented to illustrate these changes.

The objective of this catalog of code smells is to instigate the improvement of the quality of code developed in Elixir. For this reason, we are interested in knowing Elixir's community opinion about these code smells: *Do you agree that these code smells can be harmful? Have you seen any of them in production code? Do you have any suggestions about some Elixir-specific code smell not cataloged by us?...*

Please feel free to make pull requests and suggestions ([Issues][Issues] tab). We want to hear from you!

[▲ back to Index](#table-of-contents)

## Design-related smells

Design-related smells are more complex, affect a coarse-grained code element, and are therefore harder to detect. In this section, 13 different smells classified as design-related are explained and exemplified:

### GenServer Envy

* __Category:__ Design-related smell.

* __Problem:__ In Elixir, processes can be primitively created by ``Kernel.spawn/1``, ``Kernel.spawn/3``, ``Kernel.spawn_link/1`` and ``Kernel.spawn_link/3`` functions. Although it is possible to create them this way, it is more common to use abstractions (e.g., [``Agent``][Agent], [``Task``][Task], and [``GenServer``][GenServer]) provided by Elixir to create processes. The use of each specific abstraction is not a code smell in itself; however, there can be trouble when either a ``Task`` or ``Agent`` is used beyond its suggested purposes, being treated like a ``GenServer``.

* __Example:__ As shown next, ``Agent`` and ``Task`` are abstractions to create processes with specialized purposes. In contrast, ``GenServer`` is a more generic abstraction used to create processes for many different purposes:

  * ``Agent``: As Elixir works on the principle of immutability, by default no value is shared between multiple places of code, enabling read and write as in a global variable. An ``Agent`` is a simple process abstraction focused on solving this limitation, enabling processes to share state.
  * ``Task``: This process abstraction is used when we only need to execute some specific action asynchronously, often in an isolated way, without communication with other processes.
  * ``GenServer``: This is the most generic process abstraction. The main benefit of this abstraction is explicitly segregating the server and the client roles, thus providing a better API for the organization of processes communication. Besides that, a ``GenServer`` can also encapsulate state (like an ``Agent``), provide sync and async calls (like a ``Task``), and more.
  
  Examples of this code smell appear when ``Agents`` or ``Tasks`` are used for general purposes and not only for specialized ones such as their documentation suggests. To illustrate some smell occurrences, we will cite two specific situations. 1) When a ``Task`` is used not only to async execute an action, but also to frequently exchange messages with other processes; 2) When an ``Agent``, beside sharing some global value between processes, is also frequently used to execute isolated tasks that are not of interest to other processes.

* __Refactoring:__ When an ``Agent`` or ``Task`` goes beyond its suggested use cases and becomes painful, it is better to refactor it into a ``GenServer``.

[▲ back to Index](#table-of-contents)
___

### Agent Obsession

* __Category:__ Design-related smell.

* __Problem:__ In Elixir, an ``Agent`` is a process abstraction focused on sharing information between processes by means of message passing. It is a simple wrapper around shared information, thus facilitating its read and update from any place in the code. The use of an ``Agent`` to share information is not a code smell in itself; however, when the responsibility for interacting directly with an ``Agent`` is spread across the entire system, this can be problematic. This bad practice can increase the difficulty of code maintenance and make the code more prone to bugs.

* __Example:__ The following code seeks to illustrate this smell. The responsibility for interacting directly with the ``Agent`` is spread across four different modules (i.e, ``A``, ``B``, ``C``, and ``D``).

  ```elixir
  defmodule A do
    #...
    def update(pid) do
      #...
      Agent.update(pid, fn _list -> 123 end)
      #...
    end
  end
  ```

  ```elixir
  defmodule B do
    #...
    def update(pid) do
      #...
      Agent.update(pid, fn content -> %{a: content} end)
      #...
    end
  end
  ```

  ```elixir
  defmodule C do
    #...
    def update(pid) do
      #...
      Agent.update(pid, fn content -> [:atom_value | [content]] end)
      #...
    end
  end
  ```

  ```elixir
  defmodule D do
    #...
    def get(pid) do
      #...
      Agent.get(pid, fn content -> content end)
      #...
    end
  end
  ```
  
  This spreading of responsibility can generate duplicated code and make code maintenance more difficult. Also, due to the lack of control over the format of the shared data, complex composed data can be shared. This freedom to use any format of data is dangerous and can induce developers to introduce bugs.

  ```elixir
  # start an agent with initial state of an empty list
  iex(1)> {:ok, agent} = Agent.start_link fn -> [] end        
  {:ok, #PID<0.135.0>}

  # many data format (i.e., List, Map, Integer, Atom) are
  # combined through direct access spread across the entire system
  iex(2)> A.update(agent)
  iex(3)> B.update(agent)
  iex(4)> C.update(agent)
    
  # state of shared information
  iex(5)> D.get(agent)
  [:atom_value, %{a: 123}]
  ```

* __Refactoring:__ Instead of spreading direct access to an ``Agent`` over many places in the code, it is better to refactor this code by centralizing the responsibility for interacting with an ``Agent`` in a single module. This refactoring improves the maintainability by removing duplicated code; it also allows you to limit the accepted format for shared data, reducing bug-proneness. As shown below, the module ``KV.Bucket`` is centralizing the responsibility for interacting with the ``Agent``. Any other place in the code that needs to access shared data must now delegate this action to ``KV.Bucket``. Also, ``KV.Bucket`` now only allows data to be shared in ``Map`` format.

  ```elixir
  defmodule KV.Bucket do
    use Agent

    @doc """
    Starts a new bucket.
    """
    def start_link(_opts) do
      Agent.start_link(fn -> %{} end)
    end

    @doc """
    Gets a value from the `bucket` by `key`.
    """
    def get(bucket, key) do
      Agent.get(bucket, &Map.get(&1, key))
    end

    @doc """
    Puts the `value` for the given `key` in the `bucket`.
    """
    def put(bucket, key, value) do
      Agent.update(bucket, &Map.put(&1, key, value))
    end
  end
  ```

  The following are examples of how to delegate access to shared data (provided by an ``Agent``) to ``KV.Bucket``.

  ```elixir
  # start an agent through a `KV.Bucket`
  iex(1)> {:ok, bucket} = KV.Bucket.start_link(%{})
  {:ok, #PID<0.114.0>}

  # add shared values to the keys `milk` and `beer`
  iex(2)> KV.Bucket.put(bucket, "milk", 3)
  iex(3)> KV.Bucket.put(bucket, "beer", 7)

  # accessing shared data of specific keys
  iex(4)> KV.Bucket.get(bucket, "beer")   
  7
  iex(5)> KV.Bucket.get(bucket, "milk")
  3
  ```

  These examples are based on code written in Elixir's official documentation. Source: [link][AgentObsessionExample]

[▲ back to Index](#table-of-contents)
___

### Unsupervised process

* __Category:__ Design-related smell.

* __Problem:__ In Elixir, creating a process outside a supervision tree is not a code smell in itself. However, when code creates a large number of long-running processes outside a supervision tree, this can make visibility and monitoring of these processes difficult, preventing developers from fully controlling their applications.

* __Example:__ The following code example seeks to illustrate a library responsible for maintaining a numerical ``Counter`` through a ``GenServer`` process outside a supervision tree. Multiple counters can be created simultaneously by a client (one process for each counter), making these unsupervised processes difficult to manage. This can cause problems with the initialization, restart, and shutdown of a system.

  ```elixir
  defmodule Counter do
    use GenServer

    @moduledoc """
      Global counter implemented through a GenServer process
      outside a supervision tree.
    """

    @doc """
      Function to create a counter.
        initial_value: any integer value.
        pid_name: optional parameter to define the process name.
                  Default is Counter.
    """
    def start(initial_value, pid_name \\ __MODULE__)
      when is_integer(initial_value) do
      GenServer.start(__MODULE__, initial_value, name: pid_name)
    end

    @doc """
      Function to get the counter's current value.
        pid_name: optional parameter to inform the process name.
                  Default is Counter.
    """
    def get(pid_name \\ __MODULE__) do
      GenServer.call(pid_name, :get)
    end

    @doc """
      Function to changes the counter's current value.
      Returns the updated value.
        value: amount to be added to the counter.
        pid_name: optional parameter to inform the process name.
                  Default is Counter.
    """
    def bump(value, pid_name \\ __MODULE__) do
      GenServer.call(pid_name, {:bump, value})
      get(pid_name)
    end

    ## Callbacks

    @impl true
    def init(counter) do
      {:ok, counter}
    end

    @impl true
    def handle_call(:get, _from, counter) do
      {:reply, counter, counter}
    end

    def handle_call({:bump, value}, _from, counter) do
      {:reply, counter, counter + value}
    end
  end

  #...Use examples...

  iex(1)> Counter.start(0)
  {:ok, #PID<0.115.0>}

  iex(2)> Counter.get()   
  0

  iex(3)> Counter.start(15, C2)  
  {:ok, #PID<0.120.0>}

  iex(4)> Counter.get(C2)
  15

  iex(5)> Counter.bump(-3, C2)
  12

  iex(6)> Counter.bump(7)
  7
  ```

* __Refactoring:__ To ensure that clients of a library have full control over their systems, regardless of the number of processes used and the lifetime of each one, all processes must be started inside a supervision tree. As shown below, this code uses a ``Supervisor`` <sup>[link][Supervisor]</sup> as a supervision tree. When this Elixir application is started, two different counters (``Counter`` and ``C2``) are also started as child processes of the ``Supervisor`` named ``App.Supervisor``. Both are initialized with zero. By means of this supervision tree, it is possible to manage the lifecycle of all child processes (e.g., stopping or restarting each one), improving the visibility of the entire app.

  ```elixir
  defmodule SupervisedProcess.Application do
    use Application

    @impl true
    def start(_type, _args) do
      children = [
        # The counters are Supervisor children started via Counter.start(0).
        %{
          id: Counter,
          start: {Counter, :start, [0]}
        }, 
        %{
          id: C2,
          start: {Counter, :start, [0, C2]}
        }
      ]

      opts = [strategy: :one_for_one, name: App.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  #...Use examples...

  iex(1)> Supervisor.count_children(App.Supervisor)   
  %{active: 2, specs: 2, supervisors: 0, workers: 2}

  iex(2)> Counter.get(Counter)   
  0

  iex(3)> Counter.get(C2)
  0

  iex(4)> Counter.bump(7, Counter)
  7

  iex(5)> Supervisor.terminate_child(App.Supervisor, Counter)
  iex(6)> Supervisor.count_children(App.Supervisor)     
  %{active: 1, specs: 2, supervisors: 0, workers: 2}  #only one active

  iex(7)> Counter.get(Counter)   #Error because it was previously terminated
  ** (EXIT) no process: the process is not alive...

  iex(8)> Supervisor.restart_child(App.Supervisor, Counter)  
  iex(9)> Counter.get(Counter)   #after the restart, this process can be accessed again
  0
  ```

  These examples are based on codes written in Elixir's official documentation. Source: [link][UnsupervisedProcessExample]

[▲ back to Index](#table-of-contents)
___

### Large messages between processes

* __Category:__ Design-related smell.

* __Problem:__ In Elixir, processes run in an isolated manner, often concurrently with other Elixir. Communication between different processes is performed via message passing. The exchange of messages between processes is not a code smell in itself; however, when processes exchange messages, their contents are copied between them. For this reason, if a huge structure is sent as a message from one process to another, the sender can become blocked, compromising performance. If these large message exchanges occur frequently, the prolonged and frequent blocking of processes can cause a system to behave anomalously.

* __Example:__ The following code is composed of two modules which will each run in a different process. As the names suggest, the ``Sender`` module has a function responsible for sending messages from one process to another (i.e., ``send_msg/3``). The ``Receiver`` module has a function to create a process to receive messages (i.e., ``create/0``) and another one to handle the received messages (i.e., ``run/0``). If a huge structure, such as a list with 1_000_000 different values, is sent frequently from ``Sender`` to ``Receiver``, the impacts of this smell could be felt.
  
  ```elixir
  defmodule Receiver do
    @doc """
      Function for receiving messages from processes.
    """
    def run do
      receive do
        {:msg, msg_received} -> msg_received
        {_, _} -> "won't match"
      end
    end

    @doc """
      Create a process to receive a message.
      Messages are received in the run() function of Receiver.
    """
    def create do
      spawn(Receiver, :run, [])
    end
  end
  ```

  ```elixir
  defmodule Sender do
    @doc """
      Function for sending messages between processes.
        pid_receiver: message recipient.
        msg: messages of any type and size can be sent.
        id_msg: used by receiver to decide what to do
                when a message arrives.
                Default is the atom :msg
    """
    def send_msg(pid_receiver, msg, id_msg \\ :msg) do
      send(pid_receiver, {id_msg, msg})
    end
  end
  ```
  
  Examples of large messages between processes:

  ```elixir
  iex(1)> pid = Receiver.create
  #PID<0.144.0>

  #Simulating a message with large content - List with length 1_000_000
  iex(2)> msg = %{from: inspect(self()), to: inspect(pid), content: Enum.to_list(1..1_000_000)}

  iex(3)> Sender.send_msg(pid, msg)
  {:msg,
    %{
      content: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
        39, 40, 41, 42, 43, 44, 45, 46, 47, ...],
      from: "#PID<0.105.0>",
      to: "#PID<0.144.0>"
    }}
  ```

  This example is based on a original code by Samuel Mullen. Source: [link][LargeMessageExample]

[▲ back to Index](#table-of-contents)
___

### Complex multi-clause function

* __Category:__ Design-related smell.

* __Problem:__ Using multi-clause functions in Elixir, to group functions of the same name, is not a code smell in itself. However, due to the great flexibility provided by this programming feature, some developers may abuse the number of guard clauses and pattern matches when defining these grouped functions.

* __Example:__ A recurrent example of abusive use of the multi-clause functions is when we’re trying to mix too much business logic into the function definitions. This makes it difficult to read and understand the logic involved in the functions, which may impair code maintainability. Some developers use documentation mechanisms such as ``@doc`` annotations to compensate for poor code readability, but unfortunately, with a multi-clause function, we can only use these annotations once per function name, particularly on the first or header function. As shown next, all other variations of the function need to be documented only with comments, a mechanism that cannot automate tests, leaving the code prone to bugs.

  ```elixir
  @doc """
    Update sharp product with 0 or empty count
    
    ## Examples

      iex> Namespace.Module.update(...)
      expected result...   
  """
  def update(%Product{count: nil, material: material})
    when material in ["metal", "glass"] do
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

* __Refactoring:__ As shown below, a possible solution to this smell is to break the business rules that are mixed up in a single complex multi-clause function in several different simple functions. Each function can have a specific ``@doc``, describing its behavior and parameters received. While this refactoring sounds simple, it can have a lot of impact on the function's current clients, so be careful!

  ```elixir
  @doc """
    Update sharp product

    ## Parameter
      struct: %Product{...}
    
    ## Examples

      iex> Namespace.Module.update_sharp_product(%Product{...})
      expected result...   
  """
  def update_sharp_product(struct) do
    # ...
  end

  @doc """
    Update blunt product

    ## Parameter
      struct: %Product{...}
    
    ## Examples

      iex> Namespace.Module.update_blunt_product(%Product{...})
      expected result...   
  """
  def update_blunt_product(struct) do
    # ...
  end

  @doc """
    Update animal

    ## Parameter
      struct: %Animal{...}
    
    ## Examples

      iex> Namespace.Module.update_animal(%Animal{...})
      expected result...   
  """
  def update_animal(struct) do
    # ...
  end
  ```

  This example is based on a original code by Syamil MJ ([@syamilmj][syamilmj]). Source: [link][MultiClauseExample]

[▲ back to Index](#table-of-contents)
___

### Complex extraction in clauses

* __Category:__ Design-related smell.

* __Note:__ This smell was suggested by the community via issues ([#9][Complex-extraction-in-clauses-issue]).

* __Problem:__ When we use multi-clause functions, it is possible to extract values in the clauses for further usage and for pattern matching/guard checking. This extraction itself does not represent a code smell, but when you have too many clauses or too many arguments, it becomes hard to know which extracted parts are used for pattern/guards and what is used only inside the function body. This smell is related to [Complex multi-clause function](#complex-multi-clause-function), but with implications of its own. It impairs the code readability in a different way.

* __Example:__ The following code, although simple, tries to illustrate the occurrence of this code smell. The multi-clause function ``drive/1`` is extracting fields of an ``%User{}`` struct in its clauses for further usage (``name``) and for pattern/guard checking (``age``). 

  ```elixir
  def drive(%User{name: name, age: age}) when age >= 18 do
    "#{name} can drive"
  end

  def drive(%User{name: name, age: age}) when age < 18 do
    "#{name} cannot drive"
  end
  ```
  
  While the example is small and looks like a clear code, try to imagine a situation where ``drive/1`` was more complex, having many more clauses, arguments, and extractions. This is the really smelly code!

* __Refactoring:__ As shown below, a possible solution to this smell is to extract only pattern/guard related variables in the signature once you have many arguments or multiple clauses:

  ```elixir
  def drive(%User{age: age} = user) when age >= 18 do
    %User{name: name} = user
    "#{name} can drive"
  end

  def drive(%User{age: age} = user) when age < 18 do
    %User{name: name} = user
    "#{name} cannot drive"
  end
  ```

  This example and the refactoring are proposed by José Valim ([@josevalim][jose-valim])

[▲ back to Index](#table-of-contents)
___

### Complex branching

* __Category:__ Design-related smell.

* __Note:__ Formerly known as "Complex API error handling".

* __Problem:__ When a function assumes the responsibility of handling multiple errors alone, it can increase its cyclomatic complexity (metric of control-flow) and become incomprehensible. This situation can configure a specific instance of "Long function", a traditional code smell, but has implications of its own. Under these circumstances, this function could get very confusing, difficult to maintain and test, and therefore bug-proneness.

* __Example:__ An example of this code smell is when a function uses the ``case`` control-flow structure or other similar constructs (e.g., ``cond``, or ``receive``) to handle multiple variations of response types returned by the same API endpoint. This practice can make the function more complex, long, and difficult to understand, as shown next.

  ```elixir
  def get_customer(customer_id) do
    case get("/customers/#{customer_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{body: body}} -> {:error, body}
      {:error, _} = other -> other
    end
  end
  ```

  Although ``get_customer/1`` is not really long in this example, it could be. Thinking about this more complex scenario, where a large number of different responses can be provided to the same endpoint, is not a good idea to concentrate all on a single function. This is a risky scenario, where a little typo, or any problem introduced by the programmer in handling a response type, could eventually compromise the handling of all responses from the endpoint (if the function raises an exception, for example).

* __Refactoring:__ As shown below, in this situation, instead of concentrating all handlings within the same function,  creating a complex branching, it is better to delegate each branch (handling of a response type) to a different private function. In this way, the code will be cleaner, more concise, and readable.

  ```elixir
  def get_customer(customer_id) when is_integer(customer_id) do
    case get("/customers/#{customer_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> success_api_response(body)
      {:ok, %Tesla.Env{body: body}} -> x_error_api_response(body)
      {:error, _} = other -> y_error_api_response(other)
    end
  end

  defp success_api_response(body) do
    {:ok, body}
  end

  defp x_error_api_response(body) do
    {:error, body}
  end

  defp y_error_api_response(other) do
    other
  end
  ```

  While this example of refactoring ``get_customer/1`` might seem quite more verbose than the original code, remember to imagine a scenario where ``get_customer/1`` is responsible for handling a number much larger than three different types of possible responses. This is the smelly scenario!

  This example is based on code written by Zack <sup>[MrDoops][MrDoops]</sup> and Dimitar Panayotov <sup>[dimitarvp][dimitarvp]</sup>. Source: [link][ComplexErrorHandleExample]. We got suggestions from José Valim ([@josevalim][jose-valim]) on the refactoring.

[▲ back to Index](#table-of-contents)
___

### Complex else clauses in with

* __Category:__ Design-related smell.

* __Note:__ This smell was suggested by the community via issues ([#7][Complex-else-clauses-in-with-issue]).

* __Problem:__ This code smell refers to ``with`` statements that flatten all its error clauses into a single complex ``else`` block. This situation is harmful to the code readability and maintainability because difficult to know from which clause the error value came.

* __Example:__ An example of this code smell, as shown below, is a function ``open_decoded_file/1`` that read a base 64 encoded string content from a file and returns a decoded binary string. This function uses a ``with`` statement that needs to handle two possible errors, all of which are concentrated in a single complex ``else`` block.

  ```elixir
  def open_decoded_file(path) do
    with {:ok, encoded} <- File.read(path),
         {:ok, value} <- Base.decode64(encoded) do
      value
    else
        {:error, _} -> :badfile
        :error -> :badencoding
    end
  end
  ```

* __Refactoring:__ As shown below, in this situation, instead of concentrating all error handlings within a single complex ``else`` block, it is better to normalize the return types in specific private functions. In this way, due to its organization, the code will be cleaner and more readable.

  ```elixir
  def open_decoded_file(path) do
    with {:ok, encoded} <- file_read(path),
         {:ok, value} <- base_decode64(encoded) do
      value
    end
  end

  defp file_read(path) do
    case File.read(path) do
      {:ok, contents} -> {:ok, contents}
      {:error, _} -> :badfile
    end
  end

  defp base_decode64(contents) do
    case Base.decode64(contents) do
      {:ok, contents} -> {:ok, contents}
      :error -> :badencoding
    end
  end
  ```

  This example and the refactoring are proposed by José Valim ([@josevalim][jose-valim])

[▲ back to Index](#table-of-contents)
___

### Exceptions for control-flow

* __Category:__ Design-related smell.

* __Problem:__ This smell refers to code that forces developers to handle exceptions for control-flow. Exception handling itself does not represent a code smell, but this should not be the only alternative available to developers to handle an error in client code. When developers have no freedom to decide if an error is exceptional or not, this is considered a code smell.

* __Example:__ An example of this code smell, as shown below, is when a library (e.g. ``MyModule``) forces its clients to use ``try .. rescue`` statements to capture and evaluate errors. This library does not allow developers to decide if an error is exceptional or not in their applications.

  ```elixir
  defmodule MyModule do
    def janky_function(value) do
      if is_integer(value) do
        #...
        "Result..."
      else
        raise RuntimeError, message: "invalid argument. Is not integer!"
      end
    end
  end
  ```

  ```elixir
  defmodule Client do
   
    # Client forced to use exceptions for control-flow.
    def foo(arg) do
      try do
        value = MyModule.janky_function(arg)
        "All good! #{value}."
      rescue
        e in RuntimeError ->
          reason = e.message
          "Uh oh! #{reason}."
      end
    end

  end

  #...Use examples...

  iex(1)> Client.foo(1)                   
  "All good! Result...."

  iex(2)> Client.foo("lucas")
  "Uh oh! invalid argument. Is not integer!."
  ```

* __Refactoring:__ Library authors should guarantee that clients are not required to use exceptions for control-flow in their applications. As shown below, this can be done by refactoring the library ``MyModule``, providing two versions of the function that forces clients to use exceptions for control-flow (e.g., ``janky_function``). 1) a version with the raised exceptions should have the same name as the smelly one, but with a trailing ``!`` (i.e., ``janky_function!``); 2) Another version, without raised exceptions, should have a name identical to the original version (i.e., ``janky_function``), and should return the result wrapped in a tuple.

  ```elixir
  defmodule MyModule do
    @moduledoc """
      Refactored library
    """
    
    @doc """
      Refactored version without exceptions for control-flow.
    """
    def janky_function(value) do
      if is_integer(value) do
        #...
        {:ok, "Result..."}
      else
        {:error, "invalid argument. Is not integer!"}
      end
    end

    def janky_function!(value) do
      case janky_function(value) do
        {:ok, result} -> 
          result
        {:error, message} -> 
          raise RuntimeError, message: message
      end
    end
  end
  ```

  This refactoring gives clients more freedom to decide how to proceed in the event of errors, defining what is exceptional or not in different situations. As shown next, when an error is not exceptional, clients can use specific control-flow structures, such as the ``case`` statement along with pattern matching.

  ```elixir
  defmodule Client do
   
    # Clients now can also choose to use control-flow structures
    # for control-flow when an error is not exceptional.
    def foo(arg) do
      case MyModule.janky_function(arg) do
        {:ok, value} -> "All good! #{value}."
        {:error, reason} -> "Uh oh! #{reason}."
      end
    end

  end

  #...Use examples...

  iex(1)> Client.foo(1)                   
  "All good! Result...."

  iex(2)> Client.foo("lucas")
  "Uh oh! invalid argument. Is not integer!."
  ```

  This example is based on code written by Tim Austin <sup>[neenjaw][neenjaw]</sup> and Angelika Tyborska <sup>[angelikatyborska][angelikatyborska]</sup>. Source: [link][ExceptionsForControlFlowExamples]

[▲ back to Index](#table-of-contents)
___

### Untested polymorphic behavior

* __Category:__ Design-related smell.

* __Problem:__ This code smell refers to functions that have protocol-dependent parameters and are therefore polymorphic. A polymorphic function itself does not represent a code smell, but some developers implement these generic functions without accompanying guard clauses, allowing to pass parameters that do not implement the required protocol or that have no meaning.

* __Example:__ An instance of this code smell happens when a function uses ``to_string()`` to convert data received by parameter. The function ``to_string()`` uses the protocol ``String.Chars`` for conversions. Many Elixir data types (e.g., ``BitString``, ``Integer``, ``Float``, ``URI``) implement this protocol. However, as shown below, other Elixir data types (e.g., ``Map``) do not implement it and can cause an error in ``dasherize/1`` function. Depending on the situation, this behavior can be desired or not. Besides that, it may not make sense to dasherize a ``URI`` or a number as shown next.

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

  iex(2)> CodeSmells.dasherize(10)  #<= Makes sense?
  "10"

  iex(3)> CodeSmells.dasherize(URI.parse("http://www.code_smells.com")) #<= Makes sense?
  "http://www.code-smells.com"

  iex(4)> CodeSmells.dasherize(%{last_name: "vegi", first_name: "lucas"})
  ** (Protocol.UndefinedError) protocol String.Chars not implemented 
  for %{first_name: "lucas", last_name: "vegi"} of type Map
  ```

* __Refactoring:__ There are two main alternatives to improve code affected by this smell. __1)__ You can either remove the protocol use (i.e., ``to_string/1``), by adding multi-clauses on ``dasherize/1`` or just remove it; or __2)__ You can document that ``dasherize/1`` uses the protocol ``String.Chars`` for conversions, showing its consequences. As shown next, we refactored using the first alternative, removing the protocol and restricting ``dasherize/1`` parameter only to desired data types (i.e., ``BitString`` and ``Atom``). Besides that, we use ``@doc`` to validate ``dasherize/1`` for desired inputs and to document the behavior to some types that we think don't make sense for the function (e.g., ``Integer`` and ``URI``).

  ```elixir
  defmodule CodeSmells do
    @doc """
      Function that converts underscores to dashes.

      ## Parameter
        data: only BitString and Atom are supported.

      ## Examples

          iex> CodeSmells.dasherize(:lucas_vegi)
          "lucas-vegi"

          iex> CodeSmells.dasherize("Lucas_Vegi")
          "Lucas-Vegi"

          iex> CodeSmells.dasherize(%{last_name: "vegi", first_name: "lucas"})
          ** (FunctionClauseError) no function clause matching in CodeSmells.dasherize/1

          iex> CodeSmells.dasherize(URI.parse("http://www.code_smells.com"))
          ** (FunctionClauseError) no function clause matching in CodeSmells.dasherize/1

          iex> CodeSmells.dasherize(10)
          ** (FunctionClauseError) no function clause matching in CodeSmells.dasherize/1
    """
    def dasherize(data) when is_atom(data) do
      dasherize(Atom.to_string(data))
    end

    def dasherize(data) when is_binary(data) do
      String.replace(data, "_", "-")
    end
  end

  #...Use examples...

  iex(1)> CodeSmells.dasherize(:lucas_vegi)
  "lucas-vegi"

  iex(2)> CodeSmells.dasherize("Lucas_Vegi")
  "Lucas-Vegi"

  iex(3)> CodeSmells.dasherize(10)
  ** (FunctionClauseError) no function clause matching in CodeSmells.dasherize/1
  ```

  This example is based on code written by José Valim ([@josevalim][jose-valim]). Source: [link][JoseValimExamples]

[▲ back to Index](#table-of-contents)
___

### Alternative return types

* __Category:__ Design-related smell.

* __Note:__ This smell was suggested by the community via issues ([#6][Alternative-return-type-issue]).

* __Problem:__ This code smell refers to functions that receive options (e.g., ``keyword list``) parameters that drastically change its return type. Because options are optional and sometimes set dynamically, if they change the return type it may be hard to understand what the function actually returns.

* __Example:__ An example of this code smell, as shown below, is when a library (e.g. ``AlternativeInteger``) has a multi-clause function ``parse/2`` with many alternative return types. Depending on the options received as a parameter, the function will have a different return type.

  ```elixir
  defmodule AlternativeInteger do
    def parse(string, opts) when is_list(opts) do
      case opts[:discard_rest] do
        true -> #only an integer value convert from string parameter
        _   ->  #another return type (e.g., tuple)
      end
    end

    def parse(string, opts \\ :default) do
      #another return type (e.g., tuple)
    end
  end

  #...Use examples...

  iex(1)> AlternativeInteger.parse("13")
  {13, "..."}

  iex(2)> AlternativeInteger.parse("13", discard_rest: true)
  13

  iex(3)> AlternativeInteger.parse("13", discard_rest: false)
  {13, "..."}
  ```

* __Refactoring:__ To refactor this smell, as shown next, it's better to add in the library a specific function for each return type (e.g., ``parse_no_rest/1``), no longer delegating this to an options parameter.

  ```elixir
  defmodule AlternativeInteger do
    def parse_no_rest(string) do
      #only an integer value convert from string parameter
    end

    def parse(string) do
      #another return type (e.g., tuple)
    end
  end

  #...Use examples...

  iex(1)> AlternativeInteger.parse("13")
  {13, "..."}

  iex(2)> AlternativeInteger.parse_no_rest("13")
  13
  ```

  This example and the refactoring are proposed by José Valim ([@josevalim][jose-valim])

[▲ back to Index](#table-of-contents)
___

### Code organization by process

* __Category:__ Design-related smell.

* __Problem:__ This smell refers to code that is unnecessarily organized by processes. A process itself does not represent a code smell, but it should only be used to model runtime properties (e.g., concurrency, access to shared resources, event scheduling). When a process is used for code organization, it can create bottlenecks in the system.

* __Example:__ An example of this code smell, as shown below, is a library that implements arithmetic operations (e.g., add, subtract) by means of a ``GenSever`` process<sup>[link][GenServer]</sup>. If the number of calls to this single process grows, this code organization can compromise the system performance, therefore becoming a bottleneck.

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

* __Refactoring:__ In Elixir, as shown next, code organization must be done only by modules and functions. Whenever possible, a library should not impose specific behavior (such as parallelization) on its clients. It is better to delegate this behavioral decision to the developers of clients, thus increasing the potential for code reuse of a library.

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
  
  This example is based on code provided in Elixir's official documentation. Source: [link][CodeOrganizationByProcessExample]

[▲ back to Index](#table-of-contents)
___

### Data manipulation by migration

* __Category:__ Design-related smell.

* __Problem:__ This code smell refers to modules that perform both data and structural changes in a database schema via ``Ecto.Migration``<sup>[link][Migration]</sup>. Migrations must be used exclusively to modify a database schema over time (e.g., by including or excluding columns and tables). When this responsibility is mixed with data manipulation code, the module becomes less cohesive, more difficult to test, and therefore more prone to bugs.

* __Example:__ An example of this code smell is when an ``Ecto.Migration`` is used simultaneously to alter a table, adding a new column to it, and also to update all pre-existing data in that table, assigning a value to this new column. As shown below, in addition to adding the ``is_custom_shop`` column in the ``guitars`` table, this ``Ecto.Migration`` changes the value of this column for some specific guitar models.

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
  
* __Refactoring:__ To remove this code smell, it is necessary to separate the data manipulation in a ``mix task`` <sup>[link][MixTask]</sup> different from the module that performs the structural changes in the database via ``Ecto.Migration``. This separation of responsibilities is a best practice for increasing code testability. As shown below, the module ``AddIsCustomShopToGuitars`` now use ``Ecto.Migration`` only to perform structural changes in the database schema:

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

  Furthermore, the new mix task ``PopulateIsCustomShop``, shown next, has only the responsibility to perform data manipulation, thus improving testability:

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

  You can run this ``mix task`` above by typing the next command via console:
  
  ```elixir
    mix populate_is_custom_shop
  ```
  
  This example is based on code originally written by Carlos Souza. Source: [link][DataManipulationByMigrationExamples]

[▲ back to Index](#table-of-contents)

## Low-level concerns smells

Low-level concerns smells are more simple than design-related smells and affect a small part of the code. Next, all 9 different smells classified as low-level concerns are explained and exemplified:

### Working with invalid data

* __Category:__ Low-level concerns smells.

* __Problem:__ This code smell refers to a function that does not validate its parameters' types and therefore can produce internal non-predicted behavior. When an error is raised inside a function due to an invalid parameter value, this can confuse the developers and make it harder to locate and fix the error.

* __Example:__ An example of this code smell is when a function receives an invalid parameter and then passes it to a function from a third-party library. This will cause an error (raised deep inside the library function), which may be confusing for the developer who is working with invalid data. As shown next, the function ``foo/1`` is a client of a third-party library and doesn't validate its parameters at the boundary. In this way, it is possible that invalid data will be passed from ``foo/1`` to the library, causing a mysterious error.

  ```elixir
  defmodule MyApp do
    alias ThirdPartyLibrary, as: Library

    def foo(invalid_data) do
      #...some code...
      Library.sum(1, invalid_data)
      #...some code...
    end
  end

  #...Use examples...

  # with valid data is ok
  iex(1)> MyApp.foo(2)
  3

  #with invalid data cause a confusing error deep inside
  iex(2)> MyApp.foo("Lucas")
  ** (ArithmeticError) bad argument in arithmetic expression: 1 + "Lucas"
    :erlang.+(1, "Lucas")
    library.ex:3: ThirdPartyLibrary.sum/2
  ```

* __Refactoring:__ To remove this code smell, client code must validate input parameters at the boundary with the user, via guard clauses or pattern matching. This will prevent errors from occurring deeply, making them easier to understand. This refactoring will also allow libraries to be implemented without worrying about creating internal protection mechanisms. The next code illustrates the refactoring of ``foo/1``, removing this smell:

  ```elixir
  defmodule MyApp do
    alias ThirdPartyLibrary, as: Library

    def foo(data) when is_integer(data) do
      #...some code...
      Library.sum(1, data)
      #...some code...
    end
  end

  #...Use examples...

  #with valid data is ok
  iex(1)> MyApp.foo(2)
  3

  # with invalid data errors are easy to locate and fix
  iex(2)> MyApp.foo("Lucas")
  ** (FunctionClauseError) no function clause matching in MyApp.foo/1    
    
    The following arguments were given to MyApp.foo/1:
    
        # 1
        "Lucas"
    
    my_app.ex:6: MyApp.foo/1
  ```

  This example is based on code provided in Elixir's official documentation. Source: [link][WorkingWithInvalidDataExample]

[▲ back to Index](#table-of-contents)
___

### Map/struct dynamic access

* __Category:__ Low-level concerns smells.

* __Problem:__ In Elixir, it is possible to access values from ``Maps``, which are key-value data structures, either strictly or dynamically. When trying to dynamically access the value of a key from a ``Map``, if the informed key does not exist, a null value (``nil``) will be returned. This return can be confusing and does not allow developers to conclude whether the key is non-existent in the ``Map`` or just has no bound value. In this way, this code smell may cause bugs in the code.

* __Example:__ The code shown below is an example of this smell. The function ``plot/1`` tries to draw a graphic to represent the position of a point in a cartesian plane. This function receives a parameter of ``Map`` type with the point attributes, which can be a point of a 2D or 3D cartesian coordinate system. To decide if a point is 2D or 3D, this function uses dynamic access to retrieve values of the ``Map`` keys:

  ```elixir
  defmodule Graphics do
    def plot(point) do
      #...some code...

      # Dynamic access to use point values
      {point[:x], point[:y], point[:z]}

      #...some code...
    end
  end

  #...Use examples...
  iex(1)> point_2d = %{x: 2, y: 3}
  %{x: 2, y: 3}

  iex(2)> point_3d = %{x: 5, y: 6, z: nil} 
  %{x: 5, y: 6, z: nil}

  iex(3)> Graphics.plot(point_2d) 
  {2, 3, nil}   # <= ambiguous return

  iex(4)> Graphics.plot(point_3d)         
  {5, 6, nil}
  ```
  
  As can be seen in the example above, even when the key ``:z`` does not exist in the ``Map`` (``point_2d``), dynamic access returns the value ``nil``. This return can be dangerous because of its ambiguity. It is not possible to conclude from it whether the ``Map`` has the key ``:z`` or not. If the function relies on the return value to make decisions about how to plot a point, this can be problematic and even cause errors when testing the code.

* __Refactoring:__ To remove this code smell, whenever a ``Map`` has keys of ``Atom`` type, replace the dynamic access to its values per strict access. When a non-existent key is strictly accessed, Elixir raises an error immediately, allowing developers to find bugs faster. The next code illustrates the refactoring of ``plot/1``, removing this smell:

  ```elixir
  defmodule Graphics do
    def plot(point) do
      #...some code...

      # Strict access to use point values
      {point.x, point.y, point.z}

      #...some code...
    end
  end

  #...Use examples...
  iex(1)> point_2d = %{x: 2, y: 3}
  %{x: 2, y: 3}

  iex(2)> point_3d = %{x: 5, y: 6, z: nil} 
  %{x: 5, y: 6, z: nil}

  iex(3)> Graphics.plot(point_2d) 
  ** (KeyError) key :z not found in: %{x: 2, y: 3} # <= explicitly warns that
    graphic.ex:6: Graphics.plot/1                  # <= the z key does not exist!

  iex(4)> Graphics.plot(point_3d)         
  {5, 6, nil}
  ```

  As shown below, another alternative to refactor this smell is to replace a ``Map`` with a ``struct`` (named map). By default, structs only support strict access to values. In this way, accesses will always return clear and objective results:

  ```elixir
  defmodule Point do
    @enforce_keys [:x, :y]
    defstruct [x: nil, y: nil]
  end

  #...Use examples...
  iex(1)> point = %Point{x: 2, y: 3}   
  %Point{x: 2, y: 3}

  iex(2)> point.x   # <= strict access to use point values
  2

  iex(3)> point.z   # <= trying to access a non-existent key
  ** (KeyError) key :z not found in: %Point{x: 2, y: 3}

  iex(4)> point[:x] # <= by default, struct does not support dynamic access 
  ** (UndefinedFunctionError) ... (Point does not implement the Access behaviour)
  ```

  These examples are based on code written by José Valim ([@josevalim][jose-valim]). Source: [link][JoseValimExamples]

[▲ back to Index](#table-of-contents)
___

### Unplanned value extraction

* __Category:__ Low-level concerns smells.

* __Problem:__ In Elixir, there are many ways to extract key-related values from a URL query string. However, when pattern matching is not used for this purpose, depending on the format of the URL query string, the code may have undesired behavior, such as being able to extract unplanned values instead of forcing a crash. This unplanned value extraction can give a false impression that the code is working correctly, causing bugs.

* __Example:__ The code shown below is an example of this smell. The function ``get_value/2`` tries to extract a value from a specific key of a URL query string. As it is not implemented using pattern matching, ``get_value/2`` always returns a value, regardless of the format of the URL query string passed as a parameter in the call. Sometimes the returned value will be valid; however, if a URL query string with an unexpected format is used in the call, ``get_value/2`` will extract incorrect values from it:

  ```elixir
  defmodule Extract do
  
    @doc """
      Extract value from a key in a URL query string.
    """
    def get_value(string, desired_key) do
      parts = String.split(string, "&")
      Enum.find_value(parts, fn pair ->
        key_value = String.split(pair, "=")
        Enum.at(key_value, 0) == desired_key && Enum.at(key_value, 1)
      end)
    end
    
  end

  #...Use examples...

  # URL query string according to with the planned format - OK!
  iex(1)> Extract.get_value("name=Lucas&university=UFMG&lab=ASERG", "lab")  
  "ASERG"

  iex(2)> Extract.get_value("name=Lucas&university=UFMG&lab=ASERG", "university")
  "UFMG"

  # Unplanned URL query string format - Unplanned value extraction!
  iex(3)> Extract.get_value("name=Lucas&university=institution=UFMG&lab=ASERG", "university")
  "institution"   # <= why not "institution=UFMG"? or only "UFMG"?
  ```

* __Refactoring:__ To remove this code smell, ``get_value/2`` can be refactored through the use of pattern matching. So, if an unexpected URL query string format is used, the function will be crash instead of returning an invalid value. This behavior, shown below, will allow clients to decide how to handle these errors and will not give a false impression that the code is working correctly when unexpected values are extracted:

  ```elixir
  defmodule Extract do

    @doc """
      Extract value from a key in a URL query string.
      Refactored by using pattern matching.
    """
    def get_value(string, desired_key) do
      parts = String.split(string, "&")
      Enum.find_value(parts, fn pair ->
        [key, value] = String.split(pair, "=") # <= pattern matching
        key == desired_key && value
      end)
    end

  end

  #...Use examples...

  # URL query string according to with the planned format - OK!
  iex(1)> Extract.get_value("name=Lucas&university=UFMG&lab=ASERG", "name")      
  "Lucas"

  # Unplanned URL query string format - Crash explaining the problem to the client!
  iex(2)> Extract.get_value("name=Lucas&university=institution=UFMG&lab=ASERG", "university")
  ** (MatchError) no match of right hand side value: ["university", "institution", "UFMG"] 
    extract.ex:7: anonymous fn/2 in Extract.get_value/2 # <= left hand: [key, value] pair
  
  iex(3)> Extract.get_value("name=Lucas&university&lab=ASERG", "university")                  
  ** (MatchError) no match of right hand side value: ["university"] 
    extract.ex:7: anonymous fn/2 in Extract.get_value/2 # <= left hand: [key, value] pair
  ```
  
  These examples are based on code written by José Valim ([@josevalim][jose-valim]). Source: [link][JoseValimExamples]

[▲ back to Index](#table-of-contents)
___

### Modules with identical names

* __Category:__ Low-level concerns smells.

* __Problem:__ This code smell is related to possible module name conflicts that can occur when a library is implemented. Due to a limitation of the Erlang VM (BEAM), also used by Elixir, only one instance of a module can be loaded at a time. If there are name conflicts between more than one module, they will be considered the same by BEAM and only one of them will be loaded. This can cause unwanted code behavior.

* __Example:__ The code shown below is an example of this smell. Two different modules were defined with identical names (``Foo``). When BEAM tries to load both simultaneously, only the module defined in the file (``module_two.ex``) stay loaded, redefining the current version of ``Foo`` (``module_one.ex``) in memory. That makes it impossible to call ``from_module_one/0``, for example:

  ```elixir
  defmodule Foo do
    @moduledoc """
      Defined in `module_one.ex` file.
    """
    def from_module_one do
      "Function from module one!"
    end
  end
  ```

  ```elixir
  defmodule Foo do
    @moduledoc """
      Defined in `module_two.ex` file.
    """
    def from_module_two do
      "Function from module two!"
    end
  end
  ```

  When BEAM tries to load both simultaneously, the name conflict causes only one of them to stay loaded:

  ```elixir
  iex(1)> c("module_one.ex")
  [Foo]

  iex(2)> c("module_two.ex")
  warning: redefining module Foo (current version defined in memory)
  module_two.ex:1
  [Foo]

  iex(3)> Foo.from_module_two()
  "Function from module two!"

  iex(4)> Foo.from_module_one()  # <= impossible to call due to name conflict
  ** (UndefinedFunctionError) function Foo.from_module_one/0 is undefined...
  ```

* __Refactoring:__ To remove this code smell, a library must standardize the naming of its modules, always using its own name as a prefix (namespace) for all its module's names (e.g., ``LibraryName.ModuleName``). When a module file is within subdirectories of a library, the names of the subdirectories must also be used in the module naming (e.g., ``LibraryName.SubdirectoryName.ModuleName``). In the refactored code shown below, this module naming pattern was used. For this, the ``Foo`` module, defined in the file ``module_two.ex``, was also moved to the ``utils`` subdirectory. This refactoring, in addition to eliminating the internal conflict of names within the library, will prevent the occurrence of name conflicts with client code:

  ```elixir
  defmodule MyLibrary.Foo do
    @moduledoc """
      Defined in `module_one.ex` file.
      Name refactored!
    """
    def from_module_one do
      "Function from module one!"
    end
  end
  ```

  ```elixir
  defmodule MyLibrary.Utils.Foo do
    @moduledoc """
      Defined in `module_two.ex` file.
      Name refactored!
    """
    def from_module_two do
      "Function from module two!"
    end
  end
  ```

  When BEAM tries to load them simultaneously, both will stay loaded successfully:

  ```elixir
  iex(1)> c("module_one.ex")   
  [MyLibrary.Foo]

  iex(2)> c("module_two.ex")   
  [MyLibrary.Utils.Foo]

  iex(3)> MyLibrary.Foo.from_module_one()
  "Function from module one!"

  iex(4)> MyLibrary.Utils.Foo.from_module_two()
  "Function from module two!"
  ```

  This example is based on the description provided in Elixir's official documentation. Source: [link][ModulesWithIdenticalNamesExample]

[▲ back to Index](#table-of-contents)
___

### Unnecessary macro

* __Category:__ Low-level concerns smells.

* __Problem:__ ``Macros`` are powerful meta-programming mechanisms that can be used in Elixir to extend the language. While implementing ``macros`` is not a code smell in itself, this meta-programming mechanism should only be used when absolutely necessary. Whenever a macro is implemented, and it was possible to solve the same problem using functions or other pre-existing Elixir structures, the code becomes unnecessarily more complex and less readable. Because ``macros`` are more difficult to implement and understand, their indiscriminate use can compromise the evolution of a system, reducing its maintainability.

* __Example:__ The code shown below is an example of this smell. The ``MyMacro`` module implements the ``sum/2`` macro to perform the sum of two numbers received as parameters. While this code has no syntax errors and can be executed correctly to get the desired result, it is unnecessarily more complex. By implementing this functionality as a macro rather than a conventional function, the code became less clear and less objective:

  ```elixir
  defmodule MyMacro do
    
    defmacro sum(v1, v2) do
      quote do
        unquote(v1) + unquote(v2)
      end
    end

  end

  #...Use examples...

  iex(1)> require MyMacro
  MyMacro

  iex(2)> MyMacro.sum(3, 5)
  8

  iex(3)> MyMacro.sum(3+1, 5+6)
  15
  ```

* __Refactoring:__ To remove this code smell, the developer must replace the unnecessary macro with structures that are simpler to write and understand, such as named functions. The code shown below is the result of the refactoring of the previous example. Basically, the ``sum/2`` macro has been transformed into a conventional named function:

  ```elixir
  defmodule MyMacro do
    
    def sum(v1, v2) do   # <= macro became a named function!
      v1 + v2
    end

  end

  #...Use examples...

  iex(1)> require MyMacro
  MyMacro

  iex(2)> MyMacro.sum(3, 5)
  8

  iex(3)> MyMacro.sum(3+1, 5+6)
  15
  ```

  This example is based on the description provided in Elixir's official documentation. Source: [link][UnnecessaryMacroExample]

[▲ back to Index](#table-of-contents)
___

### Large code generation

* __Category:__ Low-level concerns smells.

* __Note:__ This smell was suggested by the community via issues ([#13][Large-code-generation-issue]).

* __Problem:__ This code smell is related to ``macros`` that generate too much code. When a ``macro`` provides a large code generation, it impacts how the compiler or the runtime works. The reason for this is that Elixir may have to expand, compile, and execute a code multiple times, which will make compilation slower.

* __Example:__ The code shown below is an example of this smell. Imagine you are defining a router for a web application, where you could have macros like ``get/2``. On every invocation of the macro, which can be hundreds, the code inside ``get/2`` will be expanded and compiled, which can generate a large volume of code in total.

  ```elixir
  defmodule Routes do
    ...

    defmacro get(route, handler) do
      quote do
        route = unquote(route)
        handler = unquote(handler)

        if not is_binary(route) do
          raise ArgumentError, "route must be a binary"
        end

        if not is_atom(handler) do
          raise ArgumentError, "route must be a module"
        end

        @store_route_for_compilation {route, handler}
      end
    end
  end
  ```

* __Refactoring:__ To remove this code smell, the developer must simplify the ``macro``, delegating to other functions part of its work. As shown below, by encapsulating in the function ``__define__/3`` the functionality pre-existing inside the ``quote``, we reduce the code that is expanded and compiled on every invocation of the ``macro``, and instead we dispatch to a function to do the bulk of the work.

  ```elixir
  defmodule Routes do
    ...

    defmacro get(route, handler) do
      quote do
        Routes.__define__(__MODULE__, unquote(route), unquote(handler))
      end
    end

    def __define__(module, route, handler) do
      route = unquote(route)
      handler = unquote(handler)

      if not is_binary(route) do
        raise ArgumentError, "route must be a binary"
      end

      if not is_atom(handler) do
        raise ArgumentError, "route must be a module"
      end

      Module.put_attribute(module, :store_route_for_compilation, {route, handler})
    end
  end
  ```

  This example and the refactoring are proposed by José Valim ([@josevalim][jose-valim])

[▲ back to Index](#table-of-contents)
___

### App configuration for code libs

* __Category:__ Low-level concerns smells.

* __Problem:__ The ``Application Environment`` <sup>[link][ApplicationEnvironment]</sup> is a global configuration mechanism and therefore can be used to parameterize values that will be used in several different places in a system implemented in Elixir. This parameterization mechanism can be very useful and therefore is not considered a code smell by itself. However, when ``Application Environments`` are used as a mechanism for configuring a library's functions, this can make these functions less flexible, making it impossible for a library-dependent application to reuse its functions with different behaviors in different places in the code. Libraries are created to foster code reuse, so this kind of limitation imposed by global configurations can be problematic in this scenario.

* __Example:__ The ``DashSplitter`` module represents a library that configures the behavior of its functions through the global ``Application Environment`` mechanism. These configurations are concentrated in the ``config/config.exs`` file, shown below:

  ```elixir
  import Config

  config :app_config,
    parts: 3

  import_config "#{config_env()}.exs"
  ```

  One of the functions implemented by the ``DashSplitter`` library is ``split/1``. This function has the purpose of separating a string received via parameter into a certain number of parts. The character used as a separator in ``split/1`` is always ``"-"`` and the number of parts the string is split into is defined globally by the ``Application Environment``. This value is retrieved by the ``split/1`` function by calling ``Application.fetch_env!/2``, as shown next:

  ```elixir
  defmodule DashSplitter do
    def split(string) when is_binary(string) do
      parts = Application.fetch_env!(:app_config, :parts) # <= retrieve global config
      String.split(string, "-", parts: parts)             # <= parts: 3
    end
  end
  ```

  Due to this type of global configuration used by the ``DashSplitter`` library, all applications dependent on it can only use the ``split/1`` function with identical behavior in relation to the number of parts generated by string separation. Currently, this value is equal to 3, as we can see in the use examples shown below:

  ```elixir
  iex(1)> DashSplitter.split("Lucas-Francisco-Vegi")
  ["Lucas", "Francisco", "Vegi"]

  iex(2)> DashSplitter.split("Lucas-Francisco-da-Matta-Vegi")
  ["Lucas", "Francisco", "da-Matta-Vegi"]
  ```

* __Refactoring:__ To remove this code smell and make the library more adaptable and flexible, this type of configuration must be performed via parameters in function calls. The code shown below performs the refactoring of the ``split/1`` function by adding a new optional parameter of type ``Keyword list``. With this new parameter it is possible to modify the default behavior of the function at the time of its call, allowing multiple different ways of using ``split/2`` within the same application:

  ```elixir
  defmodule DashSplitter do
    def split(string, opts \\ []) when is_binary(string) and is_list(opts) do
      parts = Keyword.get(opts, :parts, 2) # <= default config of parts == 2
      String.split(string, "-", parts: parts)
    end
  end

  #...Use examples...

  iex(1)> DashSplitter.split("Lucas-Francisco-da-Matta-Vegi", [parts: 5])
  ["Lucas", "Francisco", "da", "Matta", "Vegi"]

  iex(2)> DashSplitter.split("Lucas-Francisco-da-Matta-Vegi") #<= default config is used!
  ["Lucas", "Francisco-da-Matta-Vegi"]  
  ```
  
  These examples are based on code provided in Elixir's official documentation. Source: [link][AppConfigurationForCodeLibsExample]

[▲ back to Index](#table-of-contents)
___

### Compile-time app configuration

* __Category:__ Low-level concerns smells.

* __Problem:__ As explained in the description of [App configuration for code libs](#app-configuration-for-code-libs), the ``Application Environment`` can be used to parameterize values in an Elixir system. Although it is not a good practice to use this mechanism in the implementation of libraries, sometimes this can be unavoidable. If these parameterized values are assigned to ``module attributes``, it can be especially problematic. As ``module attribute`` values are defined at compile-time, when trying to assign ``Application Environment`` values to these attributes, warnings or errors can be triggered by Elixir. This happens because, when defining module attributes at compile time, the ``Application Environment`` is not yet available in memory.

* __Example:__ The ``DashSplitter`` module represents a library. This module has an attribute ``@parts`` that has its constant value defined at compile-time by calling ``Application.fetch_env!/2``. The ``split/1`` function, implemented by this library, has the purpose of separating a string received via parameter into a certain number of parts. The character used as a separator in ``split/1`` is always ``"-"`` and the number of parts the string is split into is defined by the module attribute ``@parts``, as shown next:

  ```elixir
  defmodule DashSplitter do
    @parts Application.fetch_env!(:app_config, :parts) # <= define module attribute 
                                                          # at compile-time
    def split(string) when is_binary(string) do
      String.split(string, "-", parts: @parts) #<= reading from a module attribute
    end

  end
  ```

  Due to this compile-time configuration based on the ``Application Environment`` mechanism, Elixir can raise warnings or errors, as shown next, during compilation:

  ```elixir
  warning: Application.fetch_env!/2 is discouraged in the module body,
  use Application.compile_env/3 instead...

  ** (ArgumentError) could not fetch application environment :parts
  for application :app_config because the application was not loaded nor
  configured
  ```

* __Refactoring:__ To remove this code smell, when it is really unavoidable to use the ``Application Environment`` mechanism to configure library functions, this should be done at runtime and not during compilation. That is, instead of calling ``Application.fetch_env!(:app_config, :parts)`` at compile-time to set ``@parts``, this function must be called at runtime within ``split/1``. This will mitigate the risk that ``Application Environment`` is not yet available in memory when it is necessary to use it. Another possible refactoring, as shown below, is to replace the use of the ``Application.fetch_env!/2`` function to define ``@parts``, with the ``Application.compile_env/3``. The third parameter of ``Application.compile_env/3`` defines a default value that is returned whenever that ``Application Environment`` is not available in memory during the definition of ``@parts``. This prevents Elixir from raising an error at compile-time:

  ```elixir
  defmodule DashSplitter do
    @parts Application.compile_env(:app_config, :parts, 3) # <= default value 3 prevents an error! 
                                                      
    def split(string) when is_binary(string) do
      String.split(string, "-", parts: @parts) #<= reading from a module attribute
    end

  end
  ```
  
  These examples are based on code provided in Elixir's official documentation. Source: [link][AppConfigurationForCodeLibsExample]

* __Remark:__ This code smell can be detected by [Credo][Credo], a static code analysis tool. During its checks, Credo raises this [warning][CredoWarningApplicationConfigInModuleAttribute] when this smell is found.

[▲ back to Index](#table-of-contents)
___

### Dependency with "use" when an "import" is enough

* __Category:__ Low-level concerns smells.

* __Problem:__ Elixir has mechanisms such as ``import``, ``alias``, and ``use`` to establish dependencies between modules. Establishing dependencies allows a module to call functions from other modules, facilitating code reuse. A code implemented with these mechanisms does not characterize a smell by itself; however, while the ``import`` and ``alias`` directives have lexical scope and only facilitate that a module to use functions of another, the ``use`` directive has a broader scope, something that can be problematic. The ``use`` directive allows a module to inject any type of code into another, including propagating dependencies. In this way, using the ``use`` directive makes code readability worse, because to understand exactly what will happen when it references a module, it is necessary to have knowledge of the internal details of the referenced module.

* __Example:__ The code shown below is an example of this smell. Three different modules were defined -- ``ModuleA``, ``Library``, and ``ClientApp``. ``ClientApp`` is reusing code from the ``Library`` via the ``use`` directive, but is unaware of its internal details. Therefore, when ``Library`` is referenced by ``ClientApp``, it injects into ``ClientApp`` all the content present in its ``__using__/1`` macro. Due to the decreased readability of the code and the lack of knowledge of the internal details of the ``Library``, ``ClientApp`` defines a local function ``foo/0``. This will generate a conflict as ``ModuleA`` also has a function ``foo/0``; when ``ClientApp`` referenced ``Library`` via the ``use`` directive, it has a dependency for ``ModuleA`` propagated to itself:

  ```elixir
  defmodule ModuleA do
    def foo do
      "From Module A"
    end
  end
  ```

  ```elixir
  defmodule Library do
    defmacro __using__(_opts) do
      quote do
        import ModuleA  # <= propagating dependencies!

        def from_lib do
          "From Library"
        end
      end
    end

    def from_lib do
      "From Library"
    end
  end
  ```

  ```elixir
  defmodule ClientApp do
    use Library

    def foo do
      "Local function from client app"
    end

    def from_client_app do
      from_lib() <> " - " <> foo()
    end

  end
  ```

  When we try to compile ``ClientApp``, Elixir will detect the conflict and throw the following error:

  ```elixir
  iex(1)> c("client_app.ex") 

  ** (CompileError) client_app.ex:4: imported ModuleA.foo/0 conflicts with local function
  ```

* __Refactoring:__ To remove this code smell, it may be possible to replace ``use`` with ``alias`` or ``import`` when creating a dependency between an application and a library. This will make code behavior clearer, due to improved readability. In the following code, ``ClientApp`` was refactored in this way, and with that, the conflict as previously shown no longer exists:

  ```elixir
  defmodule ClientApp do
    import Library

    def foo do
      "Local function from client app"
    end

    def from_client_app do
      from_lib() <> " - " <> foo()
    end

  end

  #...Uses example...

  iex(1)> ClientApp.from_client_app()
  "From Library - Local function from client app"
  ```

  These examples are based on code provided in Elixir's official documentation. Source: [link][DependencyWithUseExample]

[▲ back to Index](#table-of-contents)

## About

This catalog was proposed by Lucas Vegi and Marco Tulio Valente, from [ASERG/DCC/UFMG][ASERG].

For more info see the following paper:

* [Code Smells in Elixir: Early Results from a Grey Literature Review][preprint-copy], International Conference on Program Comprehension (ICPC), 2022.

Please feel free to make pull requests and suggestions ([Issues][Issues] tab).

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
[UnsupervisedProcessExample]: https://hexdocs.pm/elixir/master/library-guidelines.html#avoid-spawning-unsupervised-processes
[Supervisor]: https://hexdocs.pm/elixir/master/Supervisor.html
[Discussions]: https://github.com/lucasvegi/Elixir-Code-Smells/discussions
[Issues]: https://github.com/lucasvegi/Elixir-Code-Smells/issues
[LargeMessageExample]: https://samuelmullen.com/articles/elixir-processes-send-and-receive/
[Agent]: https://hexdocs.pm/elixir/1.13/Agent.html
[Task]: https://hexdocs.pm/elixir/1.13/Task.html
[GenServer]: https://hexdocs.pm/elixir/1.13/GenServer.html
[AgentObsessionExample]: https://elixir-lang.org/getting-started/mix-otp/agent.html#agents
[ElixirInProduction]: https://elixir-companies.com/
[WorkingWithInvalidDataExample]: https://hexdocs.pm/elixir/master/library-guidelines.html#avoid-working-with-invalid-data
[ModulesWithIdenticalNamesExample]: https://hexdocs.pm/elixir/master/library-guidelines.html#avoid-defining-modules-that-are-not-in-your-namespace
[UnnecessaryMacroExample]: https://hexdocs.pm/elixir/master/library-guidelines.html#avoid-macros
[ApplicationEnvironment]: https://hexdocs.pm/elixir/1.13/Config.html
[AppConfigurationForCodeLibsExample]: https://hexdocs.pm/elixir/master/library-guidelines.html#avoid-application-configuration
[CredoWarningApplicationConfigInModuleAttribute]: https://hexdocs.pm/credo/Credo.Check.Warning.ApplicationConfigInModuleAttribute.html
[Credo]: https://hexdocs.pm/credo/overview.html
[DependencyWithUseExample]: https://hexdocs.pm/elixir/master/library-guidelines.html#avoid-use-when-an-import-is-enough
[ICPC-ERA]: https://conf.researchr.org/track/icpc-2022/icpc-2022-era
[preprint-copy]: https://doi.org/10.48550/arXiv.2203.08877
[jose-valim]: https://github.com/josevalim
[syamilmj]: https://github.com/syamilmj
[Complex-extraction-in-clauses-issue]: https://github.com/lucasvegi/Elixir-Code-Smells/issues/9
[Alternative-return-type-issue]: https://github.com/lucasvegi/Elixir-Code-Smells/issues/6
[Complex-else-clauses-in-with-issue]: https://github.com/lucasvegi/Elixir-Code-Smells/issues/7
[Large-code-generation-issue]: https://github.com/lucasvegi/Elixir-Code-Smells/issues/13
