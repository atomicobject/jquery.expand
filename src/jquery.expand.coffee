# *jquery.expand* is a templating plugin for jquery.
#
# *expand* tries to be to templating what CSS is to styling. Templating is unobtrusive.
# In fact, templates are just normal DOM nodes. Transformations on the templates
# are specified via a powerful JSON DSL.
#
# Basic usage is `$(cssSelector).expand(directive)` which returns a new,
# detached DOM node (wrapped in a jquery object) to be inserted back in the dom
# wherever you want.
#
# Let's start with a simple example
#
#     <div id="adr-template" class="adr">
#       <div class="street-address"></div>
#       <div class="extended-address"></div>
#       <span class="locality"></span>,
#       <span class="region"></span>
#       <span class="postal-code"></span>
#       <div class="country-name"></div>
#     </div>
# 
# This element can be used as a template like this:
#
#     var myAdr = $("#adr-template").expand({
#       "street-address": "941 Wealthy St SE",
#       "locality": "Grand Rapids",
#       "region": "MI",
#       "postal-code": "49506",
#       "country-name": false
#     });
#
# After executing, the variable `myAdr` has a reference to a new, jQuery-wrapped
# DOM node that is not attached to the DOM. You can then manipulate myAdr if desired,
# or add it directly to the body. In this case, the resulting node has markup like this:
# 
#     <div class="adr">
#       <div class="street-address">941 Wealthy St SE</div>
#       <div class="extended-address"></div>
#       <span class="locality">Grand Rapids</span>,
#       <span class="region">MI</span>
#       <span class="postal-code">49506</span>
#     </div>
#
# The value passed to `expand` is called a directive. Directives are Javascript objects
# which are crawled recursively to mutate the pattern DOM node. Most native Javascript types
# are supported as directives, and the interplay between the different types is both
# powerful and nuanced. In most cases, the meaning of a type is what intuitively makes sense,
# and using expand is pretty natural once you get used to thinking analogously about the DOM
# and JSON (actually JavaScript) directives.

$ = jQuery

$.fn.expand = (directive) ->
  element = 
    if this[0].nodeName == "SCRIPT" 
      $this = $(this)
      node = $this.data("expand-node")
      if !node
        node = $(this.html())
        $this.data("expand-node", node)
      $(node[0].cloneNode(true))
    else
      $(this[0].cloneNode(true)).
        removeAttr("id")

  expandTemplateInPlace(element, directive)
  return element

# 
# Types of Directives
# ==================
expandTemplateInPlace = (element, directive) ->
  #
  # Simple Directives
  # -------------------
  # `null`, `undefined`, and `true` all cause the element to be left untouched.
  return element[0] if directive in [null, undefined, true]

  # `false` causes the element to be removed.
  if directive == false
    element.remove()

  # numbers, strings, and jquery (dom) objects are set as the inner html of the element.
  else if typeof(directive) in ["number", "string"] or directive instanceof jQuery
    element.html directive


  # Functions
  # ----------------
  #
  # Functions are very powerful. They're passed the new HTML element (wrapped
  # in a jQuery object) that will be included in the output, and can affect
  # it in one of two ways.
  #
  # The first option is to simply mutate the element in place. At the point
  # at which the directive is applied, the element is detached from the DOM and so
  # can be mutated efficiently. The function can change the element or remove
  # it and it will have the desired effect. The invocation also binds the jquery
  # object to `this` so either normal functions of one argument or jquery.fn- and
  # event handler-style functions can be used.
  #
  # The second option is to return a new directive. Expand recurses on the
  # return value of the function. In this way, a null or undefined return
  # value has no effect, but there's a lot of power here. You can use a
  # predicate function as a directive, and a false return value will cause the
  # element to be removed.

  else if $.isFunction directive
    return expandTemplateInPlace element, directive.call(element, element)


  # Arrays
  # ------------------
  #
  # Arrays are a little tricky, but match up very well with HTML once
  # you're used to them. When the directive is an array, the first child of the
  # element is cloned once for each element of the array, and the array
  # element is used as a directive with which to expand the cloned element. For
  # example, if your template is
  #
  #     <ul>
  #       <li></li>
  #     </ul>
  #
  # and your directive is `[1,2,3]`, then the `li` is cloned once for each array element, and the
  # result is
  #
  #     <ul>
  #       <li>1</li>
  #       <li>2</li>
  #       <li>3</li>
  #     </ul>
  # 
  else if directive.constructor == Array
    childTemplate = element.children()[0]
    fragment = document.createDocumentFragment()
    jq = $([1])
    if childTemplate
      for matchDirective in directive
        node = childTemplate.cloneNode(true)
        fragment.appendChild node
        jq[0] = node
        expandTemplateInPlace jq, matchDirective
    element.html fragment

  # Objects
  # ------------------
  #
  # Object directives are a lot like arrays in that they represent a
  # combination of simpler directives to perform on children of an element. Just as an
  # object's properties are the constituent elements defining the object, an
  # directive object's properties are the constituent elements of the
  # directive to be performed. 
  #
  # ### Classes
  #
  # The simplest type of object directive is what you'd normally see in a JSON
  # object. Let's say you had an object called `name` defined by 
  #
  # `{ first_name: "John", last_name: "Smith" }` 
  #
  # returned by an AJAX call, and you want to populate a few elements on the
  # page, with the template:
  #
  #     <div id="name">
  #       <span class="first_name"></span>
  #       <span class="last_name"></span>
  #     </div>
  #
  # In this simple (contrived) example, you could use interpolate your name
  # elements by simply calling `$("#name").expand(name)`. The result would be
  # a jquery object with the html
  #
  #     <div id="name">
  #       <span class="first_name">John</span>
  #       <span class="last_name">Smith</span>
  #     </div>
  #
  # To clarify, any property whose name is a simple (alphanumeric) string
  # assumes the property name is a class name and uses the value of the
  # property as a directive to expand *every* element with that class within
  # the surrounding context.
  #
  # To take things a step furthery, it's important to realize that these
  # contexts stack.  If the value associated with a property is another
  # object, that object is used to expand only the element(s) matched by the
  # key. This is just like CSS selectors. A directive like
  #
  # `{foo: {bar: "baz"}}`
  #
  # Will cause all elements with class "bar" somewhere beneath an element
  # with class "foo" to have their inner html set to "baz". However, elements
  # with class "bar" that are not within a "foo" will not be affected.

  else if typeof(directive) == 'object'
    jq = $([1])
    for own propertyName, property of directive
      for rule in KEY_SYNTAX
        result = rule.call element, propertyName, property, jq
        break if result != false

  element[0]

KEY_SYNTAX = [
  # ### Attributes
  # 
  # An `@` prefix on a property name causes an attribute to be set on the
  # element. For example
  #
  # `{"@href": "http://www.atomicobject.com"}`
  #
  # will have the href attribute set on the corresponding element. This can
  # only take a string or numeric value.

  (propertyName, analog) ->
    match = /^@([\w-]+)$/.exec(propertyName)
    return false unless match
    this.attr(match[1], analog)
    return null

  # ### Properties
  # 
  # An `:` prefix on a property name causes a property to be set on the
  # element. For example
  #
  # `{":checked": true}`
  #
  # will have the checked property set on the corresponding element.      
  
  (propertyName, analog) ->
    match = /^:([\w-]+)$/.exec(propertyName)
    return false unless match
    this.prop(match[1], analog)
    return null

  # ### Function properties
  #
  # A `()` suffix on a property name causes a function to be called on the
  # corresponding jquery object. This is especially useful for adding or
  # removing classes or setting inner text or form values. The value of the
  # property is passed as an argument.
  #
  # For example:
  #
  # * `$("#foo").expand({"text()": "foo"})` will have inner text foo.
  # * `$("#foo").expand({"val()": "foo"})` will have the form element's value set to "foo".
  # * `$("#foo").expand({"addClass()": "foo"})` will have the class "foo" added.
  # * `$("#foo").expand({"removeClass()": "foo"})` will have the class "foo" removed.
  #

  (propertyName, analog) ->
    match = /^(\w+)\(\)$/.exec(propertyName)
    return false unless match
    this[match[1]].call(this, analog)
    return null

  # ### Composition
  #
  # "." as a property name causes expansion to be continued on the current element
  # with the value. One use of this is to decorate a directive parameter with additional 
  # directives, or to set attributes and expand contents with an array simultaneously.
  #
  # For example:
  #
  #     $("#mylist").expand({
  #       "addClass()": "emphasized", 
  #       ".": someArray})
  #
  # will add the `emphasized` class to `#mylist` and expand the first child repeatedly for each entry
  # in someArray.

  (propertyName, analog) ->
    if propertyName == "."
      expandTemplateInPlace(this, analog)
      return null
    else
      false


  # ### Arbitrary selectors
  #
  # *Expand* isn't limited to just selecting elements to expand by class
  # names. A `$` prefix on property name will cause the rest of the name
  # to be used as an arbitrary css selector. For example, 
  #
  # * `{'$.bar, .baz': "asdf"}` will set the inner html of bar an baz elements to "asdf".
  # * `{'$a[title]': function(el){ el.append(" (" + el.attr("title") + ")"); }}` will add a parenthetical explanation to the text of each link with a title attribute.
  # * `{'$:text': {"val()": "foo"}}` will set the text of all text inputs/textareas to "foo".

  (propertyName, analog, jq) ->
    directive =
      if propertyName.charAt(0) == "$"
        propertyName.slice(1)
      else
        "." + propertyName
    matches = this.find directive
    for match in matches
      jq[0] = match
      expandTemplateInPlace jq, analog 
    return null
]

$.expand =

  # Composition 
  # -------------
  #
  # Expand comes with a rudimentary composition function.
  # `$.expand.compose(directive1, directive2,...)` will return an object that can be used
  # as a directive which is equivalent to applying the argument directives
  # in order.
  #
  # If all the directives are predicate functions, $.expand.compose is equivalent
  # to an `&&` operation on the results of the functions.
  
  compose: () ->
    directives = arguments
    return (element) ->
      for directive in directives
        expandTemplateInPlace element, directive
        break if directive == false
      return null

# expandInPlace
# =================
#
# You can also use `expandInPlace` to update a template in place. This needs to be used carefully,
# however. Since you're changing the template node, it's possible to change it in a way that it will
# not work the same way in subsequent calls (if nodes are removed, for example). The DOM is also updated while the node
# is attached, potentially leading to performance problems as the browser redraws the page.
$.fn.expandInPlace = (directive) ->
  expandTemplateInPlace($(element), directive) for element in this
  return this


# License
# =============
#
# *expand* is licensed under the MIT license.
#
# Author
# ======
# 
# * Drew Colthorp (colthorp@atomicobject.com)
# * © 2011 [Atomic Object](http://www.atomicobject.com/)
# * More Atomic Object [open source](http://www.atomicobject.com/pages/Software+Commons) projects
