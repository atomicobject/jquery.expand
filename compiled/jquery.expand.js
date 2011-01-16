(function() {
  var __hasProp = Object.prototype.hasOwnProperty;
  (function($) {
    var expandTemplateInPlace;
    expandTemplateInPlace = function(element, expansion) {
      var childTemplate, expanded, fragment, matchExpansion, property, propertyName, result, rule, syntax, _, _i, _len;
      if (expansion === null || expansion === void 0 || expansion === true) {
        return element[0];
      }
      if (expansion === false) {
        element.remove();
      } else if (/^(?:number|string)$/.test(typeof expansion) || expansion instanceof jQuery) {
        element.html(expansion);
      } else if ($.isFunction(expansion)) {
        return expandTemplateInPlace(element, expansion(element));
      } else if (expansion.constructor === Array) {
        childTemplate = element.children()[0];
        fragment = document.createDocumentFragment();
        if (childTemplate) {
          for (_i = 0, _len = expansion.length; _i < _len; _i++) {
            matchExpansion = expansion[_i];
            expanded = expandTemplateInPlace($(childTemplate).clone(true), matchExpansion);
            fragment.appendChild(expanded);
          }
        }
        element.html(fragment);
      } else if (typeof expansion === 'object') {
        syntax = $.expand.KEY_SYNTAX;
        for (propertyName in expansion) {
          if (!__hasProp.call(expansion, propertyName)) continue;
          property = expansion[propertyName];
          for (_ in syntax) {
            if (!__hasProp.call(syntax, _)) continue;
            rule = syntax[_];
            result = rule.call(element, propertyName, property);
            if (result && typeof result === "object") {
              expandTemplateInPlace($(result.expand), result.withExpansion);
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
          var match, matches, pattern, _i, _len;
          pattern = propertyName.charAt(0) === "$" ? propertyName.slice(1, propertyName.length) : "." + propertyName;
          matches = this.find(pattern);
          for (_i = 0, _len = matches.length; _i < _len; _i++) {
            match = matches[_i];
            expandTemplateInPlace($(match), analog);
          }
          return null;
        }
      },
      compose: function() {
        var expansions;
        expansions = arguments;
        return function(element) {
          var expansion, _i, _len;
          for (_i = 0, _len = expansions.length; _i < _len; _i++) {
            expansion = expansions[_i];
            expandTemplateInPlace(element, expansion);
          }
          return null;
        };
      }
    };
    return $.fn.expand = function(expansion) {
      var element;
      element = $(this[0]).clone(true);
      element.removeAttr("id");
      return $(expandTemplateInPlace(element, expansion));
    };
  })(jQuery);
}).call(this);
