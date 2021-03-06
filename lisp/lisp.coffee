type = (obj) ->
    if obj?
        (Object::toString.call obj).slice 8, -1
    else
        String obj

beget = do ->
    Dummy = ->

    (obj) ->
        if obj?
            Dummy.prototype = obj
            value = new Dummy
            Dummy.prototype = null
            value
        else
            throw new Error "Can't inherit from #{obj}"

class Symbol
    constructor: (@value) ->

macros = {}

primitives =
    'lambda': ([args, body...], $env) ->
        ->
            env = beget $env
            for arg, index in args
                env[arg.value] = arguments[index]

            for expr in body.slice(0, -1)
                evaluate expr, env

            evaluate body[body.length - 1], env

    'if': ([test, t, e], env) ->
        if (evaluate test, env) is false
            (evaluate t, env)
        else
            (evaluate e, env)

    'quote': (body, env) ->
        body

    'define': (body, env) ->
        [$name, $val] = body
        unless $name instanceof Symbol        
            throw new SyntaxError()

        name = $name.value
        if env[name]? 
            throw new Error "'#{name}' is already defined"

        val = evaluate $val, env
        env[name] = val
        null

    'set!': (body, env) ->
        [$name, $val] = body
        unless $name instanceof Symbol        
            throw new SyntaxError()

        name = $name.value
        unless env[name]? 
            throw new Error "'#{name}' is already defined"

        val = evaluate $val, env
        env[name] = val
        null

    '.': (body, env) ->
        if body.length < 2
            throw new SyntaxError 'wattt'

        [$obj, $method, $args...] = body
        obj = evaluate $obj, env

        unless $method instanceof Symbol and obj?
            throw new TypeError

        method = obj[$method.value]

        if typeof method is 'function'
            args = $args.map (x) -> evaluate x, env
            method.apply obj, args
        else
            method

default_env = 
    '+': (args...) ->
        total = 0
        for i in args
            total += i

        total

    '*': (args...) ->
        product = 1
        for i in args
            product *= i

        product

    '=': (a, b) ->
        a is b

evaluate = (v, env=default_env) ->
    switch type v
        when 'Number', 'String'
            v

        when 'Object'
            if  v instanceof Symbol
                return env[v.value]

            throw new SyntaxError 

        when 'Array'
            if v.length is 0
                throw new SyntaxError

            [operator, operands...] = v
            if macros[operator.value]?
                evaluate (macros[operator.value] operands), env

            else if primitives[operator.value]?
                primitives[operator.value] operands, env

            else 
                fun = evaluate operator, env 
                args = (operands.map (v) -> evaluate v, env)
                fun.apply env.context, args

parseExpression = do ->
    {Parser} = require '../src/Parser'
    {Any, lazy} = Parser
    JSON = require '../json/src/Json'

    symbol = (Parser.from /[\*\+\._a-z][\*\+\._a-z0-9]*/i)
        .mapTo Symbol

    atom = Any [JSON.Number, JSON.String, symbol]

    whitespace = (Any [' ', '\r', '\n', '\t']).onceOrMore()
    comment = /;.*(\n|\r|$)/

    nontoken = (Any [whitespace, comment]).zeroOrMore()
    IW = (p) -> (Parser.from p).surroundedBy(nontoken, nontoken)
    
    expression = Parser.lazy -> 
        Any [atom, list, quote]

    list = Parser.lazy ->
        open = (Parser.from '(').followedBy(nontoken)
        close = (Parser.from ')').precededBy(nontoken)
        
        expression
            .separatedBy(nontoken)
            .surroundedBy(open, close)

    quote = Parser.lazy ->
        expression
            .precededBy('\'')
            .map((expr) ->
                [new Symbol 'quote'].concat(expr))

    expression
        .surroundedBy(nontoken, nontoken)
        .toFunction()

evalString = (source) ->
    tree = parseExpression source
    evaluate tree

console.log (evalString '\'(a list of symbols)')
console.log (evalString '((lambda (a) (* a a)) 5)')
console.log (evalString """
    ((lambda (str)
        ;; remove the first and
        ;; last character of a string
        (. str slice 1 -1)) 
     "{unwrap me}")
    """)
