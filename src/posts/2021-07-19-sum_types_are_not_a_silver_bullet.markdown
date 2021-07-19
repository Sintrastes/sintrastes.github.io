---
title: "Sum types are not a silver bullet: Why you shouldn't always reach for that sealed class."
author: Nathan Bedell
tags: haskell, kotlin
---

In Kotlin, the notion of a *sealed class* (or, more recently, in Kotlin 1.5, that of a *sealed interface*) is a mechanism for limiting the inheritance of a class (or interface)
 to one of a fixed number of cases. Together with *data classes*, this can be used to emulate what is known in the functional programming community as *algebraic data types*,
 often abbreviated ADT (much to the chagrin of those who might also abbreviate *abstract data type* as ADT). These algebraic data types are the combination of *product types*, and *sum types* (which correspond to Kotlin's sealed classes).
 
In recent years, this feature has found its way into more and more
 traditional OOP and imperative languages: Rust, Swift, Kotlin -- heck, even Java 15 -- all have a form of these "algebraic data types", and so the comments of this blog post
 will apply to any of those languages, as well as to more traditional functional languages supporting algebraic data types such as Haskell, ML, OCaml, F#, and Scala. 
 
In this post I'll argue that in both cases these algebraic data types have the potential to be overused, and give an example of an anti-pattern that can arise with an over-eager use of sum types that I've decided to call "The product of sums trap". I've definitely fallen into this trap myself, so I wanted to share some advice on when using sum types might be a mistake. But first, I'd like to cover a bit of background into the mathematics of algebraic data types.
 If you already are familiar with algebraic data types and their mathematical underpinning, or if you'd simply prefer to get into the meat of the post
 and some practical examples, you might want to start from [here](#why-are-adts-good)
 
Aside: Putting the "Algebraic" into ADTs:
---------------------------------- 
 
Why are they called *algebraic* data types? Well, the notion (like many notions in the typed FP community) comes from *category theory*, which [Steve Awodey](https://www.youtube.com/watch?v=BF6kHD1DAeU) 
 sometimes likes to describe as the *abstract algebra of functions*. Now, before you run off, I should say: You do not need to understand category theory to understand this post. I simply introduce
 the idea below briefly for some context in understanding what I mean by "product of sums" in my analogy.

For those not familiar, whereas primary school algebra focuses on *computations* and *algorithms* in a particular algebraic system,
 abstract algebra is the study of *algebraic structures* themselves, and the sets of rules that define them. For instance, even back in primary school, you probably learned
 the rules:

::: mathblock
 1. For all real numbers x, y, and z: $(x + y) + z = x + (y + z)$
 2. For all real numbers x and y: $x \times y = y \times x$
::: 
 
I won't list them all here, but the ones you learned are technically called the *field laws* of the real numbers, stating that the real numbers
 satisfy all the properties of the algebraic structure known as a "field".
 
To add some more detail to Awodey's characterization of category theory, I'd like to say further that whereas *abstract algebra* is the study of *algebraic operations*
 (such as `+, *, -`) and *equations*, category theory is the study of *operations on types* (in category theory we would say *objects*) and *functions* (more specifically, *isomorphisms*).
 
An isomorphism $f : X \rightarrow Y$ (restricting myself here to to case of types and functions) is simply a function that has an inverse -- that is, a function $g : Y \rightarrow X$ such that:

::: mathblock
 1. For all x of type X: $g(f(x)) = x$
 2. For all x of type Y: $f(g(x)) = x$
::: 
 
We say that two types are "isomorphic" and write: $X \equiv Y$ if there exists an isomorphism between them. I think a good intuition for this is that two types
 being isomorphic means that they are "essentially the same", or "two different presentations of the same data". Given this, I can finally explain why
 algebraic data types are -- algebraic.
 
One way of thinking about algebraic data types is that they can be implemented in terms of two "type operators" -- $+$ and $\times$. These type operators
 then obey very similar laws to the ones we are familiar with from elementary arithmetic, but where equality is replaced with isomorphism:
 
::: mathblock
 1. For all types X, Y, and Z: $(X + Y) + Z \equiv X + (Y + Z)$
 2. For all types X and Y: $X \times Y \equiv Y \times X$
::: 
 
We can define these types in Kotlin as follows: 
 
```kotlin
data class Product<A,B>(val first: A, val second: B)

sealed class Sum<A,B> {
  data class InL<A,B>(val value: A): Sum<A,B>()
  data class InR<A,B>(val value: B): Sum<A,B>()
}
```

You may recognize the `Product` type as being essentially the same as Kotlin's `Pair<A,B>` -- and if you did, you're already
 getting the hang of the concept of an *isomorphism*.
 
 ```kotlin
 fun productToPair(product: Product<A,B>): Pair<A,B> {
     return Pair(product.first, product.second)
 }
 
 fun pairToProduce(pair: Pair<A,B>): Product<A,B> {
     return Product(pair.first, pair.second)
 }
 ```
 
 You may also recognize the `Sum<A,B>` I've defined here as being isomorphic to the `Either<A,B>` type defined in [arrow](https://arrow-kt.io/docs/0.10/apidocs/arrow-core-data/arrow.core/-either/).
 
Why are ADTs good?
------------------

Before getting into the problems that can arise for maintainability when making use of sum types, I'd like first to
 provide a positive example of how sum types can be good.
 
If you've taken a course in algorithms and data structures, and haven't been lucky enough to work in a language
 with sum types, you've probably written code like this before:

```kotlin
open class BinaryTree<A> {
    val node: A
    val left: BinaryTree<A>?
    val right BinaryTree<A>?
}
```

This works pretty well. This is a binary tree with a value of type `A` at each point of the tree,
 where each tree can have possibly a left sub-tree, and possibly a right sub-tree.
 
What if we wanted to model a binary tree where values are only stored in the leaves? We might try making
 use of inheritance to encode the two separate cases then:
 
```kotlin 
open class BinaryTree<A>

class Branch<A>(
  val left: BinaryTree<A>?
  val right: BinaryTree<A>?
): BinaryTree<A>()

class Leaf<A>(val node: A): BinaryTree<A>()
```

I use the `open` keyward here to enable inheritance, but this sort of thing would be possible
 by default in Java or C++. 
 
Consider what would happen if we wanted to write a function on such a tree. I'll write an incredibly simple (non-recursive) one
 for illustration purposes:

```kotlin
/** Print some diagnostic information about a binary tree*/
fun peek(tree: BinaryTree<Int>): String =
    when(tree) {
        is Branch -> {
            "This is a branch."
        }
        is Leaf -> {
            "This is a leaf with value ${tree.node}."
        }
        -- We have to put this here, or the compiler yells at us.
        else -> throw IllegalStateException("UNREACHABLE")
    }
```

That is annoying. The compiler can't deduce that there are exactly two cases here to consider -- and rightly so,
 there is nothing preventing someone in a third-party code base using our code as a library, or future maintainers 
 from additionally sub-classing `BinaryTree`, so Kotlin forces us to explicitly account for that in our code.
 
This is where the sealed modifier comes in. If we replace `open class BinaryTree<A>` with `sealed class BinaryTree<A>`,
 Kotlin only allows inheritance from the base `BinaryTree` class in the same file it is defined. The compiler (and we!)
 can now rest assured that there are exactly two types of `BinaryTree`: A `Branch`, and a `Leaf`, and we can safely omit
 the `else` branch in the above function.
 
So, sealed classes are good at making definitions of data types, with strong compiler guarantees that say "This data type will be in exactly one of a finite number of forms".

Beyond better communicating our intent to the compiler and later maintainers of our code-base, sealed classes are also useful for making illegal states un-representable.

What do I mean by this? Oftentimes, functions will accept a larger set of inputs than is actually considered "valid", and upon accepting "invalid" input, will:

  * Throw an exception
  * Have undefined/unexpected behavior.
  * Return null/some kind of result type.

This is, in some sense, unavoidable in any program that deals with the "outside world". For instance, any sort of parsing function is of this form
 (only *valid* strings will be successfully parsed). However, the best thing to do, both to avoid having to parse more than is necessary (which could
 cause performance issues), and to make life easier as a programmer (dealing directly with a `MyObject` is a lot easier than remembering that a particular
 `String` is (probably) a serialized representation of a `MyObject`), is to only parse things at the *edges* of your application, and then to pass around
 more structured data types internally.
 
The issue (which is still sometimes unavoidable) is for "internal" functions in the code base which accept a larger set of inputs than is considered "valid".
 For example, consider the following function:
 
```kotlin
/** 
 * Takes a field of type A, B, or C, and
 * updates the view accordingly.
 *
 * Warning: Throws an IllegalArgumentException unless
 *  exactly one of the arguments is non-null. View can
 *  only have one of the three fields set at a time.
 */
fun setField(fieldA: A?, fieldB: B?, fieldC: C?)
```

With sealed classes, we can create a data type that exactly models the constraint "exactly one of the arguments is non-null", so
 we can re-write this function to not have to deal with exceptions!
 
```kotlin
sealed class SomeField {
    data class First(val fieldA: A): SomeField()
    data class Second(val fieldB: B): SomeField()
    data class Third(val fieldC: C): SomeField()
}

/** 
 * Takes a field of type A, B, or C, and
 * updates the view accordingly.
 */
fun setField(field: SomeField)
```

Now we no longer have to deal with the possibility that someone called `setField` with the wrong arguments.

Case study: Extensible REPL
---------------------------

Lets say you want to build a REPL for a programming language, like `ghci`, or the `python` executable. Usually these
 applications, in addition to allowing you to make new definitions and evaluate expressions, allow you to enter
 specific "commands". For instance, in `ghci`, `:set +m` lets you unable multi-line entry mode.
 
At first, if you're new to sealed classes/ADTs, and you're generally trying to design your systems such that you [parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/), it might seem like a good idea to define an algebraic data type for commands in this repl, where each term of the sum corresponds to one possible command, such as the following:
 
```kotlin
sealed class ReplCommand {
    /** Turn mutli-line mode on or off. */
    data class SetMultiLine(val value: Boolean): ReplCommand()
    /** List the most recent definitions that have been added into the REPL. */
    object ListDefinitions: ReplCommand()
}
``` 
 
We could then define a function for parsing such commands from raw strings:

```kotlin
fun parseReplCommand(input: String): ReplCommand? =
    // Commands start with a ':' character, so look for that first.
    if (input.firstOrNull() == ':') {
        val cmdText = input.split(" ").first()
        when(cmdText) {
            "set_m" -> {
                val rawArg = input.substringAfter(' ')
                rawArg.readAsBooleanOrNull?.let { parsed ->
                    ReplCommand.SetMultiline(parsed)
                }
            }
            "list_defs" -> {
                ReplCommand.ListDefinitions
            }
        }
    } else {
        null
    }
```

A little verbose -- if we plan to add many more commands in the future, it might be worth looking into
 using a parsing library, or at least building up some utilities to make argument parsing a bit easier, but
 so far nothing too troubling. 

Let's then say we have a `ReplCtx` that defines a context of actions we can preform in our Repl
 ^[We will not worry about the actual implementation of such a class here -- but I quite like this
 style of programming in Kotlin. It is reminiscent of [MTL](https://hackage.haskell.org/package/mtl)-style programming in Haskell]:
 
```kotlin
interface ReplCtx {
    fun setMultilineMode(value: Boolean)
    fun getDefinitions(): List<MyLanguageDeclaration>
    fun addDefinition(defn: MyLanguageDeclaration): Boolean
    fun display(text: String)
    fun prompt(): String?
}
```

Given this, we can define a function which takes a `ReplCommand`, and preforms an action in a
 `ReplCtx`. This cleanly separates our parsing code from our action-oriented code.
 
```kotlin
fun ReplCtx.executeCommand(command: ReplCommand) {
    when(command) {
        is ReplCommand.SetMultiline -> {
           // Set the multiline mode to whatever the user's selection is.
           val userSelection = command.value
           setMulitlineMode(userSelection)
        }
        is ReplCommand.ListDefinitions -> {
            // Get the current list of definitions.
            val defns = getDefinitions()
            // Display the last 10 definitions to the prompt.
            display(
                defns.take(10)
            )
        }
    }
}
```

Consider for a moment the organization of the code-base so far. We have multiple functions (a *product*)^[Multiple functions defined in a module can be considered to be a product of those functions, as given such a module, we have access to *both* functions. This observation can be made more formal in languages with first-class modules like [OCaml](https://ocaml.org/manual/firstclassmodules.html).], each of which handles a number of different cases (a *sum*). This is what is meant by the *product of sums* trap.

To explore why this can be problematic, let's see what happens if we add a new command to `ReplCommand`: 

```kotlin
/** List all of the definitions that have been added into the REPL. */
object ListAllDefinitions: ReplCommand()
```

The compiler will happily tell us that we need to add a new case to `executeCommand`. Great! This is why sealed classes are helpful.
 
Unfortunately, this helpfulness only goes so far. Notice, for example, every time we add a new `ReplCommand,` the compiler will *not* complain that we forgot to add a case to `parseReplCommand`. If you didn't document that `ReplCommand`s are parsed by using the `parseReplCommand` function -- and you're either coming back to this code-base after some time away, and have forgotten the structure, or completely new to the code-base, you might scratch your head for awhile, studying the code until you finally see that a new case needs to be added to `parseReplCommand`.
 
Iterate on this design a few times, add a few new features and a couple of new commands, and you've created, what [I've discovered myself](https://github.com/Sintrastes/bli-prolog/blob/a87a7f8fb4d1736db1357aee93910f269b16ef5b/src/Bli/App/Config.hs) to be a big bowl of spaghetti.
 
Now when you want to add a new command, you've got *several* places in the code-base you have to modify, all of which may or may not make the compiler warn you if you've missed one of them. You're keeping up with that documentation for all of this, right?
 
Worst comes to worst, let's say that after dealing with this code-base for awhile, you decide you want users to be able to implement their own custom commands, perhaps through a custom DSL, or some sort of plugin system^[On the JVM you'd use a class loader for this. Languages targeting native binaries like Haskell will need some form of [dynamic linking](https://hackage.haskell.org/package/plugins)]. Now we can't even use sealed types at all! *Extensible at run-time* is kind of antithetical to *known to have exactly these cases at compile-time*.
 
This led me to come up with the following maxim for myself:

::: blockquote
Organize your codebase as if you had to support a system that lets you add new cases at run-time.
:::    
    
This works, because organizing your code-base this way makes life easier not just for you in the future
 if you indeed decide to implement such a feature, but for *any* developer that has to add a new
 case to your system. Let's consider what this alternative looks like:

The extensible solution
------------------------

Rather than defining a case for each command in our system, let's consider what a command *needs*
 in other to function like a command^[The analogy might be a bit strained at this point, but it seems to me like this alternative way of thinking might be thought of as a "sum of products" solution. I attempted to try to work this out formally as an isomorphism between the two solutions, but was not able to say anything concrete (at least for this example). Perhaps there is a more advanced analysis that could be done here to say something more meaningful!].

```kotlin
interface ReplCommand<A> {
    /** String used to identify the command. */
    val name: String
    /** Function to parse the arguments of the command. */
    fun parseArgs(input: String): A?
    /** Function to run once the arguments have been parsed correctly. */
    fun ReplCtx.action(args: A)
}
```

Surprise! The solution in an OOP language is to simply use a plain old interface! In a language like Haskell or C without interfaces, you'd just use typed records/structs. For instance, in Haskell^[Note that where one would use a function with receiver parameter in Kotlin, one often uses a custom monad of some kind in Haskell, which is what `Repl` is here.] the solution would look
 something like:

```haskell
data ReplCommand a = ReplCommand {
    name :: String,
    parseArgs :: String -> Maybe a,
    action  :: a -> Repl ()
}
```



For a lot of us, sum types are shiny and new -- so, especially when first learning about them, we may be biased towards trying to incorporate them into every solution -- but sometimes the "boring" solution is the right one.

Let's see what our solution looks like now with this interface instead of a sum type. Our code for handling commands looks like:

```kotlin
fun parseReplCommand(command: ReplCommand<A>, input: String): A? {
    // Commands start with a ':' character, so look for that first.
    if (input.firstOrNull() == ':') {
        val cmdText = input.split(" ").first()
        // If the name of the command is the same as thing one,
        // try parsing the arguments to the command.
        if (command.name == cmdText) {
            val argsText = input.substringAfter(' ')
            command.parseArgs(argsText)
        } else {
            null
        }
    } else {
        null
    }
}

/** Pair of a command and the arguments to that command of the correct type. */
data class CommandWithArgs<A>(val command: ReplCommand<A>, val args: A) {
    fun ReplCtx.runAction() {
        command.action(args)
    }
}

fun ReplCtx.startRepl(commands: List<ReplCommand<*>) {
    while(true) {
        // Prompt the user for input (continue on empty input)
        val input = prompt() ?: continue
        // Try parsing each of the commands in order, and return a bundle of
        // the first arguments to successfully be parsed, and the corresponding argument:
        val parsedCommand = commands.map { cmd ->
            parseReplCommand(cmd, input)?.let {
                CommandWithArgs(cmd, it)
            }
        }
            .filterNotNull()
            .firstOrNull()
        if (parsedCommand != null) {
            parsedCommand.runAction()
        } else {
            display("Error parsing command.")
        }
    }
}

```

Where now we can define our commands themselves as:

```kotlin
object SetMultiLine: ReplCommand<Boolean> {
    override val name = "set_m"
    override fun parseArgs(input: String): Boolean? {
        return when(input) {
            "on"  -> true
            "off" -> false
            else  -> null
        }
    }
    override fun ReplCtx.action(args: Boolean) {
        setMulitlineMode(args)
    }
}

object ListDefinitions: ReplCommand<Unit> {
    override val name = "list_defs"
    override fun parseArgs(input: String): Unit? {
        return when(input) {
            ""   -> Unit
            else -> null
        }
    }
    override fun ReplCtx.action(args: Unit) {
    	// Get the current list of definitions.
        val defns = getDefinitions()
        // Display the last 10 definitions to the prompt.
        defns.take(10).forEach {
            display(it.toString())
        }
    }
}
```

While this is still a bit verbose, and for more complicated commands with multiple arguments, we may
 again want to consider use of a specialized parsing DSL for parsing command arguments, we have accomplished
 our stated goal: The implementation of `ReplCommands` is cleanly separated from the logic of running our REPL.
 
Some final notes
----------------

While in this post, I have attempted to come up with a criterion for when it is appropriate to use sum types,
 and when it is appropriate to simply use records, I suspect the answer will not be entirely satisfactory to everyone.
 The naive maxim I proposed earlier in this post is, I fear, a bit strong, and requires some clarification.
 
"Organize your codebase as if you had to support a system that lets you add new cases at run-time." is I think a great
 suggestion for things that could be classified as "features" of an application. Repl commands are a good example of this
 -- they're something tangible you can talk about in a program, of which the number of "features" included is more-or-less
 arbitrary. For some other examples I think fit this definition well, consider:
 
  * "Editor actions" one could preform in an IDE, which can be bound to various keybindings.
  * Menus or configuration windows in a GUI application.
  
Whereas things that are "good fits" for sum types include:

  * Abstract syntax trees for a programming, domain-specific, or markup language.
  * Specific data types (e.x. trees, or result types), where making such types "extensible" doesn't really make much sense 
    (A binary tree with additional cases is no longer a binary tree!)

However, even in the case of ADTs, people often think about making them as extensible as possible. What I've covered today concerns the
 aspect of extensibility regarding *extension by new cases*, but more generally, a lot of people have spent a lot of time thinking about
 the [expression problem](https://en.wikipedia.org/wiki/Expression_problem), which concerns the problem of designing data types
 so that it is easy to both *add new cases*, and to *add new operations* on that data.
 
Moreover, even in the case of things that one might consider to be "features", there are a few considerations which might
 lead one to use sum types to model them.

For instance, an important consideration when deciding whether or not to use sum types is the fact that writing things 
 in a generic enough way to be extensible is oftentimes more challenging than writing out each of the cases manually with a sum type. 
 Just in our example above, we can see that in order to support commands with varying argument types, we had to use Kotlin's type
 projections, and a utility class `CommandWithArgs` to get everything to typecheck^[I may write a post in the future on this, and related techniques in Kotlin.].
 If you're just in the prototyping stage, that might be more effort than it's worth. Then again, it may pay off in the future to spend the time getting a solid,
 extensible design down from the beginning. I think it's partially a matter of personal preference and how you want to work.

I think that a general rule of thumb here is: 
 
::: blockquote
If there are a small number of cases to consider, and it is not 
likely that more cases will be added in the future, consider modeling your data as a sum type. 
:::    

