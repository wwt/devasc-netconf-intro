# DEVASC Associate NETCONF Intro Hands-On Lab Guide

## :fontawesome-solid-laptop-code: Overview

What's the big fuss over IT automation?  Well, more than anything, the excitement is about the sorts of things that you _don't_ have to do when automation is on your side.  Things like _not_ having to either copy and paste configuration changes to dozens (maybe hundreds) of different systems or repeat the same click, click, click, click, click-through-the-UI marathon over, and over, and over..._every single time_ there's a need to make a bulk change :rage:.

To automate configuration and management workflows for network devices, we need to learn to write some form of automation-specific code, and the **NETCONF** protocol makes that possible.  **NETCONF** provides a programmatic way to automate the network device workflows based on the predictable data structures found in YANG models.

This guide will walk you through some hands-on exercises that help teach and give you a place to practice using Python to automate workflows with **NETCONF**.  You'll get the most from these exercises if you have some familiarity with:

- :fontawesome-brands-python: Python fundamentals.
- :fontawesome-solid-code: Managing and transposing structured data between XML and Python objects.
- :material-code-json: Interpreting YANG models.

---

### :fontawesome-solid-file-code: Unstructured vs Structured Data

#### Data Meant for Humans to Read

When we interact with the CLI of a network device, we typically send text commands and receive text responses.  Usually, the responses to our commands are in plain text, in an **unstructured** format.  We often see the raw text responses formatted with various spaces, tabs, numbering, tables, or even text-based graphics, to make the text easier for humans to read.

---

#### Data Meant for Computers to Read

When a computer, such as an automation system, tries to read that same, **unstructured** data, we usually have to tell the computer precisely how it needs to find the information we need.  That is, we have to write some form of a search pattern, or **parser**, to sift through all of the spaces, special characters, and text graphics, etc., to find the specific, raw data we want.  Parsing through unstructured data is often difficult to configure, temperamental to test successfully, and a headache to maintain.  Plus, anytime an IT system undergoes a software or hardware change, the unstructured command response a parser expects can change, even if by a single character, and cause the parser to fail or work improperly.

---

#### The NETCONF Protocol

So, how do we automate configuration and management workflows for network devices and avoid having our lives consumed by the "joy" of writing and maintaining text parsers?  Fortunately, the NETCONF protocol, defined in [IETF RFC 6241](https://datatracker.ietf.org/doc/html/rfc6241 "IETF RFC 6241"){target=_blank}, allows us to use code to automate how we configure and manage network devices using open-source or OEM-proprietary **structured** YANG data models.

Using [openly available YANG models](https://github.com/YangModels/yang "YANG Model Git Repository"){target=_blank}, our automation code can programmatically interact with network devices at scale because NETCONF uses XML to structure the data it sends between NETCONF clients[^1] and NETCONF servers[^2].

---

## :fontawesome-solid-code: A Practical Example

Here is an example of data returned by a network device in response to a CLI command compared with the same data returned by a network device in response to a NETCONF RPC.  Now, unless you happen to be a computer, you will probably find the CLI example (**unstructured data**) a bit easier to read than the NETCONF example (**structured data**).

---

### :fontawesome-regular-file-code: A Side-by-Side Comparision

???+ abstract "Example Network Device CLI and NETCONF Response Data"

    Even though the CLI and NETCONF data formats look drastically different, they both provide the _exact_ same data.

    === "CLI Response Output - Unstructured Data"
        ```text
        --8<-- "includes/data_cli.txt"
        ```

    === "NETCONF Response Output - Structured Data"

        ```xml
        --8<-- "includes/data_xml.xml"
        ```

---

### :fontawesome-brands-python: Comparing the Code

If you're thinking, _"Why would I ever want to deal with the **structured data** in a NETCONF RPC reply? It looks like a mess!"_  Well, to put it simply, **structured data** in NETCONF RPCs is _way_ easier to work with **programmatically**.  Take a look at how we might parse both the CLI and NETCONF responses with some Python code:

???+ note "Example Code Exercise"

    This exercise aims to parse the interface ID from each of the CLI and NETCONF response data sets.  For reference, the correct result of a search for the interface ID is the text **1/10**.  These examples assume the CLI and NETCONF data sets are already available to the Python interpreter in the variable with the name **`data`**.

    - Even though the CLI response data is only a few lines long, the Python code to parse the interface ID from that data, with a regular expression, is lengthy and somewhat complex to read.
    - By contrast, even though the NETCONF response data is lengthy, the Python code to parse the interface ID is short and far less complex to read.

    ??? example "Click to view the code examples"

        === "Parse the Unstructured (CLI) Response"
            ```python linenums="1" hl_lines="5-17 19 21-25"
            --8<-- "includes/parse_unstructured.py"
            ```
    
        === "Parsing the Structured (NETCONF) Response"
            ```python linenums="1" hl_lines="5-9"
            --8<-- "includes/parse_structured.py"
            ```

---

All right, that's enough reading for now.  It's time to get into the lab exercises and get some real practice.  If everything to this point makes perfect sense to you, great!  If not, don't worry because you're about to get plenty of hands-on repetitions with functional code.  [Click here to continue to the next section](sections/section_1.md "Hands-On Lab Setup").

[^1]: NETCONF documentation often uses the terms **managers** and **clients** interchangeably to describe management workstations or servers.
[^2]: NETCONF documentation uses the terms **agents**, **devices**, and **servers** interchangeably to describe network devices.

--8<-- "includes/glossary.txt"
