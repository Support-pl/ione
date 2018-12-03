var newline = /\r?\n|\r/g;
var escapeRegExp = function (str) {
    // source: https://developer.mozilla.org/en/docs/Web/JavaScript/Guide/Regular_Expressions
    return str.replace(/([.*+?^${}()|\[\]\/\\])/g, '\\$1');
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
function Parser (customKeywordSpec) {
    var keywordSpec = customKeywordSpec || {
        _: [0],
        gettext: [0],
        ngettext: [0, 1]
    };
    var openings = ['<%', '{\\*', '{{'];
    var closures = ['%>', '\\*}', '}}'];

    if (typeof keywordSpec !== 'object') {
        throw 'Invalid keyword spec';
    }

    this.keywordSpec = keywordSpec;
    this.expressionPattern = new RegExp([
        '(?:' + openings.join('[=-]|') + '[=-]) *',
        '(' + Object.keys(keywordSpec).map(escapeRegExp).join('|') + ')',
        '\\(',
        '([\\s\\S]*?)',
        '\\)',
        ' *(?:' + closures.join('|') + ')'
    ].join(''), 'g');
}

/**
 * Given a EJS template string returns the list of i18n strings.
 *
 * @param String template The content of a EJS template.
 * @return Object The list of translatable strings, the line(s) on which each appears and an optional plural form.
 */
Parser.prototype.parse = function (template) {
    var result = {};
    var match;
    var keyword;
    var params;
    var msgid;

    while ((match = this.expressionPattern.exec(template)) !== null) {
        keyword = match[1];

        params = match[2].split(',').reduce(groupParams, []).map(trim).map(trimQuotes);

        msgid = params[this.keywordSpec[keyword][0]];

        result[msgid] = result[msgid] || { line: [] };
        result[msgid].line.push(template.substr(0, match.index).split(newline).length);

        if (this.keywordSpec[keyword].length > 1) {
            result[msgid].plural = result[msgid].plural || params[this.keywordSpec[keyword][1]];
        }
    }

    return result;
};

module.exports = Parser;
