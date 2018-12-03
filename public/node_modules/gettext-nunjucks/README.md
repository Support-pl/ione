# gettext-nunjucks [![build status](https://secure.travis-ci.org/ministryofprogramming/gettext-nunjucks.png)](http://travis-ci.org/ministryofprogramming/gettext-nunjucks)

Extract translatable strings from [Nunjucks](https://github.com/mozilla/nunjucks) template strings.

It can be used stand-alone or through [xgettext-template](https://github.com/gmarty/xgettext).

### API

#### new Parser(keywordSpec)
Creates a new parser.
The `keywordSpec` parameter is optional, with the default being:
```javascript
{
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
}
```
Each keyword (key) requires an object with argument positions. The `msgid` position is required. `msgid_plural` and `msgctxt` are optional.
For example `gettext: {msgid: 0}` indicates that the Nunjucks expression looks like `{{ gettext("string") }}`.

#### .parse(template)
Parses the `template` string for Nunjucks expressions using the keywordspec.
It returns an object with this structure:
```javascript
{
  msgid1: {
    line: [1, 3]
  },
  msgid2: {
    line: [2],
    plural: 'msgid_plural'
  },
  context\u0004msgid2: {
    line: [4]
  }
}
```

### Development

#### Install
```shell
git clone git@github.com:ministryofprogramming/gettext-nunjucks.git
npm i
```

#### Test
```shell
npm run lint
npm test
```
