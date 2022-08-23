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

[Fowler and Beck][FowlerAndBeckCatalog] coined the term *__code smell__* to name suboptimal code structures that can harm software maintenance and evolution. In addition to coining the term, they cataloged 22 traditional code smell. Although these smells were proposed in the nineties for the object-oriented programming paradigm, some of them are also discussed in the Elixir context nowadays. In this section, 12 traditional smells are explained and exemplified in this context.

We present these smells using the following structure for each one:

* __Name:__ A name is important to facilitate communication between developers;
* __Problem:__ How the code smell can harm code quality and the impacts it can have on software maintenance, comprehension, and evolution;

[▲ back to Index](#table-of-contents)

___

### Comments

* __Problem:__ This smell occurs when a ``function`` is documented using explanatory comments instead of ``@doc``.

[▲ back to Index](#table-of-contents)
___

### Long Parameter List

* __Problem:__ In a functional language like Elixir, ``functions`` tend to be pure and therefore do not access or manipulate values outside their scopes. Since the input values of these ``functions`` are just their parameters, it is natural to expect that ``functions`` with a long list of parameters be created to keep them pure. However, when this list has <u>more than three or four parameters</u>, the function's interface becomes confusing and prone to errors during use.

[▲ back to Index](#table-of-contents)
___

### Long Function

* __Problem:__ Poorly cohesive ``function``, made up of too many lines of code that group together many different responsibilities that could be separated into smaller functions with a single responsibility each. Generally, <u>any function longer than ten lines should make you start asking questions</u>.

[▲ back to Index](#table-of-contents)
___

### Primitive Obsession

* __Problem:__ This code smell can be felt when Elixir basic types (e.g., ``integer``, ``float``, and ``string``) are abusively used in function parameters and code variables, rather than creating specific composite data types (e.g., ``protocols``, ``structs``, and ``@type``) that can better represent a domain.

[▲ back to Index](#table-of-contents)
___

### Shotgun Surgery

* __Problem:__ Code with responsibilities spread across many Elixir ``modules``, so that modifications require many small changes to many different ``modules`` at the same time. These changes are susceptible to errors, since they may be forgotten, producing incorrect behavior.

[▲ back to Index](#table-of-contents)
___

### Duplicated Code

* __Problem:__ This smell occurs <u>when two or more code fragments look almost identical</u>. Duplicated code can cause maintenance issues especially when changes are needed. Since multiple code fragments will have to be updated, there is the risk that one of them will not be changed, causing unwanted system behavior.

[▲ back to Index](#table-of-contents)
___

### Feature Envy

* __Problem:__ This smell occurs when a ``function`` accesses more data or calls more functions from another ``module`` than from its own. The presence of this smell can make a ``module`` less cohesive and increase code coupling.

[▲ back to Index](#table-of-contents)
___

### Divergent Change

* __Problem:__ This code smell is the opposite of [Shotgun Surgery](#shotgun-surgery). While in Shotgun Surgery many ``modules`` need to be modified at the same time to complete a single code change, in Divergent Change a single ``module`` is modified constantly, in multiple parts, due to unrelated reasons. Modules that bundle together many ``functions`` that do not share a common goal are a cause of Divergent Change.

[▲ back to Index](#table-of-contents)

___

### Inappropriate Intimacy

* __Problem:__ In Elixir, this code smell can be felt in ``impure functions``. These functions can access internal values of other ``modules`` that are not received via parameters, <u>generating excessive coupling</u>. Particularly, the values accessed by impure functions of a ``module`` “A”, can be internal details of a ``module`` “B”, obtained by calling functions of ``module`` “B”, inside functions of ``module`` “A”.

[▲ back to Index](#table-of-contents)
___

### Large Class

* __Problem:__ Although Elixir does not support classes, ``functions`` can be grouped by ``modules`` in a similar way. When a ``module`` is not cohesive, it deals with multiple distinct business rules, tending to have <u>many functions and lines of code, becoming large</u>. This makes maintenance difficult.

[▲ back to Index](#table-of-contents)
___

### Speculative Generality

* __Problem:__ This smell occurs when a code has fragments that were implemented in order to give it flexibility in the future, but in practice they end up not being useful because they are never used. In Elixir, this smell can be felt in ``modules`` not used anywhere in the code, ``functions`` that are never called or even in functions with ``parameters`` defined with default values and which do not have calls that inform different values for these parameters. Code with this smell is unnecessarily large and more difficult to maintain.

[▲ back to Index](#table-of-contents)
___

### Switch Statements

* __Problem:__ It can be felt when the same sequence of conditional statements, whether via ``if/else``, ``case``, ``cond`` or ``with`` appear duplicated by the code, forcing changes in multiple parts of the code whenever a new check needs to be added to their conditional statements.

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
