# PragmaticContext

PragmaticContext allows you to declaratively contextualize your
ActiveModel objects in terms of Linked Data concepts, giving you an easy way to
get your models talking JSON-LD.

## What's JSON-LD?

I'm glad you asked. [JSON-LD](http://json-ld.org/) is a lightweight JSON format
for expressing data within a context (also known as 'Linked Data'). Essentially
what this means is that it lets you say that the thing your data model calls
a 'last_name' (and what someone else may call 'family_name', or 'surname', or 'apellido') are all embodiments of the same abstract idea of a [Family
Name](http://xmlns.com/foaf/spec/#term_familyName). JSON-LD is similar in spirit
(though [vastly different in
execution](http://manu.sporny.org/2014/json-ld-origins-2/)) to
[RDF](http://en.wikipedia.org/wiki/Resource_Description_Framework). It allows
users of your application to unambiguously establish the place of your application's data
within a larger universe by placing it in context.

If you're just getting started with JSON-LD, I highly recommend the [JSON-LD 1.0 W3C
Recommendation](http://www.w3.org/TR/json-ld/) (really. Start at section 5).
It's a straightforward description of JSON-LD's purpose and structure, and
should be an easy read for anyone who already uses JSON. I wish more standards
documents were written this way. Seriously, it's great.

## An example

As an example, let's consider the following Mongoid document:

    class Person
      include Mongoid::Document

      field :first_name
      field :last_name
      field :email
    end

As implemented above, a Person object has a first name, a last name, an email
address, and would serialize to JSON as something like:

    { 
      "first_name": "Mat",
      "last_name": "Trudel",
      "email": "mat@geeky.net"
    }

While that's usually clear enough to a human interacting with your API, the
field names chosen are basically arbitrary, and are difficult to process in any
automated way. Ideally, your field names should be able to unambiguously
identify a field as representing the concept of a person's first
name, whether the field was named 'first_name', 'FirstName', 'given_name', or
even 'field1234'. By allowing you to contextualize your data, JSON-LD lets you
essentially say "when I say 'last_name', I really mean
`http://xmlns.com/foaf/0.1/familyName`". In so doing, it becomes possible to
associate the last name fields of any JSON-LD API, regardless of what they name
their fields.

## Isn't this just a re-invention of RDF?

Yes and no. While it's true that JSON-LD is a valid RDF serialization format,
this [wasn't one of its original design
goals](http://manu.sporny.org/2014/json-ld-origins-2/). My intent with
PragmaticContext is to allow developers who already work with JSON data to be
able to easily turn it into Linked Data without having to know or care about RDF
at all. At a basic level, the concepts of Linked Data should be grokkable by
anyone who already understands the basic concepts of APIs in general. JSON-LD's
creator Manu Sporny says it best:

> I’ve heard many people say that JSON-LD is primarily about the Semantic Web,
> but I disagree, it’s not about that at all. JSON-LD was created for Web
> Developers that are working with data that is important to other people and
> must interoperate across the Web. The Semantic Web was near the bottom of my
> list of “things to care about” when working on JSON-LD, and anyone that tells
> you otherwise is wrong

In terms of my personal approach to developing PragmanticContext, I'm
consciously not considering RDF as entering into the equation at all. With
PragmaticContext, I'm playing the role of an API developer already steeped in
JSON who wants to make their data more expressive without having to slow down
or learn a new stack. While I personally understand RDF's role and potential,
I'm willfully ignoring it with the goal of producing a library relevant to JSON
API developers. My thesis is that if JSON-LD is to be relevant to existing JSON
API developers, it needs to do so as a natural outgrowth of their existing
environment.

## Installation

Add this line to your application's Gemfile:

    gem 'pragmatic_context'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pragmatic_context

## Usage

PragmaticContext is implemented as a module that you mix into your existing
ActiveModel objects. Taking the `Person` model above, you would add context to
it like so:

    class Person
      include Mongoid::Document
      include PragmaticContext::Contextualizable

      field :first_name
      field :last_name
      field :email

      contextualize :first_name, :as => 'http://xmlns.com/foaf/0.1/givenName'
      contextualize :last_name, :as => 'http://xmlns.com/foaf/0.1/familyName'
      contextualize :email, :as => 'http://xmlns.com/foaf/0.1/mbox'
    end

This gives Pragmatic Context everything it needs to be able to create JSON-LD
representations of your model objects. Getting at these representations is
discussed in the following section.

### Getting at a JSON-LD representation

The `Contextualizable` mixin adds a `as_jsonld` method that returns a Hash
representation of your object, ready for serialization. Calling this method on
the `Person` object described above will produce the following JSON-LD document:

    { 
      "@context": {
        "first_name": { "@id", "http://xmlns.com/foaf/0.1/givenName" },
        "last_name": { "@id", "http://xmlns.com/foaf/0.1/familyName" },
        "email": { "@id", "http://xmlns.com/foaf/0.1/mbox" },
      },
      "first_name": "Mat",
      "last_name": "Trudel",
      "email": "mat@geeky.net"
    }

A couple of things to note about this implementation:

* `as_jsonld` will only serialize fields that have matching `contextualize`
  statements. This is in keeping with JSON-LD's convention of ignoring fields in
  a document which do not have a context defined.
* The produced JSON-LD document embeds the context directly in the document,
  within the `@context` field.
* For each field present in your object's `as_json` method *that has a matching
  `contextualize` statement*, `as_jsonld` will:
    * If the field is a primitive value (string, number, boolean, nil), its
      value will be copied directly from the output of `as_json`
    * If the field is a nested object which includes `Contextualizable`, it is
      recursively converted to JSON-LD by calling its `as_jsonld` method
    * If the field is a Hash, its keys are copied over to the parent document's
      representation, namespaced as per the field's `contextualize` statement.
      More info on this case is given below.

#### Hash subdocuments and namespacing

As dicsussed above, subdocuments which are also `Contextualizable` are
automatically recused into and serialized into the output of `as_jsonld`. This
behaviour should be pretty straightforward to understand and make use of, but
doesn't clearly cover the case where you may want to refer to concepts in
separate vocabularies with similar names. In this case, Pragmatic Context
allows for namespacing based on nested hashes.

*This is an advanced use case and probably only useful if you know that you need
it. If this doesn't make sense to you, feel free to ignore it.*

Nested hashes which have a corresponding `contextualize` statement are copied into the
parent document within a namespace. This may seem confusing at first, but is
done principally to realize use cases such as the following:

    class CreativeWork
      include Mongoid::Document
      include PragmaticContext::Contextualizable

      field :dc, type: Hash
      field :mods, type: Hash

      contextualize :dc, :as => 'http://purl.org/dc/terms/'
      contextualize :mods, :as => 'http://www.loc.gov/mods/rdf/v1#'
    end

This allows for both dc['title'] and mods['title'] to be set to independent
values, and for the resulting document to serialize out as something like:

    {
      "@context": {
        "dc": "http://purl.org/dc/terms/",
        "mods": "http://www.loc.gov/mods/rdf/v1#',
      },
      "dc:title": "The value of dc['title']",
      "mods:title": "The value of mods['title']"
    }

### Custom serializers

If you want to refer to your JSON-LD context by URI (see Example 4 in the [JSON
spec](http://www.w3.org/TR/json-ld) for more info), or if you want to use your
own serializer to customize the JSON-LD representaions you produce, you'll want
to make use of the `Contextualizable` mixin's `jsonld_context` method.  `jsonld_context`
returns a Hash object ready to be serialized into the `@context` field of the
output object. By wiring this up in whatever serializer your application uses,
you can easily extend custom serializations to output
valid JSON-LD.


### Dynamic documents & more complicated cases

There are cases (especially using Monogid's dynamic fields feature) where the
list of an object's fields is not known at class load time. In these cases, it's
possible to defer contextualization to a custom `Contextualizer` class
configured like so:

    class Person
      include Mongoid::Document
      include PragmaticContext::Contextualizable

      #
      # Machinery for defining fields, either static or dynamic
      #

      contextualize_with CustomContextualizer
    end

    class CustomContextualizer
      def definitions_for_terms(terms)
        # Returns a hash of terms => term definitions
      end
    end

Examples of this are forthcoming.

## Contributing

1. Fork it ( http://github.com/mtrudel/pragmatic_context/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
