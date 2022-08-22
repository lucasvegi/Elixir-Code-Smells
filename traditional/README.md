# [Catalog of Traditional Code Smells in Elixir][Traditional Smells]

[![GitHub last commit](https://img.shields.io/github/last-commit/lucasvegi/Elixir-Code-Smells)](https://github.com/lucasvegi/Elixir-Code-Smells/commits/main)

## Table of Contents

* __[Traditional code smells](#traditional-code-smells)__
  * [Comments](#comments)
  * [Long Parameter List](#long-parameter-list)
  * [Long Function](#long-function)
  * [Primitive Obsession](#primitive-obsession)
  * [Shotgun Surgery](#shotgun-surgery)
  * [Duplicated Code](#duplicated-code)
  * [Feature Envy](#feature-envy)
  * [Divergent Change](#divergent-change)
  * [Inappropriate Intimacy](#inappropriate-intimacy)
  * [Large Class](#large-class)
  * [Speculative Generality](#speculative-generality)
  * [Switch Statements](#switch-statements)
* __[Elixir-specific code smells][Elixir Smells]__

## Traditional code smells

[Fowler and Beck][FowlerAndBeckCatalog] coined the term *__code smell__* to name suboptimal code structures that can harm software maintenance and evolution. In addition to coining the term, they cataloged 22 traditional code smell. Although traditional code smells were proposed in the nineties for the object-oriented programming paradigm, some of them are also discussed in the Elixir context nowadays. In this section, 12 different traditional smells are explained and exemplified in this context. We present these smells using the following structure for each one:

* __Name:__ Unique identifier of the code smell. This name is important to facilitate communication between developers;
* __Problem:__ How the code smell can harm code quality and the impacts it can have on software maintenance, comprehension, and evolution;
* __Example:__ Code and textual descriptions to illustrate the occurrence of the code smell;

[▲ back to Index](#table-of-contents)

___

### Comments

* __Problem:__ This smell occurs when a ``function`` is documented using explanatory comments instead of ``@doc``.

* __Example:__

  ```elixir
  defmodule ModuleA do
    #@doc """
    #  construct for documentation not used!
    #"""
    def foo do
      # explanatory comments used for documentation
      ...
      ...
      # explanatory comments used for documentation
      ...
      ...
    end
  end
  ```

[▲ back to Index](#table-of-contents)
___

### Long Parameter List

* __Problem:__ In a functional language like Elixir, ``functions`` tend to be pure and therefore do not access or manipulate values outside its scopes. Since the input values of these ``functions`` are just their parameters, it is natural to expect that ``functions`` with a long list of parameters be created to keep them pure. However, when this list has <u>more than three or four parameters and doesn't use abstractions</u> (e.g., ``struct``) to decrease this amount, these ``function`` interfaces become confusing and prone to errors during use.

* __Example:__
  
  ```elixir
  defmodule Library do
    def loan(user_name, email, password, user_alias, book_name, book_ed, active) do
      # ... loan/7
      # ... too many parameters that can be grouped in structs!
    end
  end
  ```

[▲ back to Index](#table-of-contents)
___

### Long Function

* __Problem:__ Poorly cohesive ``function``, made up of too many lines of code that group together many different responsibilities that could be separated into multiple smaller functions with a single responsibility each. Generally, <u>any function longer than ten lines should make you start asking questions</u>.

* __Example:__ ``print/2`` is a long function (low-cohesion), so is necessary to separate it in blocks and add comments to understand. This is a bad practice.
  
  ```elixir
  defmodule Report do
    def print(user, purchase_order) do
      # Company data 
      print_company_data()

      # User data
      IO.puts("Name: #{user.first_name} #{user.last_name}")
      
      # Order data (with filters and calculations)
      purchase_order.items
      |> Enum.filter(&(&1.status == 3))
      |> Enum.map(fn item ->
        IO.puts("Item: #{item.name}")
        IO.puts("Price: #{item.price}")
        IO.puts("Amount: #{item.amount}")
        total = item.price * item.amount
        IO.puts("Total: #{total}")
      end)
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)
___

### Primitive Obsession

* __Problem:__ This code smell can be felt when Elixir basic types (e.g., ``integer``, ``float``, and ``string``) are abusively used in function parameters and code variables, rather than creating specific composite data types (e.g., ``protocols``, ``structs``, and ``@type``) that can better represent a domain.

* __Example:__ Use a ``float`` value to represent ``Money`` or use a ``string`` to represent an ``Address``. ``Money`` and ``Address`` are more complex structures than a simple primitive value.

[▲ back to Index](#table-of-contents)
___

### Shotgun Surgery

* __Problem:__ Code with responsibilities spread across many Elixir ``modules``, so to perform any modifications in it requires that you make many small changes to many different ``modules`` at the same time. These code are susceptible to errors, because during these changes, some of these several ``modules`` that must be modified, eventually may be forgotten and remain unchanged, producing incorrect behavior.

* __Example:__ Imagine the scenario of an e-commerce, where depending on the type of user's subscription, special shipping conditions, discounts and subscription renewal fees are charged. In the two modules below (``ShoppingCart`` and ``Subscription``), only two signature types are handled (``id: 3`` and ``id: 4``), however, if a new signature type is created (``id: 8``), many small changes in different parts of these two modules will need to be performed to meet this new single requirement. This happens due to the spreading of responsibilities of a feature by the code.

  ```elixir
  defmodule ShoppingCart do
    def calculate_shipping(zip_code, %{id: 3}), do: 0.0
    def calculate_shipping(zip_code, %{id: 4}), do: 0.0
    # def calculate_shipping(zip_code, %{id: 8}), do: 0.0    <-- small change
    
    def calculate_shipping(zip_code, _) do
      10.0 * Location.calculate(zip_code)
    end

    def apply_discount(total, %{id: 3}),
      do: total * 0.95
    
    def apply_discount(total, %{id: 4}),
      do: total * 0.9

    #def apply_discount(total, %{id: 8}),                  <-- small change
    #  do: total * 0.85
    
    def apply_discount(total, _),
      do: total
  end
  ```

  ```elixir
  defmodule Subscription do
    def renew(%{id: id}, user) do
      case id do
        3 -> Billing.perform(user, id, 100.0)
        4 -> Billing.perform(user, id, 95.0)
        #8 -> Billing.perform(user, id, 90.0)               <-- small change
      end
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)
___

### Duplicated Code

* __Problem:__ This smells occurs <u>when two or more code fragments look almost identical</u>. Duplicated code can cause maintenance issues especially when it needs to be changed. Since multiple code fragments will have to be updated, there is the risk that one of them will not be changed, causing unwanted system behavior.

* __Example:__

  ```elixir
  defmodule ShoppingCart do
    def calculate_shipping(zip_code, subscription) do
      if (Enum.member?([3, 4], subscription.id)) do     # <-- duplicated code!
        0
      else
        10.0 * Location.calculate(zip_code)
      end
    end

    def apply_discount(total, subscription) do
      if (Enum.member?([3, 4], subscription.id)) do     # <-- duplicated code!
        total * 0.9
      else
        total
      end
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)
___

### Feature Envy

* __Problem:__ This occurs when a ``function`` accesses more data or calls more functions from another ``module`` different from its own. The presence of this smell can make a ``module`` less cohesive and increase code coupling.

* __Example:__ In the following code, all the data used in the ``calculate_total_item/1`` function comes from the ``OrderItem`` module. So if ``calculate_total_item/1`` were moved to ``OrderItem``, the ``Order`` module could become more cohesive and the coupling would decrease.

  ```elixir
  defmodule Order do
    def calculate_total_item(id) do
      item = OrderItem.find_item(id)
      total = (item.price + item.taxes) * item.amount
      discount = OrderItem.find_discount(item)

      unless is_nil(discount) do    # <-- all data comes from OrderItem!
        total - total * discount
      else
        total
      end
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)
___

### Divergent Change

* __Problem:__ This code smell is the opposite of [Shotgun Surgery](#shotgun-surgery). While in Shotgun Surgery many different ``modules`` need to be modified at the same time to complete a single code change, in Divergent Change a single ``module`` may need to be modified constantly, in multiple parts, for unrelated reasons. Modules that bundle together many ``functions`` that do not share a common goal are a cause of Divergent Change.

* __Example:__ ``Account`` module has at least two different and unrelated reasons that may justify modifications to this module. This smell can be removed by creating new cohesive modules and moving related functions into them.

  ```elixir
  defmodule Account do
    # Reason to modify (1): Sign-in policies!
    def signin_with_google(google_data) do
      # ...
    end
    def signin_with_apple(apple_data) do
      # ...
    end

    # Reason to modify (2): Billing policies!
    def charge_subscription(id) do
      # ...
    end
    def calculate_subscription_discount(id) do
      # ...
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)

___

### Inappropriate Intimacy

* __Problem:__ In Elixir, this code smell can be felt in ``impure functions``. These functions can access internal values of other ``modules`` that are not received via parameters, <u>generating excessive coupling</u>. The values accessed by impure functions of a ``module`` “A”, can be internal details of a ``module`` “B”, obtained by calling functions of ``module`` “B”, inside functions of ``module`` “A”.

* __Example:__ ``Order.charge/2`` function is impure. This function creates an overly tight coupling because it knows internal details that should be encapsulated in the ``User``, ``Card``, and ``Gateway`` modules.

  ```elixir
  defmodule Order do
    def charge(total, user) do
      card = User.find_credit_card(user)          # <-- access to internal details!
      if (card.status == 3) do
        gateway = Card.find_payment_gateway(card) # <-- access to internal details!
        Gateway.charge(gateway, card, total)      # <-- rule should be encapsulated!
      end
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)
___

### Large Class

* __Problem:__ Although Elixir does not support classes, ``functions`` can be grouped by ``modules`` in a similar way. When a ``module`` is not cohesive, it deals with multiple distinct business rules, tending to have <u>many functions and lines of code, becoming large</u>. This makes maintenance difficult. [Duplicated code](#duplicated-code) can contribute to the increase in the size of the modules, thus showing that some code smells can also be related.

* __Example:__ ``ShoppingCart`` module is unnecessarily large due to its lack of cohesion. It groups functions for many distinct and not directly related business rules. Therefore, these functions could be extracted to other modules, thus increasing the overall cohesion of the system.

  ```elixir
  defmodule ShoppingCart do
    # Rule 1
    def calculate_total(items, subscription) do
      # ...
    end
    
    # Rule 2
    def calculate_shipping(zip_code, %{id: 3}), do: 0.0
    def calculate_shipping(zip_code, %{id: 4}), do: 0.0
    def calculate_shipping(zip_code, _), do
      10.0 * Location.calculate(zip_code)
    end
    
    # Rule 3
    def apply_discount(total, %{id: 3}), do: total * 0.9
    def apply_discount(total, %{id: 4}), do: total * 0.9
    def apply_discount(total, _), do: total

    # Rule 4
    def send_message_subscription(%{id: 3}, _), do: nil
    def send_message_subscription(%{id: 4}, _), do: nil
    def send_message_subscription(subscription, user),
      do: Subscription.enviar_email_upgrade(subscription, user)
    
    # Rule 5
    def print(user, order) do
      # ...
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)
___

### Speculative Generality

* __Problem:__ This occurs when a code has fragments that were implemented in order to give it flexibility in future evolutions, but in practice they end up not being useful because they are never used. In Elixir, this smell can be felt in ``modules`` not used anywhere in the code, ``functions`` that are never called or even in functions with ``parameters`` defined with default values and which do not have calls that inform different values for these parameters. Code with this smell is bulkier and unnecessarily more difficult to maintain.

* __Example:__ ``apply_discount/1`` function performs an extraction on a struct ``%Product{}`` received via a parameter to obtain its ``category``. When this extraction was designed, the objective was to make ``apply_discount/1`` more flexible for future evolutions, facilitating the application of different discounts according to the category of each product. In practice, this speculation was unnecessary because the system always applied the same discount percentage for all product categories.

  ```elixir
  defmodule ShoppingCart do
    def apply_discount(%{category: category} = product) do
      case category do
        _ -> product.price * 0.8  # <-- Speculative Generality!
      end
    end
  end
  ```

  This example is based on code written by Elaine Watanabe. Source: [link][ElaineYoutube]

[▲ back to Index](#table-of-contents)
___

### Switch Statements

* __Problem:__ It can be felt when the same sequence of conditional statements, whether via ``if/else``, ``case``, ``cond`` or ``with`` appear duplicated by the code, forcing changes in multiple parts of the code whenever a new check needs to be added to these sequences of conditional statements. This smell has relationships with others, such as [Duplicated Code](#duplicated-code) and [Shotgun Surgery](#shotgun-surgery).

[▲ back to Index](#table-of-contents)

<!-- Links -->
[Traditional Smells]: https://github.com/lucasvegi/Elixir-Code-Smells/tree/main/traditional
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
[ICPC22-PDF]: https://github.com/lucasvegi/Elixir-Code-Smells/blob/main/etc/Code-Smells-in-Elixir-ICPC22-Lucas-Vegi.pdf
[ICPC22-YouTube]: https://youtu.be/3X2gxg13tXo
[Podcast-Spotify]: http://elixiremfoco.com/episode?id=lucas-vegi-e-marco-tulio
[to_atom]: https://hexdocs.pm/elixir/String.html#to_atom/1
[to_existing_atom]: https://hexdocs.pm/elixir/String.html#to_existing_atom/1
[Finbits]: https://www.finbits.com.br/
[ResearchWithElixir]: http://pesquisecomelixir.com.br/
[FowlerAndBeckCatalog]: https://books.google.com.br/books?id=UTgFCAAAQBAJ
[ElaineYoutube]: https://youtu.be/3-1PCurON4Q
