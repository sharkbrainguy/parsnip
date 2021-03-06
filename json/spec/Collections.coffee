vows = require 'vows'
assert = require 'assert'
{Parser} = require '../lib/Parsnip'

{
    collectionsOf,
    ignoreWhitespace
} = require '../src/Collections'

oneParser = (Parser.from '1').convert (_) -> 1

(vows.describe 'Parsing Collections')
    .addBatch
        'Ignoring whitespace':
            topic: ->
                ignoreWhitespace oneParser

            'Without whitespace': (p) ->
                result = p.parse '1rest'
                assert.ok result.didSucceed

                continuation = result.value
                assert.deepEqual continuation.value, 1
                assert.deepEqual (String continuation.source), 'rest'

            'With spaces': (p) ->
                result = p.parse '   1 rest'
                assert.ok result.didSucceed
                
                continuation = result.value
                assert.deepEqual continuation.value, 1
                assert.deepEqual (String continuation.source), 'rest'

            'With linebreaks': (p) ->
                result = p.parse '   \n\t1 \trest'
                assert.ok result.didSucceed
                
                continuation = result.value
                assert.deepEqual continuation.value, 1
                assert.deepEqual (String continuation.source), 'rest'

            'With something else': (p) ->
                result = p.parse '   \n\n\t'
                assert.ok not result.didSucceed

    .addBatch
        'Parsing an empty Array':
            topic: ->
                {arrayParser} = collectionsOf oneParser
                arrayParser.parse '[]rest'

            'It succeeds': (result) ->
                assert.ok result.didSucceed

            'With the correct value': (result) ->
                continuation = result.value
                assert.deepEqual continuation.value, []
                assert.deepEqual (String continuation.source), 'rest'

        'Parsing an Array':
            topic: ->
                {arrayParser} = collectionsOf oneParser
                arrayParser.parse '[1, 1, 1]rest'

            'It succeeds': (result) ->
                assert.ok result.didSucceed

            'With the correct value': (result) ->
                continuation = result.value
                assert.deepEqual continuation.value, [1, 1, 1]
                assert.deepEqual (String continuation.source), 'rest'

        'Parsing nested Arrays':
            topic: ->
                {arrayParser} = collectionsOf oneParser
                arrayParser.parse '[1, [1, 1], []]rest'

            'It succeeds': (result) ->
                assert.ok result.didSucceed

            'With the correct value': (result) ->
                continuation = result.value
                assert.deepEqual continuation.value, [1, [1, 1], []]
                assert.deepEqual (String continuation.source), 'rest'

        'Parsing something else':
            topic: ->
                {arrayParser} = collectionsOf oneParser
                arrayParser.parse '{}'

            'It fails': (result) ->
                assert.ok not result.didSucceed

    .addBatch
        'Parsing an empty Object':
            topic: ->
                {objectParser} = collectionsOf oneParser
                objectParser.parse '{}rest'

            'It succeeds': (result) ->
                assert.ok result.didSucceed

            'With the correct value': (result) ->
                continuation = result.value

                assert.deepEqual continuation.value, {}
                assert.deepEqual (String continuation.source), 'rest'

        'Parsing a non empty Object':
            topic: ->
                {objectParser} = collectionsOf oneParser
                objectParser.parse '{"poop": 1, "fart": 1} rest'

            'It succeeds': (result) ->
                assert.ok result.didSucceed

            'With the correct value': (result) ->
                continuation = result.value

                assert.deepEqual continuation.value, {poop: 1, fart: 1}
                assert.deepEqual (String continuation.source), 'rest'

        'Parsing nested objects':
            topic: ->
                src = '{"poop": {"cakes": \r\t1}\t, "fart"\n: 1, "okay": {}}  rest'
                {objectParser} = collectionsOf oneParser
                objectParser.parse src

            'It succeeds': (result) ->
                assert.ok result.didSucceed

            'With the correct value': (result) ->
                continuation = result.value

                assert.deepEqual continuation.value, {poop: {cakes:1}, fart: 1, okay: {}}
                assert.deepEqual (String continuation.source), 'rest'

    .export module
