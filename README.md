# Overview

This is a new experience in using Erlang to me. I had some experience in writing in Erlang before this, but never in terms of writing any kind of game or even a gui program. Mostly I've written stateful machines, data structures and patterns. I wanted to know what more it could be used for, and this command line game was a perfect opportunity to expand my skills.

I implemented a tic tac toe game server in Erlang using the OTP `gen_statem` behavior. The software models the game as a finite state machine with clear states for playing and game over, manages all game rules and turn logic internally, and exposes a small public API for submitting moves, resetting the game, and inspecting state. It demonstrates core Erlang concepts such as immutable data, pattern matching, message-based interaction, and OTP behaviours, and optionally includes a simple AI player to show how automated decision logic can be integrated into a concurrent Erlang process.

My purpose of this was simply to grow my knowledge and skills in the Erlang language, and add a new project I can demonstrate to my resume.

{Provide a link to your YouTube demonstration.  It should be a 4-5 minute demo of the software running and a walkthrough of the code.  Focus should be on sharing what you learned about the language syntax.}

[Software Demo Video](http://youtube.link.goes.here)

# Development Environment

This program utilizes the Erlang language and rebar3 to compile and run. I developed it inside of Visual Studio Code. It utilizes OTP `gen_statem` libraries.

# Future Work

* Code optimization. I would like to go through and make sure everything is optimized and there are no bugs missed during testing.
* A GUI with a more simple interface for running the game