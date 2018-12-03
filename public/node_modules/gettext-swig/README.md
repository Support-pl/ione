# gettext-swig [![build status](https://secure.travis-ci.org/smhg/gettext-swig.png)](http://travis-ci.org/smhg/gettext-swig)

Extract translatable strings from [Swig](http://node-swig.github.io/swig-templates/) template strings.

It can be used stand-alone or through [gmarty/gettext](https://github.com/gmarty/xgettext).

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
  dpgettext: {
    msgctxt: 1,
    msgid: 2
  }
}
```
Each keyword (key) requires an object with argument positions. The `msgid` position is required. `msgid_plural` and `msgctxt` are optional.
For example `gettext: {msgid: 0}` indicates that the Swig expression looks like `{{ "string"|gettext }}`.

#### .parse(template)
Parses the `template` string for Handlebars expressions using the keywordspec.
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
git clone git@github.com:smhg/gettext-swig.git
npm i
```

#### Test
```shell
npm run lint
npm test
```
