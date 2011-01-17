# *jquery.expand* is a templating plugin for jquery.
#
# *expand* tries to be to templating what CSS is to styling. Templating is unobtrusive.
# In fact, templates are just normal DOM nodes. Transformations on the templates
# are specified via a powerful JSON DSL.
#
# Basic usage is `$(cssSelector).expand(expansionValue)` which returns a new,
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
# or add it directly. The resulting node has markup like this:
# 
#     <div class="adr">
#       <div class="street-address">941 Wealthy St SE</div>
#       <div class="extended-address"></div>
#       <span class="locality">Grand Rapids</span>,
#       <span class="region">MI</span>
#       <span class="postal-code">49506</span>
#     </div>
#
# This simple example is just the tip of the iceberg. The templating "language" spans
# the entire tower of types provide by JSON, and powerful mechanisms for manipulating
# are provided through different key syntaxes.
# 
# Types of patterns
# ==================
#
# Simple patterns
# -------------------
(($) ->
  expandTemplateInPlace = (element, expansion) ->
    # `null`, `undefined`, and `true` all cause the element to be left untouched.
    return element[0] if expansion in [null, undefined, true]

    # `false` causes the element to be removed.
    if expansion == false
      element.remove()

    # numbers, strings, and jquery (dom) objects are set as the inner html of the element.
    else if typeof(expansion) in ["number", "string"] or expansion instanceof jQuery
      element.html expansion


    # Functions
    # ----------------
    #
    # Functions are very powerful. They're passed the new HTML element (wrapped
    # in a jQuery object) that will be included in the output, and can affect
    # it in one of two ways.
    #
    # The first option is to simply mutate the element in place. At the point
    # at which expansion happens, the element is detached from the DOM and so
    # can be mutated efficiently. The function can change the element or remove
    # it and it will have the desired effect.
    #
    # The second option is to return a new pattern. Expand recurses on the
    # return value of the function. In this way, a null or undefined return
    # value has no effect, but there's a lot of power here. You can use a
    # predicate function as a pattern, and a false return value will cause the
    # element to be removed.

    else if $.isFunction expansion
      return expandTemplateInPlace element, expansion(element)


    # Arrays
    # ------------------
    #
    # Arrays are a little tricky, but matches up very well with HTML once
    # you're used to it. When the pattern is an array, the first child of the
    # element is cloned once for each element of the array, and the array
    # element is used as a pattern with witch to expand the cloned element. For
    # example, if your template is
    #
    #     <ul>
    #       <li></li>
    #     </ul>
    #
    # and your pattern is `[1,2,3]`, then the `li` is cloned once for each array element, and the
    # result is
    #
    #     <ul>
    #       <li>1</li>
    #       <li>2</li>
    #       <li>3</li>
    #     </ul>
    # 
    else if expansion.constructor == Array
      childTemplate = element.children()[0]
      fragment = document.createDocumentFragment()
      if childTemplate
        for matchExpansion in expansion
          expanded = expandTemplateInPlace $(childTemplate).clone(true), matchExpansion
          fragment.appendChild expanded
      element.html fragment

    # Objects
    # ------------------
    #
    # Object patterns are a lot like arrays in that they represent a
    # combination of simpler expansions to perform on the element. Just as an
    # object's properties are the constituent elements defining the object, an
    # expansion object's properties are the constituent elements of the
    # expansion to be performed. 
    #
    # ### Classes
    #
    # The simplest type of object pattern is what you'd normally see in a JSON
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
    # property as a pattern to expand *every* element with that class within
    # the surrounding context.
    #
    # To take things a step furthery, it's important to realize that these
    # contexts stack.  If the value associated with a property is another
    # object, that object is used to expand only the element(s) matched by the
    # key. This is just like CSS selectors. A pattern like
    #
    # `{foo: {bar: "baz"}}`
    #
    # Will cause all elements with class "bar" somewhere beneath an element
    # with class "foo" to have their inner html set to "baz". However, elements
    # with class "bar" that are not within a "foo" will not be affected.

    else if typeof(expansion) == 'object'
      syntax = $.expand.KEY_SYNTAX
      for own propertyName, property of expansion
        for own _, rule of syntax
          result = rule.call element, propertyName, property
          expandTemplateInPlace $(result.expand), result.withExpansion if result && typeof(result) == "object"
          break if result != false

    element[0]

  $.expand =
    KEY_SYNTAX:

      # ### Attributes
      # 
      # An `@` prefix on a property name causes an attribute to be set on the
      # element. For example
      #
      # `{"@href": "http://www.atomicobject.com"}`
      #
      # will have the href attribute set on the corresponding element. This can
      # only take a string or numeric value.
      
      "@attributes": (propertyName, analog) ->
        match = /^@([\w-]+)$/.exec(propertyName)
        return false unless match
        this.attr(match[1], analog)
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
      
      "fn()": (propertyName, analog) ->
        match = /^(\w+)\(\)$/.exec(propertyName)
        return false unless match
        this[match[1]].call(this, analog)
        return null


      # ### Arbitrary selectors
      #
      # *Expand* isn't limited to just selecting elements to expand by class
      # names. A `$` prefix on property name will cause the rest of the name
      # to be used as an arbitrary css selector. For example, 
      #
      # * `{'$.bar, .baz': "asdf"}` will set the inner html of bar an baz elements to "asdf".
      # * `{'$a[title]': function(el){ el.append(" (" + el.attr("title") + ")"); }}` will add a parenthetical explanation to the text of each link with a title attribute.
      # * `{'$:text': {"val()": "yo"}}` will set the text of all text inputs/textareas to "yo".

      "class or css selector": (propertyName, analog) ->
        pattern =
          if propertyName.charAt(0) == "$"
            propertyName.slice(1, propertyName.length)
          else
            "." + propertyName
        matches = this.find pattern
        expandTemplateInPlace $(match), analog for match in matches
        return null

    # Composition 
    # -------------
    #
    # Expand comes with a rudimentary composition function.
    # `$.expand.compose(pat1, pat2,...)` will return an object that can be used
    # as a pattern which is equivalent to all of the patterns listed above
    # (specifically, applied in order).
    #
    # If all the patterns are predicate functions, $.expand.compose is equivalent
    # to an `&&` operation on the results of the functions.
    
    compose: () ->
      expansions = arguments
      return (element) ->
        expandTemplateInPlace element, expansion for expansion in expansions
        return null

  $.fn.expand = (expansion) ->
    element = $(this[0]).clone(true)
    element.removeAttr "id"
    expandTemplateInPlace(element, expansion)
    return element

  # expandInPlace
  # =================
  #
  # You can also use `expandInPlace` to update a template in place. This needs to be used carefully,
  # however. Since you're changing the template node, it's possible to change it in a way that it will
  # not work in the future (if nodes are removed, for example). The DOM is also updated while the node
  # is attached, potentially leading to performance problems as the browser redraws the page.
  $.fn.expandInPlace = (expansion) ->
    expandTemplateInPlace($(element), expansion) for element in this
    return this

)(jQuery)


# License
# =============
#
# *expand* is licensed under the MIT license, copyright [Atomic Object](http://atomicobject.com).
