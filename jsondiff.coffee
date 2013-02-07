# jsonpatch.js 0.3.2
# (c) 2011-2013 Adam Griffiths
# (c) 2011-2013 Byron Ruth
# Original code started from https://gist.github.com/bruth/4715999
# jsondiff may be freely distributed under the BSD license

((root, factory) ->
    if typeof exports isnt 'undefined'
        # Node/CommonJS
        factory(root, exports)
    else if typeof define is 'function' and define.amd
        # AMD
        define ['exports'], (exports) ->
            root.jsondiff = factory(root, exports)
    else
        # Browser globals
        root.jsondiff = factory(root, {})
) @, (root) ->

    # Utilities
    toString = Object.prototype.toString
    hasOwnProperty = Object.prototype.hasOwnProperty

    # Define a few helper functions taken from the awesome underscore library
    isArray = (obj) -> toString.call(obj) is '[object Array]'
    isObject = (obj) -> toString.call(obj) is '[object Object]'
    isString = (obj) -> toString.call(obj) is '[object String]'
    isFunction = (obj) -> toString.call(obj) is '[object Function]'
    has = (obj, key) -> hasOwnProperty.call(obj, key)
  
    isEqual = (a, b) -> eq a, b, [], []

    # Internal recursive comparison function for `isEqual`.
    eq = (a, b, aStack, bStack) ->
      
      # Identical objects are equal. `0 === -0`, but they aren't identical.
      # See the Harmony `egal` proposal: http://wiki.ecmascript.org/doku.php?id=harmony:egal.
      return a isnt 0 or 1 / a is 1 / b  if a is b
      
      # A strict comparison is necessary because `null == undefined`.
      return a is b  if not a? or not b?
      
      # Unwrap any wrapped objects.
      # commenting out next too lines form the underscore implemenation
      # a = a._wrapped  if a instanceof _
      # b = b._wrapped  if b instanceof _
      
      # Compare `[[Class]]` names.
      className = toString.call(a)
      return false  unless className is toString.call(b)
      switch className
        
        # Strings, numbers, dates, and booleans are compared by value.
        when "[object String]"
          
          # Primitives and their corresponding object wrappers are equivalent; thus, `"5"` is
          # equivalent to `new String("5")`.
          return a is String(b)
        when "[object Number]"
          
          # `NaN`s are equivalent, but non-reflexive. An `egal` comparison is performed for
          # other numeric values.
          return (if a isnt +a then b isnt +b else ((if a is 0 then 1 / a is 1 / b else a is +b)))
        when "[object Date]", "[object Boolean]"
          
          # Coerce dates and booleans to numeric primitive values. Dates are compared by their
          # millisecond representations. Note that invalid dates with millisecond representations
          # of `NaN` are not equivalent.
          return +a is +b
        
        # RegExps are compared by their source patterns and flags.
        when "[object RegExp]"
          return a.source is b.source and a.global is b.global and a.multiline is b.multiline and a.ignoreCase is b.ignoreCase
      return false  if typeof a isnt "object" or typeof b isnt "object"
      
      # Assume equality for cyclic structures. The algorithm for detecting cyclic
      # structures is adapted from ES 5.1 section 15.12.3, abstract operation `JO`.
      length = aStack.length
      
      # Linear search. Performance is inversely proportional to the number of
      # unique nested structures.
      return bStack[length] is b  if aStack[length] is a  while length--
      
      # Add the first object to the stack of traversed objects.
      aStack.push a
      bStack.push b
      size = 0
      result = true
      
      
      # Recursively compare objects and arrays.
      if className is "[object Array]"
        
        # Compare array lengths to determine if a deep comparison is necessary.
        size = a.length
        result = size is b.length
        
        # Deep compare the contents, ignoring non-numeric properties.
        if result
          while size-- 
            unless result = eq(a[size], b[size], aStack, bStack)   
              break
      else
        
        # Objects with different constructors are not equivalent, but `Object`s
        # from different frames are.
        aCtor = a.constructor
        bCtor = b.constructor
        return false  if aCtor isnt bCtor and not (isFunction(aCtor) and (aCtor instanceof aCtor) and isFunction(bCtor) and (bCtor instanceof bCtor))
        
        # Deep compare objects.
        for key of a
          if has(a, key)
            
            # Count the expected number of properties.
            size++
            
            # Deep compare each member.
            break  unless result = has(b, key) and eq(a[key], b[key], aStack, bStack)
        
        # Ensure that both objects contain the same number of properties.
        if result
          for key of b
            break  if has(b, key) and not (size--)
          result = not size
      
      # Remove the first object from the stack of traversed objects.
      aStack.pop()
      bStack.pop()
      result
    
        
    #Patch helper functions
    getParent = (paths, path) ->
        paths[path.substr(0, path.match(/\//g).length)]

    #Checks if `obj` is an array or object
    isContainer = (obj) ->
        isArray(obj) || isObject(obj)
 
    #Checks if the two objects are of the same container type
    #returns false if they are different contianers or non-containers
    isSameContainer = (obj1, obj2) ->
       (isArray(obj1) && isArray(obj2)) || (isObject(obj1) && isObject(obj2))
    
    #Flattens an object to a hash of paths and values.
    flattenObject = (obj, prefix = "/", paths = {}) ->
        paths[prefix] =
            path: prefix
            value: obj
 
        if prefix != '/' 
            prefix = prefix + '/'
 
        #Recurse for container types
        if isArray(obj)
            flattenObject o, prefix + i,  paths for o, i in obj
        else if isObject(obj)
            flattenObject o, prefix + key,  paths for key, o of obj
 
        return paths;

    #Constructs a patch that when applied to `obj2`, it will be equivalent
    #to `obj1`. The patch format conforms to IETF JSON Patch proposal
    #http://tools.ietf.org/html/draft-ietf-appsawg-json-patch-01
    diff = (obj1, obj2) ->
        #Patches are only applicable to two of the same container types.
        if !isSameContainer obj1, obj2
            throw new Error('Patches can only be derived from objects or arrays');
 
        paths1 = flattenObject obj1
        paths2 = flattenObject obj2
        add = {}
        remove = {}
        replace = {}
        move = {}

        #Iterate over the first object's paths and compare them to the second
        #set of paths.
        for key of paths1
            doc1 = paths1[key]
            doc2 = paths2[key]

            # If the parent of `doc2` doesn't exist, skip it since neither a
            # remove or replace can occur.
            if !getParent paths2, key
                continue
            
            # Else, if doc2 does not exist then key must have been removed from the 
            # second object, so is be marked for removal.
            else if !doc2
                remove[key] = doc1
                
            # Else, if doc1 and doc2 are the same
            # container type, values will be replaced downstream.
            else if isSameContainer doc1.value, doc2.value
                continue
            
            # Else, if doc1 and doc2 are not the same
            # then doc2 must have replaced doc1
            else if !isEqual doc1.value, doc2.value
                replace[key] = doc2
                
        # Iterate over the second object's paths and compare them to the first
        # set of paths.
        for key of paths2
            doc1 = paths1[key]
            doc2 = paths2[key]
            
            # Missing in first object, thus we mark it to be added.
            # If the parent path is not present in the first obj, then this
            # means the whole array/object is new.
            if !doc1 and isSameContainer getParent(paths1, key), getParent(paths2, key)
                add[key] = doc2;

        # Attempt to promote add/remove operations to a move operation.
        # The first occurence of the same value, we can promote to a move.
        for key1, doc1 of remove
            for key2, doc2 of add
                if isEqual(doc2.value, doc1.value)                  
                    # conver the add+remove to an move
                    delete remove[key1]
                    delete add[key2]              
                    move[key2] = key1
                    break
        
        # Populate the patch
        patch = []
        for key, doc of add
            patch.push
                op: 'add'
                path: key
                value: doc.value
        
        for key of remove
            patch.push 
                op: 'remove'
                path: key
          
        for key, doc of replace
            patch.push
                op: 'replace'
                path: key
                value: doc.value
        
        for keyto, keyfrom of move
            patch.push
                op: 'move'
                from: keyfrom
                path: keyto
        patch
         

    # Export to root
    root.diff = diff
    return root
