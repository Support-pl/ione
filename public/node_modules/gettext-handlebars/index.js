'use strict';

var Handlebars = require('handlebars');

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

// default keywords, copied from GNU xgettext's JavaScript keywords
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

/**
 * Given a Handlebars template string returns the list of i18n strings.
 *
 * @param String template The content of a HBS template.
 * @return Object The list of translatable strings, the line(s) on which each appears and an optional plural form.
 */
Parser.prototype.parse = function (template) {
  var keywordSpec = this.keywordSpec,
    keywords = Object.keys(keywordSpec),
    tree = Handlebars.parse(template);

  var isMsg = function (msgs, statement) {
    switch (statement.type) {
    case 'MustacheStatement':
    case 'SubExpression':
      if (keywords.indexOf(statement.path.original) !== -1) {
        var spec = keywordSpec[statement.path.original];
        var params = statement.params;
        var msgidParam = params[spec.msgid];

        if (msgidParam) { // don't extract {{gettext}} without param
          var msgid = msgidParam.original;
          var contextIndex = spec.msgctxt;
          var context = null; // null context is *not* the same as empty context

          if (contextIndex !== undefined) {
            var contextParam = params[contextIndex];

            if (!contextParam) {
              // throw an error if there's supposed to be a context but not enough
              // parameters were passed to the handlebars helper
              throw new Error('No context specified for msgid "' + msgid + '"');
            }

            if (contextParam.type !== 'StringLiteral') {
              throw new Error('Context must be a string literal for msgid "' + msgid + '"');
            }

            context = contextParam.original;
          }

          var key = Parser.messageToKey(msgid, context);
          msgs[key] = msgs[key] || {line: []};

          // make sure plural forms match
          var pluralIndex = spec.msgid_plural;
          if (pluralIndex !== undefined) {
            var pluralParam = params[pluralIndex];

            if (!pluralParam) {
              throw new Error('No plural specified for msgid "' + msgid + '"');
            }

            if (pluralParam.type !== 'StringLiteral') {
              throw new Error('Plural must be a string literal for msgid ' + msgid);
            }

            var plural = pluralParam.original;
            var existingPlural = msgs[key].msgid_plural;
            if (plural && existingPlural && existingPlural !== plural) {
              throw new Error('Incompatible plural definitions for msgid "' + msgid +
                '" ("' + msgs[key].msgid_plural + '" and "' + plural + '")');
            }
          }

          msgs[key].line.push(statement.loc.start.line);

          Object.keys(spec).forEach(function(prop) {
            var param = params[spec[prop]];

            if (param && param.type === 'StringLiteral') {
              msgs[key][prop] = params[spec[prop]].original;
            }
          });

          // maintain backwards compatibility with plural output
          msgs[key].plural = msgs[key].msgid_plural;
        }
      }

      break;
    case 'BlockStatement':
      if (statement.program) {
        statement.program.body.reduce(isMsg, msgs);
      }

      if (statement.inverse) {
        statement.inverse.body.reduce(isMsg, msgs);
      }

      break;
    }

    // subexpressions as params
    if (statement.params) {
      statement.params.reduce(isMsg, msgs);
    }

    // subexpressions as hash
    if (statement.hash) {
      statement.hash.pairs.reduce(function (msgs, pair) {
        return isMsg(msgs, pair.value);
      }, msgs);
    }

    return msgs;
  };


  return tree.body.reduce(isMsg, {});
};

module.exports = Parser;
