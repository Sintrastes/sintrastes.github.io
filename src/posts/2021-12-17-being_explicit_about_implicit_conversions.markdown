---
title: "Being explicit about implicit conversions"
author: Nathan Bedell
tags: pl_theory, category_theory, abstract_algebra
---

A lot of the time, I think developers develop cognitive biases against certain features after spending a lot of time being frustrated by
 a particular implementation of that feature. For instance, checked exceptions have left a bad taste in many a Java developer's mouth, 
 and many will go on to say simply that "checked exceptions are bad", whereas if you dig deeper, people will often point out that the real 
 issue is the false sense of security that such checked exceptions lead to, due to the distinction between checked and unchecked exceptions,
 or generally other issues with this distinction. For instance, a `NullPointerException` in Java is unchecked (i.e. doesn't have to be declared
 in the `throws` block of a function signature) -- which was arguably [a mistake](https://en.wikipedia.org/wiki/Null_pointer#History). And
 such hiccups in the design have led designers of newer languages like Kotlin to leave out the feature entirely, even though, I'd argue,
 in a language that often emphasizes safety, checked exceptions would be a great feature to have in Kotlin!
 
 In the Kotlin standard library, there is [a method](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin.collections/first.html) 
  `List<A>.first(): A` that returns the first element of a list. Well, that is, so long as the list actually has a first element.
  On an empty list, `first` will throw a `NoSuchElementException`. It says as much in the documentation. Yet there is nothing 
  in the language preventing me from using this function without first checking that the list is non-empty, like there would be
  with checked exceptions. Of course, one could use data types like `Maybe` and `Either` from the typed functional programming world,
  but I'd argue that those are not always as ergonomic as exceptions and null values -- especially in a language where Java interop
  is important. So why not have the best of both worlds? Kotlin already explicitly handles `NullPointerExceptions` (a unchecked exception
  in Java) with it's null safety mechanisms -- why not `NoSuchElementException` as well? Just because Java isn't safe enough with it's checked exceptions doesn't mean we have to toss it
  entirely. We should go the other way and make it as safe as it should have been in the first place.
  
  There are other issues with checked exceptions one could bring up, and I may address those in another blog post, but for now
   I'd like to address a similar bias against *implicit conversions*.

Strength is in the eye of the beholder
--------------------------------------

  The discussion of implicit conversions is related to that of "strong" v.s. "weak" typing. This can be confusing, because arguably, the 
   term "strongly typed" has at least two separate meanings:
   
  1. A language is (more or less) strongly typed to the degree in which it permits implicit conversions.
  2. Code is more or less strongly typed to the degree in which the developer makes use of types to capture
      invariants of their code to ensure correctness. (This could also be said of a langauge -- meaning the degree 
      to which the language allows or facilitates such a discipline.)
      
For instance, Haskell might be said to be more strongly typed than Java, because it has features like sum types that allow
 for the programmer to express more detailed invariants for it's types. This is in spite of the fact that nothing is preventing
 the Haskell developer from writing their codebase [entirely using the `String` type](https://hackage.haskell.org/package/acme-stringly-typed-1.0.0.0/docs/Acme-StringlyTyped.html) 
 -- which would hardly be enforcing any invariants at all. After all, a tweet from Donald Trump, the source code to the Linux kernel, 
 the world's nuclear launch codes, or the entire works of Shakespere translated to Polish all fit inside Haskell's `String` type. So even the second meaning of "strongly typed" has a few different senses depending on exactly what we are talking about (i.e. a language, or a particular code-base). 

I think that because this distinction between the meanings 1 and 2 of strongly/weakly typed are 
 often conflated, languages which allow for implicit conversions in any capacity are automatically assumed to be more "weakly typed" in the second sense by association. This, together with the cognitive bias developers might have from working in a language with badly implemented implicit conversions, can lead to an overly quick dismissal of implicit conversions outright.
 
I don't think it is always the case that implicit conversions are harmful, or that implicit conversions necessarily lead to a lack of "strength" in the second sense above. To clarify the situation, I'd like to be *explicit* about what I mean by implicit conversions,
 and classify systems of implicit conversions into two cases:
 
 1. Arbitrary implicit conversions. From any type, to any type, at the language designer's (or user's -- if the langauge lets users create their own implicit conversions) whim.
 2. Principled implicit conversions. Only conversions from a "subtype" to a "supertype" is allowed.
 
Case 1 here is what left a lot of developers with a bad taste in their mouth. For instance, `C++` lets you implicitly convert a `float` to an `int` -- and JavaScript is like the wild west when it comes to implicit conversions. But what does the alternative look like? 

As a first approximation, let's interpret "subtype" as "subset". Intuitively, `int32` is a *subset* of the type of `float`.
 Of course this isn't strictly speaking true -- the memory layout of these types is different, so one is not strictly speaking
 a "subset" of the other in that sense. What we really mean in this context is that there is a mapping (function) from `int32` 
 to `float` that *behaves* like a "subset function". In set theory, these are known as *injective functions*. More generally,
 in category theory, these are called *monomorphisms*, but we'll get to that more later.
 
In other words: A function $f : X \rightarrow Y$ is injective if it maps distinct elements in `X` to distinct elements in `Y`. This can be
 viewed as kind of generalization of a "subset", because such a function identifies `X` with the subset of elements of `Y`
 that `f` maps to (it's "image").
 
Ok, great! So, this would allow for an implicit conversion from `int32` to `float`, because we can define an injection from 
`int32` to `float` -- but the opposite conversion would not be allowed, because `float` has more elements than `int`, so it is
impossible to build an injection going the other way.

This also has problems. Consider an example like this (which those against any form of implicit conversion on primitive types will often cite):

```
val x: Double = 7/2
> 3.0 // (Expected 3.5)
```

Or, perhaps even worse:

```
val x: Double = 1/2*1.1
> 0.0 // (Expected 0.55)

```

The issue is, this only causes an issue due to user expectations as to what "`/`" means. Now, I'm not saying that's not a problem --
 but implicit conversions themselves are not to blame here, and this problem can be solved in other ways.
 
Before we get to that, I should note that I am not flat out against operator overloading, or other types of overloading in a language. That's not the issue here either per se.
 Having [two different sets of arithmetic operators](https://en.wikipedia.org/wiki/ML_(programming_language)) depending on 
 whether you are working with ints or floats is not my cup of tea. The issue is _this particular case_ of operator overloading
 -- and in the next section, I hope to attempt to develop a general rule for why this particular case bothers me.
 
Consider how Haskell handles this. The type of the standard division operator in Haskell (`/`) is:

```haskell
(/) :: Fractional a => a -> a -> a
```
For those not familiar with Haskell, the `Fractional a` is a *typeclass constraint* on the type variable `a` -- and essentially says
 "This function only works on `Fractional` types (for instance, `Float` or `Double` in Haskell)". Whereas another function entirely
 is provided for integral division:
 
 ```haskell
 div :: Integral a => a -> a -> a
 ```

Arguably, it makes sense to keep these two different functions apart in a way that it doesn't make sense to do for other kinds of operators because integral division is a fundamentally different beast
 than fractional division. But to explain precisely why that is, we need to dive into some theory.

A little bit of algebra
-----------------------

I've touched a little bit [before](https://sintrastes.github.io/blog/posts/2021-07-19-sum_types_are_not_a_silver_bullet.html) on my blog on the topic of abstract algebra, to help understand the analogy between classical algebra and _algebraic data types_. To summarize: Abstract algebra is the study of *algebraic structures*, which consist of a base set `X`, a set of operations on that set (such as `+`, `-`, `*`), and a set of laws that those operations have to obey.
 
In abstract algebra, a central notion is that of a *homomorphism*, or *structure-preserving-map* between two algebraic structures.
 To demonstrate what I mean by that, I'll first introduce one of the simplest algebraic structures out there: A _monoid_.
 
A monoid is a just an interface on a type that provides a straightforward way of combining things. Namely:

 1. A monoid consists of a binary operator $\cdot : (A, A) \rightarrow A$ that is associative. That is, for all $x,y,z: A$ we
  have $(x \cdot y) \cdot z = x \cdot (y \cdot z)$. What this means is that we can list a set of things being "combined"
  unambiguously as: $x \cdot y \cdot z \cdot w \cdot ...$.
 3. Furthermore, there is an element, called $identity$ such that $identity$ combined with anything is itself. i.e.
  $x \cdot identity = x$ and $identity \cdot x = x$
  
If you're familiar with the [Composite](https://en.wikipedia.org/wiki/Composite_pattern) design pattern -- this is an example of a monoid^[In order for this to work, strictly speaking, we may need to slightly modify the notion of "equality" of composite disposables.]. For instance, in rxJava2:

```kotlin
interface Monoid<A> {
    val identity: A
    fun combine(x: A, y: A): A
}

object DisposableMonoid: Monoid<Disposable> {
    override val identity = CompositeDisposable()
    override fun combine(x: Disposable, y: Disposable): Disposable {
        return CompositeDisposable(x, y)
    }
}
```

Another example that will be fimiliar to software developers is lists! Consider (as an example of the laws):

```kotlin
listOf() + listOf(1,2,3,4) == listOf(1,2,3,4) == listOf(1,2,3,4) + listOf()
(listOf(1,2) + listOf(3)) + listOf(4,5) == listOf(1,2,3,4,5) == listOf(1,2) + (listOf(3) + listOf(4,5))
```

For some more mathematical examples, note that real numbers under addition are a monoid with identity `0`, and
 they are also a monoid under multiplication with identity `1`.
 
Finally, for a arithmetical counter-example, note that divsion over the real numbers is in fact *not* a monoid.
 It fails the associativity condition -- for instance: `(1.0/2.0)/2.0 == 0.25`, but `1.0/(2.0/2.0) == 1.0`. We will
 see later that this does in fact fit into another common algebraic structure -- just not a monoid.
 
So what does it mean to have a function that preserves the structure of a monoid? Well, if we have two monoids $X$ and $Y$, and
 a map $f: X \rightarrow Y$ between them, it means:
 
  1. $f$ must map the identity of $X$ to the identity of $Y$.
  2. $f(x \: \cdot_X \: y)$ must equal $f(x) \: \cdot_Y \: f(y)$ for all $x, y$, where $\cdot_X$ is the "combine" operation of $X$, and $\cdot_Y$
   is the "combine" operation of $Y$.
   
For other algebraic structures, the definition of a homomorphism is similar (special elements must map to special elements, and functions
 applied to the arguments of operators must yield the same result whether they are applied "under" or "over" the operations).
 
For an easy example of a monoid homomorphism, consider our example before of the reals under addition and the reals under multiplication. Note that, by high-school arithmetic:

$$ e^{x + y} = e^x * e^y $$

So the map $f(x) = e^x$ transforms one monoid operation (addition) to another (multiplication). Neat! For identities, note that we also have:

$$ e^0 = 1 $$

So the additive identity is sent to the multiplicative identity. We in fact have a monoid homomorphism from $\mathbb{R} \rightarrow \mathbb{R}$.

The astute reader might further notice that the natural logarithm (in fact, any logarithm) does the same thing, but in reverse:

```
ln(x * y) = ln (x + y)
ln(1) = 0
```

As a side-note: This actually provides some intuition for why decibels are measured on a logarithmic scale: We have something that physically 
 multiplicative (decibels), that we want to measure additively (because our brains can comprehend that better!) -- so we map
 the multaplicative scale to a lograithmic scale using a homomorphism! 
 
Homomorphisms are powerful -- as they preserve the structure of the algebra in question, they let us transfer results about one algebraic structure to another. 

Rings and Fields
----------------

We noticed before that both the multiplicative and additive operations on the real numbers formed
 monoids. Together two such monoids form another algebraic structure called a 
 *Ring*. I won't get into all the laws, but I'll define the structure itself using a Kotlin interface:
 
 ```kotlin
 interface Ring<A> {
     val addId: A
     val mulId: A
     fun add(x: A, y: A): A
     fun mul(x: A, y: A): A
     fun negate(x: A): A
 }
 ```
 
 Rings are meant to be a generalization of the algebraic strucutre of the integers -- so any laws you
  can remember from primary school regarding the integers should hold for rings as well -- but for those
  curious, [here](https://en.wikipedia.org/wiki/Ring_(mathematics)#Definition) is the formal definition.
 
Notably absent from the structure of a ring is an operation for division! Since rings are meant to be generalizations of
 the integers, this makes sense. Integers do have a "division" operator, but it takes *integers* to *rational numbers*,
 not *integers* to *integers*. 
 
Or, rather, I should say there there is no "proper" division operation on the integers, in the sense
 that there is no division operation on the integers that makes them into a *field*:
 
 ```kotlin
 interface Field<A>: Ring<A> {
     fun divide(x: A, y: A): A
 }
 ```
 
 Here, in the field laws, `divide` has to satisfy the property that for all *non-zero* `x`: ` mul(x, div(1,x)) == 1`.
  In other words, as one would say in abstract algebra^[Monoids with an inverse form another important algebraic structure called a group, which is incredibly useful for describing symmetries.], `divide` is the `inverse` of `mul`. 
  
Intuitively, it is easy to convince yourself (though perhaps not formally prove, without knowing some basic ring/field theory) that
 it is impossible for the integers to have such a `divide` operation. For instance, `2` does not have a multiplicative inverse, because
 that would have to be `1/2` (multiplicative inverses are unique when they exist) -- which is not an integer.
 
So already, perhaps you can see why it may not be wise to identify the integral division `div` in your language, with the floating point (or "real") division `/`. But let's use our knowledge to make this a formal criterion:

Some criteria for "sane" implicit conversions
---------------------------------------------

Let's pretend for a moment that `/ : (Int, Int) -> Int` was in fact a valid division operation, in the sense of field theory.
 This is maybe not too much of a stretch. Integer division is "kind of" an inverse. For instance, `(x * y) / y = x` always works^[I'm a little bit rusty since my grad school math days, but I should note here that this remark can in fact be made more formal. There is a [spectrum](https://en.wikipedia.org/wiki/Euclidean_domain) of different algebraic structures between rings and fields, going from less to more capability to preform "divisions", as well as other useful properties. ].
 
Now, rather than considering all injective functions valid choices for implicit conversions, let's instead look at 
 only allowing _injective homomorphisms_. 
 
Let's then consider the explicit mapping $toDouble: Int \rightarrow Double$. Is it a homomorphism with respect to the integral and floating point division operations?
 
 ```kotlin
  1.toDouble()/2.toDouble
     = 1.0/2.0
     = 0.5
 ```
 
 whereas:
 
 ```kotlin
 (1/2).toDouble()
    = 0.toDouble()
    = 0.0
 ```

So that is a resounding no! 

This led me to come up with the following "soundness" criterion for implicit conversions:

A system of implicit conversions is "sane" if:

  1. All implicit conversions are injective as functions on terms of the programming language.
  2. There are no cycles in the graph of implicit conversions (conversions only ever go one direction!)
  3. If there is a structure common to both types X and Y, the implicit conversion should respect that strucutre (i.e. be a homomorphism).
  4. All implicit conversions from a type `X` to a type `Y` should be in some sense *unique*, or *cannoncial* at least.

Since this whole problem deals with the messy, psychological aspect of subverting human expectations, this is not a formal soundness 
 criterion -- but merely a guideline to for developing "sane" implicit conversions that will not subvert developer expectations. Each three of these criteria, I think, could also be taken and debated seperately. 
 
Is it really nescesary that all implicit conversions are injective as functions? I can't really think of a use case of this where I would want this at the moment (assuming it is still "sound" in the sense that this conversion is a homomorphism for the relevant strucutures -- I *know* that I don't want the standard lossy C/C++-style implicit conversion from `Float` to `Int`) -- but that doesn't 
mean that non-injective implicit conversions are nescesarialy problematic. 

Is it really nescesary to prohibit cycles in the graph of implicit conversions? Again, just because `int <-> float` implicit conversions are bad doesn't nescesarialy mean that bidirectional conversions are bad per se. In Haskell, where there are several different encodings of *strings* (string, strict and lazy bytestrings, strict and lazy text, bytestring builders, etc...), where these representations are essentailly isomorphic -- I think it would be very useful to have some implicit conversions. It certainly would save me some time from
asking myself "...How do I convert from X to Y again?". However, in a langauge with strong, Hindley-Milner-esque type inference, allowing these sorts of implicit conversions could potentially be an implementation concern.

Of all of these, I honestly think that `3` and `4` are the strongest, but of course, I'd be happy to have a debate or more examples/counterexamples of problematic behavior for any of these four points. I think this is an area that deserves further explanation.
 
