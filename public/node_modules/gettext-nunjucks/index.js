'use strict';

var nunjucks = require('nunjucks');
var nunjucksMarkdown = require('nunjucks-markdown');
var marked = require('marked')

/**
 * Constructor
 * @param Object keywordSpec An object with keywords as keys and parameter indexes as values
 */
function Parser (keywordSpec) {
  // make new optional
  if (!(this instanceof Parser)) {
    return new Parser(keywordSpec);
  }

  keywordSpec = keywordSpec || Parser.keywordSpec;

  Object.keys(keywordSpec).forEach(function (keyword) {
    var positions = keywordSpec[keyword];

    if ('msgid' in positions) {
      return;
    } else if (Array.isArray(positions) && positions.indexOf('msgid') >= 0) {
      // maintain backwards compatibility with `_: ['msgid']` format
      keywordSpec[keyword] = positions.reduce(function (result, key, idx) {
        result[key] = idx;

        return result;
      }, {});
    } else if (Array.isArray(positions) && positions.length > 0) {
      // maintain backwards compatibility with `_: [0]` format
      var order = ['msgid', 'msgid_plural'];

      keywordSpec[keyword] = positions.slice(0).reduce(function (result, pos, idx) {
        result[order[idx]] = pos;

        return result;
      }, {});
    }
  });

  Object.keys(keywordSpec).forEach(function (keyword) {
    if (!('msgid' in keywordSpec[keyword])) {
      throw new Error('Every keyword must have a msgid key, but "' + keyword + '" doesn\'t have one');
    }
  });

  this.keywordSpec = keywordSpec;
}

// default JavaScript keywords from
// https://www.gnu.org/savannah-checkouts/gnu/gettext/manual/html_node/xgettext-Invocation.html
Parser.keywordSpec = {
  _: {
    msgid: 0
  },
  gettext: {
    msgid: 0
  },
  dgettext: {
    msgid: 1
  },
  dcgettext: {
    msgid: 1
  },
  ngettext: {
    msgid: 0,
    msgid_plural: 1
  },
  dngettext: {
    msgid: 1,
    msgid_plural: 2
  },
  pgettext: {
    msgctxt: 0,
    msgid: 1
  },
  npgettext: {
    msgctxt: 0,
    msgid: 1,
    msgid_plural: 2
  },
  dpgettext: {
    msgctxt: 1,
    msgid: 2
  }
};

// Same as what Jed.js uses
Parser.contextDelimiter = String.fromCharCode(4);

Parser.messageToKey = function (msgid, msgctxt) {
  return msgctxt ? msgctxt + Parser.contextDelimiter + msgid : msgid;
};

// Map every match using the Nunjucks parser.
Parser.prototype.nunjucks = function (template) {
  var matches = [];
  var keys = Object.keys(this.keywordSpec);

  function readNodes(node, matches) {
    if(node.value) {
        var newNode = { children: [node.value] };
        readNodes(newNode, matches);
    }

    if(node.cond) {
        var newNode = { children: [node.cond] };
        readNodes(newNode, matches);
    }

    if(node.left) {
        var newNode = { children: [node.left] };
        readNodes(newNode, matches);
    }

    if(node.right) {
        var newNode = { children: [node.right] };
        readNodes(newNode, matches);
    }

    if(node.expr) {
        var newNode = { children: [node.expr] };
        readNodes(newNode, matches)
    }

    if(node.ops) {
      for(var opsIndex in node.ops) {
        readNodes(node.ops[opsIndex], matches);
      }
    }

    if(node.args) {
        readNodes(node.args, matches);
    }

    if(node.body) {
        readNodes(node.body, matches);
    }

    if(node.else_) {
        var newNode = { children: [node.else_] };
        readNodes(newNode, matches);
    }

    if(node.children) {
        for(var i = 0; i < node.children.length; i++) {
            var child = node.children[i];

            if(child.name && keys.indexOf(child.name.value) !== -1) {
              var match = {
                keyword: child.name.value,
                line: child.name.lineno+1,
                args: []
              }

              for(var j in child.args.children) {
                  var currentArg = child.args.children[j];

                  if(currentArg.value) {
                    match.args.push(currentArg.value);  
                  }

                  readNodes(currentArg, matches);                        
              }

              if(match.args.length>0) {
                matches.push(match);
              }
            } else {
                readNodes(child, matches);
            }
        }
    }
  }

  // Add markdown support.
  var env = nunjucks.configure();
  marked.setOptions({smartypants: true, gfm: true});
  nunjucksMarkdown.register(env, marked);

  // Parse nodes.
  readNodes(nunjucks.parser.parse(template, env.extensionsList), matches);  
  return matches;
}

/**
 * Given a Nunjucks template string returns the list of i18n strings.
 *
 * @param String template The content of a Nunjucks template.
 * @return Object The list of translatable strings, the line(s) on which each appears and an optional plural form.
 */
Parser.prototype.parse = function (template) {
  var results = {};
  var matches = this.nunjucks(template);

  for(var i in matches) {
    var match = matches[i];

    var keyword = match.keyword;
    var params = match.args;
    var paramIndexes = this.keywordSpec[keyword];

    // Parse message.
    var msgidIndex = this.keywordSpec[keyword].msgid;
    var msgid = params[msgidIndex];

    // Prepare the result object.
    var result = {
      msgid: msgid,
      line: []
    };

    // Parse context.
    if(paramIndexes.msgctxt !== undefined) {
      result.msgctxt = result.msgctxt || params[paramIndexes.msgctxt];
    }

    // Parse plural form.
    if(paramIndexes.msgid_plural !== undefined) {
      var pluralValue = params[paramIndexes.msgid_plural];

      if (typeof pluralValue !== 'string' && !(pluralValue instanceof String)) {
        throw new Error('Plural must be a string literal for msgid ' + result.msgid);
      }

      var existingPlural = results[result.msgid];
      if(existingPlural && existingPlural.msgid_plural && (existingPlural.msgid_plural !== pluralValue)) {
        throw new Error('Incompatible plural definitions for msgid "' + result.msgid +
          '" ("' + existingPlural.msgid_plural + '" and "' + pluralValue + '")');
      }

      result.plural = result.msgid_plural = result.plural || pluralValue;
    }

    // Parse message lines.
    result.line.push(match.line);

    // Define result key.
    var resultKey = Parser.messageToKey(result.msgid, result.msgctxt);

    // Add result to results.
    var foundResult = results[resultKey];
    if(foundResult) {
      foundResult.line.push(result.line[0]);
    } else {
      results[resultKey] = result;
    }

  }

  return results;
};

module.exports = Parser;
