# *jquery.expand* is a templating system that 
(($) ->
  expandTemplateInPlace = (element, expansion) ->
    return element[0] if expansion in [null, undefined, true]

    if expansion == false
      element.remove() 

    else if /^(?:number|string)$/.test(typeof(expansion)) || expansion instanceof jQuery
      element.html expansion

    else if expansion.constructor == Array
      childTemplate = element.children()[0]
      fragment = document.createDocumentFragment()
      if childTemplate
        for matchExpansion in expansion
          expanded = expandTemplateInPlace $(childTemplate).clone(true), matchExpansion
          fragment.appendChild expanded
      element.html fragment

    else if $.isFunction expansion
      return expandTemplateInPlace element, expansion(element)

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
      "@attributes": (propertyName, analog) ->
        match = /^@([\w-]+)$/.exec(propertyName)
        return false unless match
        this.attr(match[1], analog)
        null

      "fn()": (propertyName, analog) ->
        match = /^(\w+)\(\)$/.exec(propertyName)
        return false unless match
        this[match[1]].call(this, analog)
        null

      "class or css selector": (propertyName, analog) ->
        pattern = 
          if propertyName.charAt(0) == "$"
            propertyName.slice(1, propertyName.length)
          else
            "." + propertyName
        matches = this.find pattern
        expandTemplateInPlace $(match), analog for match in matches
        null

    compose: () ->
      expansions = arguments
      return (element) ->
        expandTemplateInPlace element, expansion for expansion in expansions
        null

  $.fn.expand = (expansion) ->
    element = $(this[0]).clone(true)
    element.removeAttr "id"
    $ expandTemplateInPlace(element, expansion)

)(jQuery)
