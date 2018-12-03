'use strict';

var newline = /\r?\n|\r/g;
var escapeRegExp = function (str) {
  // source: https://developer.mozilla.org/en/docs/Web/JavaScript/Guide/Regular_Expressions
  return str.replace(/([.*+?^${}()|[\]/\\])/g, '\\$1');
};
var trim = function (str) {
  return str.replace(/^\s+|\s+$/g, '');
};
var trimQuotes = function (str) {
  return str.replace(/^['"]|['"]$/g, '');
};
var isQuote = function (chr) {
  return /['"]/.test(chr);
};
var groupParams = function (result, part) {
  if (result.length > 0) {
    var last = result[result.length - 1];
    var firstChar = last[0];
    var lastChar = last[last.length - 1];

    if (isQuote(firstChar) && (!isQuote(lastChar) || last[last.length - 2] === '\\')) {
      // merge with previous
      result[result.length - 1] += ',' + part;
    } else {
      result.push(part);
    }
  } else {
    result.push(part);
  }

  return result;
};

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
  this.expressionPattern = new RegExp([
    '{{ *',
    '(' + Object.keys(keywordSpec).map(escapeRegExp).join('|') + ')',
    '\\(',
    '([\\s\\S]*?)',
    '\\)',
    ' *}}'
  ].join(''), 'g');
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

/**
 * Given a Swig template string returns the list of i18n strings.
 *
 * @param String template The content of a Swig template.
 * @return Object The list of translatable strings, the line(s) on which each appears and an optional plural form.
 */
Parser.prototype.parse = function (template) {
  var results = {};
  var match;
  var keyword;
  var params;
  var msgid;

  while ((match = this.expressionPattern.exec(template)) !== null) {
    keyword = match[1];
    params = match[2].split(',').reduce(groupParams, []).map(trim).map(trimQuotes);

    // Parse message.
    var msgidIndex = this.keywordSpec[keyword].msgid;
    msgid = params[msgidIndex];

    // Prepare the result object.
    var result = {
      msgid: msgid,
      line: []
    };

    // Parse context.
    if (this.keywordSpec[keyword].msgctxt !== undefined) {
      var contextIndex = this.keywordSpec[keyword].msgctxt;
      result.msgctxt = result.msgctxt || params[contextIndex];
    }

    // Parse plural form.
    if (this.keywordSpec[keyword].msgid_plural !== undefined) {
      var pluralIndex = this.keywordSpec[keyword].msgid_plural;
      var pluralValue = params[pluralIndex];

      if (typeof pluralValue !== 'string' && !(pluralValue instanceof String)) {
        throw new Error('Plural must be a string literal for msgid ' + result.msgid);
      }

      var existingPlural = results[result.msgid];
      if (existingPlural && existingPlural.plural && (existingPlural.plural !== pluralValue)) {
        throw new Error('Incompatible plural definitions for msgid "' + result.msgid +
          '" ("' + existingPlural.plural + '" and "' + pluralValue + '")');
      }

      result.plural = result.msgid_plural = result.plural || pluralValue;
    }

    // Parse message lines.
    result.line.push(template.substr(0, match.index).split(newline).length);

    // Define result key.
    var resultKey = Parser.messageToKey(result.msgid, result.msgctxt);

    // Add result to results.
    var foundResult = results[resultKey];
    if (foundResult) {
      foundResult.line.push(result.line[0]);
    } else {
      results[resultKey] = result;
    }
  }

  return results;
};

module.exports = Parser;
