
# An Introduction

## Who am I?

- Joel "Jaykul" Bennett
- Sr. DevOps Engineer
- Host, ViPUG (aka Slack/Discord)
- 10x PowerShell MVP
- <span class="fragment">Battle Faction Hacker</span>

note: Hi folks! I'm Joel Bennett -- but you may know me as "Jaykul" on Twitter or the PowerShell Slack or Discord or IRC. I've been running that online chat community for about 12 years, and I am a ten-time PowerShell MVP.

Before we get started today I want to tell you something about me: Occupationally I'm a programmer. My business cards (if I had any) would say "Senior DevOps Engineer" or sometimes just "Senior Software Engineer" or "Software Architect" but at the end of the day, I'm a Battle faction hacker. It's important that you understand that as we get into our subject for today, because we're going to be talking a lot about design, but I want you to keep in mind that the reason we're putting this much thought into our design is to make sure that our modules are usable by _other people_, and that they will survive first contact with a newbie.

I want to be clear about one thing: I can promise you, up front, that not all of my own code is bullet-proof. As a battle faction hacker, the truth is that in my public code, I only rarely write things that really **need** to be bullet-proof, and as a result, if you look me up on github, you're not going to find all of these patterns followed, and you may find a lot of commands that are missing exception handling. That tends to be a side-effect of the types of modules I write, where errors are unlikely, and not critical. ;)

At work, it's quite different -- we write infrastructure automation and software deployment scripts. There, I have to be much more vigilant, and prioritize logging and central error handling.

---

# To me, writing survivable code means two things

Designing commands which make sense and work together

note:

First: designing commands which make sense and which work together. This is partly about writing so that users can use the commands without needing to read the help. It's partly about making sure that the commands work well _with others_, and that the examples actually show that.

---

# To me, writing survivable code means two things

Handling errors appropriately

note:

The second thing is error handling. We want to collect exceptions, make sure that we handle what we can, and that when we can't, we're throwing things which make sense, and if possible, that we're logging the errors or producing output that can be logged.  Here's an example. Do you know what happens in your `prompt` function if something throws an exception?

---

## Demo 1

```PowerShell
function prompt { "$pwd> " }

function prompt { "$pwd> "; Write-Error "Typo" }

function prompt { "$pwd> "; Write-Error "Typo"; throw "grenade" }
```

You can see at this point that when your prompt throws an exception, PowerShell just throws out any output it's _already gotten_ and gives you a minimalist prompt. You're expected to look in $Error and figure out what happened (oh, someone threw a grenade, classic).

Let me show you what PowerLine does in that situation. PowerLine is my prompt module, and in it, your prompt is `$prompt`, a collection of script blocks.  Here's an equivalent PowerLinePrompt, and let's see what happens when you add an exception ...

```PowerShell
# An equivalent PowerLinePrompt:
Set-PowerLinePrompt -Prompt { $MyInvocation.HistoryId }, { Get-SegmentedPath }

$prompt

$prompt += { Write-Error "Typo"}

Set-PowerLinePrompt -HideErrors

Set-PowerLinePrompt -HideErrors:$False

$prompt += { throw "grenades" }

$PromptErrors

$PromptErrors.Values | fl * -fo

Remove-PowerLineBlock $prompt[-1]

Remove-PowerLineBlock $prompt[-1]
```

Notice that I actually still got my prompt! But I also got a warning and we can see that it's telling me how to _hide_ the error if I really want to do that...

If I throw an exception, it gets logged right along with the error, and we can look at both of them in `$PromptErrors`. Notice that it tells us which block cause each problem, and of course, in this case, we can just remove those blocks.

---

## Let's start by talking about design, which is honestly my favorite part

I know, I know. I said I was Battle Faction ... but the truth is I'm really never quite happy with a module until the commands can pipe into each other, and the number of nouns has been reduced as far as I can get it. I find it's mostly about how you approach the problem: thinking about how your command will be used, how you want to use it, what commands exist which people might want to use it _with_, and design to make that easier. It's a really good practice to start by writing the help examples and tests before you ever start implementing anything -- so you can get a feel for how you expect the command to be used.

For the purposes of our talk, let's take a couple of functions from a module that's been slapped together and not really _designed_ very well.


## First, write Help

For a good command, we really require just three things in the help:

1. A Synopsis

    A synopsis or description of the command is all it takes for the help system to engage. I strongly encourage you to also write a full description, but if you're in a hurry, write a synopsis.

2. An example -- for each parameter set

    In the simplest case, you can simply provide a single example (with no parameters), and a sentence explaining that this runs it with the default values, and explaining what happens in that case.

    If you can't think of an example for a parameter set -- consider removing that parameter set 😉.

    Make sure you have at least one example for each parameter set that _correctly_ shows an example of how to provide the values which are necessary to invoke that parameter set.  That is, make sure you show each set of mandatory parameters.

    More examples are better, but only if they have significantly different _outcomes_.

3. Documentation of every parameter

   You can write this as you add parameters, by simply putting a comment above each one. In fact, I strongly recommend you do it that way (rather than using the `.PARAMETER` marker) because it's harder to forget to write and update!

## Then write tests

We're going to mostly skip over testing, because that's an entirely different talk.

Let me say this though: you should write tests as documentation. You should think of them as documenting your intent, your design, and as prooving that you've done it correctly. If you're not writing tests, start. Grab Pester. Write some _acceptance tests_, and read a little about behavior-driven development. Have a look at Gherkin syntax. Make sure you have tests for each of the examples that you wrote above.

## Pick good names

Once you have some help and some tests in place, stop and think again about naming.

I mean, you spend a lot of time thinking about what to name your commands right? But do you spend that much time thinking about the names of its parameters Parameter names are part of your user interface just like your command name, but there's not as much guidance for them as there is for command names. No lists of approved verbs, no mandates about singular nouns...

Command names matter for discoverability, but did you know you can search for commands which have a specific parameter name (and even parameter aliases)? Try it: `Get-Command -ParameterName PSPath`

The truth is, parameter names may be **the most important part** of your user interface and your programming interface. They are affect _usability_ more than the command name because they affect users' ability to figure out what values they can and should pass, and they also affect your users ability to pipeline input to your function.

### What makes a good parameter name?

First, it's a good name if users can tell what you want! Specifically, if users can tell what information they need to pass to each parameter --and what form the data should take-- without reading the help.

Here are a few guidelines for parameter names. Sometimes, one of these goals will make others impossible. That's ok. Prioritize. But also remember that you _can_ use aliases to meet your goals. Parameters should be:

- Recognizable and Specific

    `$FirstName` or `$FullName` would be better than `$Name`

- Implicitly Typed

    Remember that we want users to know what they can pass without reading the help.

    - `$FilePath` is better than `$File` or `$Path`
    - `$TimoutSeconds` is better than `$Timeout`

- Distinct

    Consider what happens if I use PSReadLine's `Ctrl+Space` to list parameters (look at Install-Package!)

    Although multiple parameters that accept similar information in different ways might be desireable for flexibility, it can confuse users even if you put them in parameter sets.

    Ideally, each parameter would start with a different letter, and be a unique way to pass a specific piece of information.

    For example, use `$Credential` alone, rather than having _both_ `$Credential` and `$UserName` and `$Password`. It limits the way a user can invoke your command (and might force them to manually create a credential on a separate line), but it's dramatically clearer what a user needs to do when there's only one representation.

- Match properties on output types

    If you're passing through some of the input as properties on the output, consider what the property names will be when naming your parameters. Sometimes it's worth breaking all the other rules in order to match up with the property on an output type you don't control.

- Match properties on pipeline input types

    In order to set parameters using the properties of pipeline input objects, you need to match the property name. You can use aliases to do this, but it's a lot easier for users to follow if the names match up exactly...


## Speaking of Input and Output Types

For background:

- PowerShell is based on .NET, an object oriented framework
- Everything we output is an object
- Everything we pass as parameters are objects
- Each object is a specific `type` of object
- The definition of a specific type is called a `class`.

Objects are fundamental to the formatting of output in PowerShell, but also to the way pipeline input works. A parameter may be defined to take the whole pipeline object as a value, or it to take a single property from it which it matches the parameter type and name.

This means that designing a _set_ of commands that work together flawlessly is about more than just designing the parameters of the functions -- you should include designing the output types.

### What Type of Object?

In PowerShell we deal in three general categories of objects: the built-in objects which are part of the .NET framework, such as the FileInfo,  dynamic objects (i.e. "PSCustomObject") such as those created by PowerShell when you use `Select-Object`, and custom objects defined by the functions and

However, there are lots of very good reasons that you should define your own object types.

1. When you want to customize formatting, your output will need a type name
2. When you need to pass a lot of data between commands, you'll want a name for a parameter type
3. When you want interactive objects, you'll want a custom type

Most of the time, you can get away with just specifying a custom `PSTypeName` -- it's enough to let you format and even contrain inputs. However, it doesn't help users who are trying to tab-complete properties of your output objects, nor make it easy for users to create the objects to pass them as input.

### Why do we care about types?

Probably the best interaction between functions is to take the output of one command as input to another -- but the best user experience is not necessarily an `InputObject` parameter of the specific type, sometimes it's better to accept the properties of the object as parameters. For one thing, it means that a `PSObject` will give you enough structure for pipelining. For another, it allows users to just pass values for each parameter. one much easier for users who do _not_ have the object to call your function, while still preserving the ease of use

## Getting parameter values from the pipeline

Hopefully, you've already encountered the `[Parameter()]` attribute, and it's many switches. Two of them allow you to collect the value of the parameter from pipeline input:

- ValueFromPipeline allows you to create an `$InputObject` parameter to collect each object. It's a good fit for when you only want to accept the output from one of your other functions, and when your objects are easy to construct (or have default constructors so you can easily build them from hashtables).

- ValueFromPipelineByPropertyValue allows you to collect the value of a single property from each object. Of course, you can set up multiple parameters like this to collect multiple properties. This is a good fit when you don't have a specific object in mind, or when you only need the key identifier from it (e.g. `PSPath` for files).

Now, the key thing to remember with pipeline input is that it means the `Process` part of your command is going to run over and over for each input. You can't always allow every parameter to be pipeline input -- and frequently, it doesn't make any sense to have every parameter passed in that way.

However, when you can support it, pipeline input gives users of a function much greater flexibility! For the sake of flexibility, I strongly recommend that you design your commands starting with a `Process` block, and let every parameter that can be assigned within that loop be a `ValueFromPipelineByPropertyValue` parameter. Remember that you can only have _one_ `ValueFromPipeline` parameter ...

There are a few caveats. First, when you design commands for pipeline input, think ahead about naming and aliases that could help someone bind the property from common objects or output of other commands in your module (as I talked about in the naming conventions). Second, make sure that you write some examples and plenty of test cases using the command that way, so that you actually cover the combinations of ways input can be passed during testing.

## Starting From the `Process` Block

To write functions (or Cmdlets) that work well in the pipeline, we need to start by putting most of the work in the `process` block (or the `ProcessObject` method). Any reference to parameters which are set with `ValueFromPipelineByPropertyName` (or `ValueFromPipeline`), or variables which are set from those parameters, obviously _has_ to stay in the `process` block, but otherwise...

### Don't leave everthing in the process block

It's tempting to just write everything in the process block, because that pretty much guarantees that the command will work the same way regardless of how it's called (with parameters or on the pipeline).

However, you should always look over your code before you're ready to share it and consider whether you can move code to the `Begin` or `End` block -- anything you can do once instead of every time will improve the performance of your command when it's in the pipeline!

Some obvious examples include setup and teardown code which doesn't need to be re-run each time, and which doesn't use values from your pipeline parameters can obviously be moved, but in general: re-examine your use cases! Look for parameters which you anticipate passing only as parameters, and never as pipeline values (for example, consider `-Destination` on a `Move` command), and see if you're doing anything with _just those parameters_ that could be moved to the `begin` or `end` blocks.

Remember: you can't _safely_ refer to any parameter that's set as `ValueFromPipelineByPropertyName` or `ValueFromPipeline` in the `begin` or `end` blocks.

## When you can't handle an error

Obviously in PowerShell it's relatively acceptable to let errors flow from your output, but some times you absolutely _have_ to handle them, suppress them, turn them into warnings, or convert terminating exceptions into non-terminating errors.

The simple story for error-handling is that you should always make sure that anything which could be thrown is caught and thrown. We could get into this a lot more (talking about why sometimes ErrorActionPreference can cause exceptions to not be thrown until there's a `try/catch` wrapped around them), but the simple thing is to just follow a pattern:

Wrap each script block in a try/catch and re-throw:

```PowerShell

function Test-Function {
    [CmdletBinding()]
    param()
    begin {
        try {

        } catch { throw $_ }
    }
    process {
        try {

        } catch { throw $_ }
    }
    end {
        try {

        } catch { throw $_ }
    }

}
```

Once you've done that, you should, of course ...

### Handle the errors you can handle

Add additional `catch` statements to handle the exceptions you want to handle.

Add logging to get your exception messages, stack trace, etc.