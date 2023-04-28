# Task
Your goal is to write a class that can be used to manage events and their handlers.
​
The class should work like this:
- It has a `subscribe` method, which takes a block and stores it as a handler
- It has an `unsubscribe` method, which takes a block and removes it from its list of handlers
- It has an `broadcast` method, which takes an arbitrary number of arguments and calls all the stored blocks with these arguments

## Note
- This should be fully tested using RSpec (the test suite is part of the requirements)
- You should not worry about the order of handlers' execution
- The handlers will not attempt to modify an event object (e.g. add or remove handlers)
- The context of handlers' execution is not important
- Each handler will be subscribed at most once at any given moment of time. It can still be unsubscribed and then subscribed again

# Run
## Build
```bash
docker build -t uplisting-technical-exercise .
```

## Lint & test
```bash
docker run -t uplisting-technical-exercise
```

This will execute (in order):
- rspec
- standardrb
- reek
- rubocop

All tests should pass. Lints should all be green.

## Custom commands
To execute custom commands, with files mounted, run:
```bash
docker run -it -v `pwd`:/usr/src/app uplisting-technical-exercise bash
```

# Discussion
## Handler equality
There is no good way to compare procs. Hence `subscribe` and `unsubscribe` methods can only make very basic checks, to see if the same handler object is already in the handlers list.

It is possible to compare procs based on their source. This would allow for a more precise handling when adding or removing handlers from the handlers queue.

However this approach is more involved and might not be necessary; an alternative approach would be to require handlers have a name. When subscribing and unsubscribing handlers, checks would then rely on the name to detect handler presence.

Another option would be to implement the the handlers as an instance of (for example) `Handler` class that respond to `call`. More control over their execution and failur modes would be handled there. An implementation of handler equality could be provided on that class directly.

## Handler failures
Current implementation allows handlers to fail and logs the error. This is to prevent one failing handler from blocking the rest.
To get more control over the failed handlers, they could be moved to a separate queue `failed_handlers`. Failed handlers could then be handled separately i.e. disabled, re-run, re-run with backoff etc.
