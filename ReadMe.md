---
theme: "white"
transition: "slide"
highlightTheme: "vs"
slideNumber: true
defaultTiming: 100
---

<!-- .slide: data-background-position="top center" data-background="./images/header.png" data-background-opacity="1" data-background-size="368px" data-background-color="#FFFFFF"  -->

# Bullet-Proofing
## Patterns & Practices
#### Survivable Advanced Functions and Scripts
https://github.com/Jaykul/DevOps2019

Joel "Jaykul" Bennett

Battle Faction

<img src="./images/cc-by-nc-sa.png" align="right" width="200px" style="border: 0px">

note:

Welcome everyone to "Bullet-proofing: Patterns and practices for survivable advanced functions and scripts" ... a presentation for the PowerShell + DevOps Global Summit, 2019. I am, of course, Joel Bennett

You may know me as "Jaykul" on Twitter or on the PowerShell Slack or Discord or IRC. I've been running that online chat community for about 12 years, and I am a ten-time PowerShell MVP.

Before we get started today I want to tell you something about myself: Occupationally I'm a programmer. My business cards (if I had any) would say "Senior DevOps Engineer" or sometimes just "Senior Software Engineer" or "Software Architect" but at the end of the day, I'm a Battle faction hacker. It's important that you understand that as we get into our subject for today, because we're going to be talking a lot about design, but I want you to keep in mind that the only reason we're putting this much thought into our design is to make sure that our modules are usable by _other people_, and that they will survive first contact with a newbie.


---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# Disclaimer

My code may not actually be bullet-proof

note:

I want to be clear about one thing: I can promise you, up front, not all of my own code is bullet-proof. As a battle faction hacker, the truth is that in my public code, I only rarely write things that really **need** to be bullet-proof, and as a result, if you look me up on github, you're not going to find all of these patterns followed, and you may find a lot of commands that are missing exception handling. That tends to be a side-effect of the types of modules I write, where errors are unlikely, and not critical. ;)

At work, it's quite different -- we write infrastructure automation and software deployment scripts. There, I have to be much more vigilant, and we prioritize logging and error handling, and so on.

---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# Survivable Code

- Errors are handled appropriately
- Commands make sense & work together

note:

To me, survivable code means two things: it's about design and about error handling. Of the two, error handling is the easiest, so we're going to talk about that right up front and get it out of the way.


---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# Error Handling
## What's Appropriate?
- Sometimes that means not handling
- Usually that means catch and release
- Normal use shouldn't produce errors
- Wrap **everything** in try/catch

note:

Obviously in PowerShell it's relatively acceptable to let errors flow from your output, but you should always do so by catching and re-throwing, not by just ignoring. There are a lot of explanations I could get into about why, and how sometimes exception only show up when there's a try/catch, but this is not an error-handling talk, it's a patterns and practices talk so I can just say:

Follow this template, and add custom handling inside it when you want to suppress errors, turn them into warnings, or convert terminating exceptions into non-terminating errors or vice-versa.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3" data-background-size="100px" data-background-color="#FFFFFF"  -->

## Code Template

```PowerShell
function Test-Function {
    <# help here #>
    [CmdletBinding()]param()
    process {
        try {
            <# code here #>
        } catch {
            throw $_
        }
    }
}

```
note:

There could be more to this template (and there will be, later), but for the moment, the point is to start with a try/catch wrapped around the inside of your process block (and your begin and end blocks too, if you need them)

At a bare minimum, you're going to be rethrowing, to make sure that you don't get surprised by exceptions if someone wraps your code. I actually encourage you to test your code with `-ErrorAction Stop`, to help you identify potential problems.

Remember that you can add additional try/catch statements inside, to wrap specific lines or handle particular errors. You can _of course_ handle particular errors even here, if you just need to customize the error message, or whatever, but this is meant to be the last stand, so you can't really do much to _recover_ here.

Ok, let's look a real-world example: What happens if something in your `prompt` function has an error or throws an exception?

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3" data-background-size="100px" data-background-color="#FFFFFF"  -->

## Demo 1
#### Not handling errors appropriately

```PowerShell
function prompt {
    Write-Error "Typo"
    "$pwd> "
}

function prompt {
    Write-Error "Typo"
    "$pwd> "
    throw "grenade"
}
```

What happens if something in your `prompt` function has an error or throws an exception?

note:

If we run these ...
1. we can see that _errors are ignored_,
2. but when the prompt throws an exception, PowerShell tosses any output it's _already gotten_ and gives you the minimalist prompt.
3. You're expected to know that this prompt means you should look in `$Error` and figure out what happened (oh, someone threw a grenade, classic).

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="100px" data-background-color="#FFFFFF"  -->

## Demo 2
#### Handling errors appropriately


```PowerShell
Set-PowerLinePrompt
$prompt
$prompt += { Write-Error "Typo"}
$prompt += { throw "grenades" }
$PromptErrors
$PromptErrors[1] | Select *
$prompt = $prompt[0,1]
```


note:

Let me show you what PowerLine does in that situation. PowerLine is my prompt module, and in it, your prompt is `$prompt`, a collection of script blocks.  Here's an equivalent PowerLinePrompt, and let's see what happens when you add an exception ...

You can see I actually still got my prompt! But I also got a warning and we can see that it's telling me how to _hide_ the error if I really want to do that...

Of course, I don't really want to hide the errors.

If I throw an exception, it gets logged right along with the error, and we can look at both of them in `$PromptErrors`. Notice that it tells us which block cause each problem, and of course, in this case, we can just remove those blocks.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

## Friends log everything

```PowerShell
try {
    Write-Information "Enter Process Import-Configuration" -Tag Trace
    <# code here #>
} catch {
    Write-Information $_ -Tag Exception
    throw $_
}
```

Invoke it with `-Iv drip`

```PowerShell
$drip |
    Where Tag -Contains Exception |
    Export-CliXml exception.logx
```

note:

I want to encourage you to _log_ everything. When we're trying to track down a problem, it's extremely helpful if there are logable statements for each logic block -- you know what I mean, right? Within each branch of an `if`, or each statement of a `switch`, etc.

There are a lot of **better** ways to log than what I'm showing you here, but if you don't have a logging solution, you could do a lot worse than writing it to the Information stream.

The information stream is timestamped and sourced, and it's full of objects, so you can capture it with the `-InformationVariable` parameter and use Export-CliXml to dump it to a file. It's pretty straight-forward, and can even be used across remoting.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

## In summary

- Always try/catch
    - Rethrow by default
    - Only handle specific exceptions
- Always log
    - Especially exceptions
    - Even Verbose output counts

note:

OK, before we go back to design, I want to just summarize this a little: the point here is that you should always try/catch, even if you're just rethrowing.

And (especially if you're supressing exceptions), you should log the path of execution, so when something unexpected happens, you have the ability to say: look, this is what happened...

OK, Now, let's improve the design...

---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->


# Usable Commands

- Intuitive and discoverable
- Play well with others
- **It's about good interfaces**

Let's talking about design,
this is my favorite part.

note:

So. I told you that survivable code was about writing commands that make sense, and work together.

What that means is that it's about designing good interfaces

- commands people can use even without reading the help, and
- commands which work well _with other commands_,

Let's talk about the process.

I know I said I was Battle Faction ... but the truth is I'm really never quite happy with a module until the commands can pipe into each other, and the number of nouns has been reduced as far as is comfortable. I don't worry too much about total newbies, but I want to write commands that people with some PowerShell experience can pick up and use intuitively.

To design commands correctly, we have to think about how they'll be used

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

## How will it be used?

- How do you want to call it
- What parameters do you want to pass
- Where will you get those values
- What are you doing with the output

note:

You're going to brainstorm, in a sense: How do you want to use it, or how do you think other people will use it. What commands exist which people might want to use it _with_. Where are you getting the values for your parameters? What are you doing with the output? Are you passing it to another command, formatting it for display?

Now, our goal is to design the command to make these scenarios that you come up with easier.

It's a good practice to start by writing down concrete examples of your answers to these questions, in pseudo code. It will help you get a feel for how you expect the command to work. When you do that, write them like this ...


--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="100px" data-background-color="#FFFFFF"  -->

### Write down your examples ...

```PowerShell
function Import-Configuration {
<#  .SYNOPSIS
        A command to load configuration for a module
    .EXAMPLE
        $Config = Import-Configuration
        Load THIS module's configuration from a command
    .EXAMPLE
        $Config = Import-Configuration
        $Config.AuthToken = $ShaToken
        $Config | Export-Configuration

        Update a single setting in the configuration
#>
```

note:

When you start writing out the concrete examples, write them like this ...

Hopefully, you recognize this as comment-based help for the command -- and I'm very serious. The first thing you should do when you start writing a command, is write the help.

---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# First, write help

We really require three things in the help:

1. A Synopsis and/or a short description
2. Examples -- for every parameter set
3. Documentation for each parameter

note:

I'm not suggesting you can write all of the help before you write the command, but ...

When you start writing down your ideas about how you're going to use the command, it can help you to visualize what you're going to be doing with the command, and that helps you think about the necessary parameters, what the output needs to be, etc.

I like to talk about the help you can't not write. That's three things:

1. A Synopsis

    First we need a synopsis or short description of the command. That's all it takes for the help system to engage, but describing it in a sentence can also help you to start thinking about the command: what it's job is, and what it's job is not.

    I encourage you to also write a full description, but for now, just write a synopsis (you'd probably get the description wrong anyway at this point). The synopsis is enough to get started.

2. An example -- for each parameter set

    Then we can write down our examples. At this stage, it's important that your examples aren't contrived. They should be the result of your brainstorming for how you want to use it. Each example should have an explanation of the purpose of using the command this way.

    In the simplest case, you can provide a single example (with no parameters), and a sentence explaining that this runs it with the default values (and explain what those are), and then explain what happens in that case.

    You don't need an example of every parameter, but you do need an example showing all of the _mandatory_ parameters for each parameter set.

    Now, maybe you don't know what those are yet, but these examples are long-lived, and you can update these and add more as you progress.

    It's might be worth saying that if you can't think of a real example for a parameter set -- you probably don't need that parameter set 😉.

    Long term, more examples are better, but only if they have significantly different _outcomes_. Examples showing parameters which just set properties on the output aren't necessary, because we're also going to write...

3. Parameter Documentation

   Documentation for each parameter. You can write this as you add parameters, by simply putting a comment above each one. In fact, I strongly recommend you do it that way (rather than using the `.PARAMETER` marker) because it's harder to forget to write and update!

The next thing we're going to do is ...

---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# Then write tests

## Remember this is design
- Write tests as documentation
- Document your intent and design
- Prove your implementation works

note:

We're going to mostly skip over testing, because that's an entirely different talk (or two or three), but let me say this:

You should approach tests as documentation. Think of them as documenting your intent, your design, and your examples, and ensuring that you don't break one of your own use cases at some point in the future.

Listen: If you're not writing tests, start. Grab Pester. Write some _acceptance tests_, and read a little about behavior-driven development. Have a look at Gherkin syntax.

But the bottom line is: make sure you have tests for each of the examples that we wrote above.

---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# Pick good names

Once you have some help and some tests in place, stop and think _again_ about naming things.

This really is the most crucial part of your design.

Parameter names define your user interface, but also your programming interface, affecting pipeline binding as well as discoverability.

note:

I know most of you spend some time thinking about what to name your commands right? What to name your functions or scripts. It's inevitable, because there are rules in PowerShell about naming.

But you _should_ be spending even more time thinking about the names of your parameters, because parameter names are not just about users discovering how to use your command, they're also the interface by which commands interact with each other.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

## Remember our example

- So far we have one parameter
- What should I call it?
    - Module
    - ModuleInfo
    - PSModuleInfo
- Maybe `ArgumentTransformation` for strings
- What about Get-Command & Get-Module

note:

    Show the Import-Configuration code

    So far we have one parameter. What should it's name be?

    Personally, I'm leaning toward ModuleInfo, because I think the "PS" looks like a module prefix that I should not use, and ModuleInfo makes it clear that I'm not just looking for a module _name_.

    However, I'm considering three things:

    1. Perhaps I could write a TypeAdapter for ModuleInfo to call get-module if you pass a string name. That would mean "Module" would be a good name anyway.
    2. What sorts of objects exist in PowerShell that might have a ModuleInfo as a property? CommandInfo!  It turns out that the output of Get-Command has a `Module` property which would work for this -- so even if I name it "ModuleInfo", I'll need to alias it as "Module" for that to work.
    3. The command that returns `PSModuleInfo` is `Get-Module` and most people probably don't know the type of object it returns.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

## Good parameter names

- Recognizable and specific
- Implicitly typed
- Distinct
- Consistent

note:

So what makes a good parameter name?

Obviously, it's a good name if users can tell what you want! Specifically, if a user can tell what information they need to pass to each parameter --and what form the data should take-- without needing to read the help.

So here are some guidelines for picking parameter names. Sometimes, these are going to cause conflicts in terms of not being able to meet all of them, but they are in priority order, and also -- you can use aliases to meet some of these goals.

Parameters should be:

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

### Recognizable and Specific

| Good | Better |
| ---- | ------ |
| `$Path` | `$FilePath` or `$DirectoryPath`
| `$Name` | `$FirstName` or `$FullName`


Users should know which value you actually want

note:

Users should be able to guess what you actually want. I put some examples here -- the idea is that more specific parameter names help people know what to pass in.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

### Implicitly Typed

| Good | Better |
| ---- | ------ |
| `$File` | `$FilePath` |
| `$TimeOut` | `$TimeOutSeconds` |
| `$Color` | `$ColorName` |

Users should know what types they can pass

note:

Users should be able to guess about what type of object is needed, or what the unit of measurement is, and what format the data should take (that is, you know "Red" not the css hex value #FF0000)

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

### Distinct

- Save typing by reducing common prefixes
- Avoid uncommon terms
- Avoid similarity
- Avoid duplication

| Good | Better |
| ---- | ------ |
| `$AllowClobber`, `$AllowPreRelease` | `$IgnoreCommandName`, `$AllowPrerelease` |


note:

Consider what happens if I use PSReadLine's `Ctrl+Space` to list parameters (look at Install-Package as a bad example!)

Multiple parameters that accept similar information in different ways might seem desireable for flexibility, but it will confuse users -- even if you put them in different parameter sets.

Ideally, each parameter would start with a different letter, and be a unique way to pass a specific piece of information. Less typing is better.

Here's another example: if you need a username and password, don't ask for `$UserName` and `$Password` -- ask for a `$Credential`. Don't offer both options either (that is: Credential _and_ UserName/Password). More is not better, it's just more.

It's ok to limit the ways a user can invoke your command (even if it means forcing them to create a credential), if it results in a dramatically clearer interface where there's only one representation of each piece of information, and it's more obvious.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

### Consistent

- Reuse parameter names ...
- Match properties on output objects
- Match properties on pipeline input

note:

Being consistent with parameter names across your module, or even parameter names on common PowerShell commands, will make it easier for users to learn and to guess based on their previous experience.

Also, when we're using parameter values as output properties, try to make the names match. Your users may be already familiar with the output object, but even if they're not, they'll learn your conventions faster if the name repeats consistently.

Finally, the same consideration applies to the names of properties which you want to use as input. Not only is consistecy important, it allows pipelining.

Don't forget that while you _can_ use aliases to resolve pipeline inputs and even handle user expectations, but when there are too many aliases, it can lead to confusion too -- it's a lot easier for users to follow if the names match up exactly...

---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# process first
#### Improve performance by reducing calls

- Most commands could participate in a pipeline
- Use `ValueFromPipelineByPropertyName`
- Or `ValueFromPipeline` (one parameter per set)

This improves performance! The overhead of initializing a command is substantial.

note:

Once you've written your help and tests, and put some thought into parameter names, it's time to start implementing.

You should start with the process block.

The reality is that initializing a command is expensive (commands are objects), so it's faster to pipe multiple things to a command than to call the command multiple times.

Obviously getting that improvement depends on your users calling your command that way, but you want to be able to do that.

I believe most commands should be able to participate in a pipeline -- and in order for you to write commands that can, you need to put some or most of the work in the process block, and make sure that any parameters you need to use there have the `ValueFromPipelineByPropertyName` (or `ValueFromPipeline`) in their attributes.

Basically, my position is that you should start by putting everything in the process block, and decorate all your parameters with `ValueFromPipelineByPropertyName`, and then remove logic from the process block as a performance optimization.


--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# Optimize process

What can we remove from process?

- Don't pre-optimize
- Begin and End blocks only run once
- Code there can't use pipeline parameters
- Setup and teardown code
- Test and validation code

note:

It's tempting to just leave everything in the process block, because that pretty much guarantees that the command will work the same way regardless of how it's called (with parameters or on the pipeline).

However, you should always look over your code before you're ready to share it and consider whether you can move code to the `Begin` or `End` block -- anything you can do once instead of every time will improve the performance of your command when it's in the pipeline!

Some obvious examples include setup and teardown code which doesn't need to be re-run each time, and which doesn't use values from your pipeline parameters can obviously be moved, but in general: re-examine your use cases! Look for parameters which you anticipate passing only as parameters, and never as pipeline values (for example, consider `-Destination` on a `Move` command), and see if you're doing anything with _just those parameters_ that could be moved to the `begin` or `end` blocks.

Remember: you can't _safely_ refer to any parameter that's set as `ValueFromPipelineByPropertyName` or `ValueFromPipeline` in the `begin` block -- but you _can_ collect those values for use in the `end` block.

---

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

# Customizing Types

Consider writing Classes or setting the `PSTypeName` on your outputs.

- Parameters bind to properties by name _and type_
- Formatting is customized by type
- Piping objects can communicate _a lot_ of data


note:

I want to leave you with some thoughts on custom objects.

In PowerShell, everything is an object, and the [Type] of a object is fundamental to the formatting of objects on screen. I don't have time to get into the intricacies of format files and so on, but I'll make the time to say:

When you're designing a set of commands that work together, you need to think beyond the function itself and think about your output objects as well. Consider what properties you need on the output, and which ones you really need to be visible by default. Consider what information you have available within each command that you might want to pass to other commands.

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

## What Type of Object?

- Built-in, Dynamic, Custom
- Write PowerShell Classes
- Write PowerShell Enums
- Constrain with `[PSTypeName(...)]`

note:

In PowerShell we deal in three general categories of objects: the built-in objects which are part of the .NET framework, such as the FileInfo,  dynamic objects (i.e. "PSCustomObject") such as those created by PowerShell when you use `Select-Object`, and custom objects defined by the functions and

However, there are lots of very good reasons that you should define your own object types.

1. When you want to customize formatting, your output will need a type name
2. When you need to pass a lot of data between commands, you'll want a name for a parameter type
3. When you want interactive objects, you'll want a custom type

A lof of the time, you can get away with just specifying a custom `PSTypeName` -- it's enough to let you format and even contrain inputs. However, it doesn't help users who are trying to tab-complete properties of your output objects, nor is it easy for users to create the objects to pass them as input.

Why do we care about types?

Probably the best interaction between functions is to take the output of one command as input to another -- but the best user experience is not necessarily an `InputObject` parameter of the specific type, sometimes it's better to accept the properties of the object as parameters. For one thing, it means that a `PSObject` will give you enough structure for pipelining. For another, it allows users to just pass values for each parameter. one much easier for users who do _not_ have the object to call your function, while still preserving the ease of use

--

<!-- .slide: data-background-position="top 0px left 0px" data-background="./images/bg.png" data-background-opacity="0.3"  data-background-size="228px" data-background-color="#FFFFFF"  -->

## Getting parameter values from the pipeline

- ValueFromPipeline
    - Input from specific other commands
    - Easy custom objects
- ValueFromPipelineByPropertyName
    - Properties from other commands
    - Speculatively allowed in-line

note:

Hopefully, you've already encountered the `[Parameter()]` attribute, and it's many switches. Two of them allow you to collect the value of the parameter from pipeline input:

- ValueFromPipeline allows you to create an `$InputObject` sort of parameter to collect each object. It's a good fit for when you only want to accept the output from one of your other functions, or when your objects are easy to construct (e.g have default constructors so you can easily build them from hashtables).

- ValueFromPipelineByPropertyName allows you to collect the value of a single property from each object. Of course, you can set up multiple parameters like this to collect multiple properties. This is a good fit when you don't have a specific object in mind, or when you only need the key identifier from it (e.g. `PSPath` for files).

---

<!-- .slide: data-background-position="bottom right" data-background="./images/header.png" data-background-opacity="1" data-background-size="368px" data-background-color="#FFFFFF"  -->

# Thank You
Please use the event app to submit a session rating

&nbsp;

https://github.com/Jaykul/DevOps2019

If you have good things to say,
I'm Joel Bennett

Otherwise, I'm Kirk Munro 😉


<img src="./images/cc-by-nc-sa.png" align="left" width="200px" style="border: 0px;">

