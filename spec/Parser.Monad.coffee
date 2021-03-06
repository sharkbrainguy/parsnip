###
Tests that the Monad laws hold using parser values
and the static methods chain, of, and zero.
###


vows = require 'vows'
assert = require 'assert'

{Parser} = require '../src/Parsnip'
{zero, of: $of, chain} = Parser

# reverse: (str:String) -> Result<String>
reverse = (str) ->
    chars = str.split ''
    reversed = do chars.reverse
    $of reversed.join ''

# capitalize: (str:String) -> Result<String>
capitalize = (str) ->
    first = do (str.charAt 0).toUpperCase
    rest = str.slice 1

    $of first + rest

# TODO: replace this with a large random 
# sample of possible inputs
source_sample = ['foobar', '!foo', 'catdog', '']

typeString = (obj) ->
    if obj?
        full = Object::toString.call obj
        full.slice 8, -1
    else
        String obj

deepEqual = (a, b) -> 
    arrayEqual = (a, b) ->
        return false unless (typeString a) is 'Array'
        return false unless (typeString b) is 'Array'
        return false unless a.length is b.length

        for _, index in a
            return false unless deepEqual a[index], b[index]

        true

    objectEqual = (a, b) ->
        if (typeString a) is 'Array' or (typeString b) is 'Array'
            return false

        unless (typeof a) is 'object' and (typeof b) is 'object'
            return false

        unless (Object.getPrototypeOf a) is (Object.getPrototypeOf b)
            return false

        keys = Object.keys a
        unless arrayEqual keys, (Object.keys b)
            return false

        for k in keys
            return false unless deepEqual a[k], b[k]

        true


    (a is b) or
    (arrayEqual a, b) or
    (objectEqual a, b)

notDeepEqual = (a, b) ->
    not deepEqual a, b

parsesEquivalently = (left, right) ->
    (source) ->
        a = left.parse source
        b = right.parse source
        deepEqual a, b

parsesUnequivalently = (left, right) ->
    (source) ->
        a = left.parse source
        b = right.parse source
        notDeepEqual a, b

assert.parsersEqual = (a, b) ->
    assert.ok (source_sample.every (parsesEquivalently a, b))

assert.parsersNotEqual = (a, b) ->
    assert.ok (source_sample.some (parsesUnequivalently a, b))

(vows.describe 'Parser monad operations')
    .addBatch
        'Left identity: (return a) >>= f is f a':
            topic: ->
                left  = chain ($of 'foo'), reverse
                right = reverse 'foo'
                [left, right]

            'Are equal': ([left, right]) ->
                assert.parsersEqual left, right

        'Right identity: m >>= return is m':
            topic: -> 
                chain (Parser.from 'foo'), $of

            'is equal to (Parser.from \'foo\')': (t) ->
                assert.parsersEqual t, (Parser.from 'foo')

            'is not equal to (Parser.from \'fun\')': (t) ->
                assert.parsersNotEqual t, (Parser.from 'fun')

            'is not equal to \'foo\' >>= (\\x -> return \'bar\')': (t) ->
                right = chain (Parser.from 'foo'), (x) -> $of 'bar'
                assert.parsersNotEqual t, right

        'Associativity: (m >>= f) >>= g is m >>= (\\x -> f x >>= g)':
            topic: ->
                m = new Parser.Succeed 'okay'
                a = chain (chain m, reverse), capitalize
                b = chain m, ((x) -> chain (reverse x), capitalize)
                [a, b]

            'left == right': ([left, right]) ->
                assert.parsersEqual left, right

    .export module
