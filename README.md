# Shorthand

Shorthand is a code generating meta-programming framework meant to facilitate building a front-end using basic information already in your server code.

It is based around to major components: "rules" and MapServer.

## Rules

Rules are annotations which provide data for assembling apps, servers, documentation, and whatever else is possible.

They are designed to be flexible, extendable, and general-purpose so that you can have a basic app running with the addition of at least 3 rules per API URL.

While MapServer provides a web server to be used, it is not the only solution and this framework was built with the intention of being web server agnostic.

There are three main types of rules which are used in the framework, each of which can be extended as necessary, they are (in the order they should be listed above the function or variable they modify): Data Rules, External Rules, and Internal Rules.

### Data Rules

Data rules provide data points for the construction of components in the External Rules. They do little for changing the server and provide no functionality however are integral to the framework.

The @Input data rule, for example is used to tell the code generator what data is required in the URL to build a REST call.

The @Output data rule is used to build the data structures sent by the server indicating which values are used to build the next view, and which are displayed in the present view.

### External Rules

External rules are probably the most interesting part of the framework, they do the leg work for actually assembling documentation, app views, and hopefully more based on information gleaned through the Data Rules.

There are not many external rules made yet, however the goal is to build out a robust library of common app functions and data displaying widgets to simplify full stack development.

The best example available right now is the InternetList, which builds a flutter list using a JSON array that just simply works.

### Internal Rules

Internal Rules are used to build the API map used in the MapServer (detailed below). They are the link between the two core concepts of this framework.

The MapServer does routing based on a Map<String, (Function||Map)> structure and these rules build the map to be used by the server, as such there should only be one internal rule per function or variable.

For example, the @EndPoint rule designates a full URL and the remainder of the URL components are passed as a list, while @Route, builds a Map in the map for additional routes.

Not all internal rules require a function or a map, @StaticContent may be used to load a file or sting into memory and loads it into a function to be called by the MapServer.

## MapServer

MapServer is a minimal, proof-of-concept web server used to build RESTful APIs which interact with the "rule" generated apps.

Funny enough, this is how the whole project started but as I began to build I saw a different potential and direction I needed to focus on.

As of now, it is purely proof of concept and does not allow for much beyond something to help get you off the ground, however for these purposes it does work.

## Shorthand Future

Things I am currently working on to improve Shorthand:

- Legacy code/script support using commands in Internal Rules (and by extension, MapServer).

- MapServer/Internal Rule authentication and conversion of inputs to a single map object

- Modularizing functionality from design in external rules. 

- HTML front-end code generation (Ideally using AngularDart, although due to the long to-do list first iteration will likely be straight JS/HTML)

- Integration with other web server frameworks (such as Jaguar and Angel), not that I want to give up on MapServer but I want this to help as many people as necessary

### Note from the Developer

This is my first published project I plan to maintain, let alone project in Dart, I am very excited by this technology. If you share the same passion for Dart creating a workflow between servers and clients together please feel free to reach out and join the team, I think we could really make the world a better place.