(function() {
  var __hasProp = Object.prototype.hasOwnProperty;
  (function($) {
    var expandTemplateInPlace;
    $.fn.expand = function(directive) {
      var element;
      element = this[0].nodeName === "SCRIPT" ? $(this.html()) : this.eq(0).clone(true).removeAttr("id");
      expandTemplateInPlace(element, directive);
      return element;
    };
    expandTemplateInPlace = function(element, directive) {
      var childTemplate, expanded, fragment, matchDirective, property, propertyName, result, rule, syntax, _, _i, _len, _ref;
      if (directive === null || directive === void 0 || directive === true) {
        return element[0];
      }
      if (directive === false) {
        element.remove();
      } else if (((_ref = typeof directive) === "number" || _ref === "string") || directive instanceof jQuery) {
        element.html(directive);
      } else if ($.isFunction(directive)) {
        return expandTemplateInPlace(element, directive(element));
      } else if (directive.constructor === Array) {
        childTemplate = element.children()[0];
        fragment = document.createDocumentFragment();
        if (childTemplate) {
          for (_i = 0, _len = directive.length; _i < _len; _i++) {
            matchDirective = directive[_i];
            expanded = expandTemplateInPlace($(childTemplate).clone(true), matchDirective);
            fragment.appendChild(expanded);
          }
        }
        element.html(fragment);
      } else if (typeof directive === 'object') {
        syntax = $.expand.KEY_SYNTAX;
        for (propertyName in directive) {
          if (!__hasProp.call(directive, propertyName)) continue;
          property = directive[propertyName];
          for (_ in syntax) {
            if (!__hasProp.call(syntax, _)) continue;
            rule = syntax[_];
            result = rule.call(element, propertyName, property);
            if (result && typeof result === "object") {
              expandTemplateInPlace($(result.expand), result.withDirective);
            }
            if (result !== false) {
              break;
            }
          }
        }
      }
      return element[0];
    };
    $.expand = {
      KEY_SYNTAX: {
        "@attributes": function(propertyName, analog) {
          var match;
          match = /^@([\w-]+)$/.exec(propertyName);
          if (!match) {
            return false;
          }
          this.attr(match[1], analog);
          return null;
        },
        "fn()": function(propertyName, analog) {
          var match;
          match = /^(\w+)\(\)$/.exec(propertyName);
          if (!match) {
            return false;
          }
          this[match[1]].call(this, analog);
          return null;
        },
        "class or css selector": function(propertyName, analog) {
          var directive, match, matches, _i, _len;
          directive = propertyName.charAt(0) === "$" ? propertyName.slice(1, propertyName.length) : "." + propertyName;
          matches = this.find(directive);
          for (_i = 0, _len = matches.length; _i < _len; _i++) {
            match = matches[_i];
            expandTemplateInPlace($(match), analog);
          }
          return null;
        }
      },
      compose: function() {
        var directives;
        directives = arguments;
        return function(element) {
          var directive, _i, _len;
          for (_i = 0, _len = directives.length; _i < _len; _i++) {
            directive = directives[_i];
            expandTemplateInPlace(element, directive);
            if (directive === false) {
              break;
            }
          }
          return null;
        };
      }
    };
    return $.fn.expandInPlace = function(directive) {
      var element, _i, _len;
      for (_i = 0, _len = this.length; _i < _len; _i++) {
        element = this[_i];
        expandTemplateInPlace($(element), directive);
      }
      return this;
    };
  })(jQuery);
}).call(this);
