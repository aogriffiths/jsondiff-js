var obj, compiled;

function standardCheck(obj1, obj2, diffres){
  console.log(JSON.stringify(diffres));
  var obj3 = JSON.parse(JSON.stringify(obj1));
  try{
    jsonpatch.apply(obj3, diffres);  
  }catch(e){
    console.log(e);
    ok(false,e);
  }
  deepEqual(obj2,obj3)
}

// QUnit
test('simple replace', function() {
  var obj1 = [ 1 ];
  var obj2 = [ 2 ];

  var diffres = jsondiff.diff(obj1, obj2);
  deepEqual(diffres, [ {
    "op" : "replace",
    "path" : "/0",
    "value" : 2
  } ]);
  standardCheck(obj1, obj2, diffres)
});

test('object add', function() {
  var obj1 = [ {  a : 1 } ];
  var obj2 = [ {  a : 1 }, {  b : 2 } ];

  var diffres = jsondiff.diff(obj1, obj2);
  deepEqual(diffres, [ {
    "op" : "add",
    "path" : "/1",
    "value" : {
      "b" : 2
    }
  } ]);
  standardCheck(obj1, obj2, diffres)
});

test('object remove', function() {
  var obj1 = [ { a : 1 },  { b : 2 }  ];
  var obj2 = [ { a : 1 } ];

  var diffres = jsondiff.diff(obj1, obj2);
  deepEqual(diffres, [  {
    "op" : "remove",
    "path" : "/1"
  } ]);
  standardCheck(obj1, obj2, diffres)
});

test('object remove and add', function() {
  var obj1 = [ {  a : 1 } ];
  var obj2 = [ {  b : 2 } ];

  var diffres = jsondiff.diff(obj1, obj2);
  deepEqual(diffres, [ {
    "op" : "add",
    "path" : "/0/b",
    "value" : 2
  }, {
    "op" : "remove",
    "path" : "/0/a"
  } ]);
  standardCheck(obj1, obj2, diffres)
});

test('simple move', function() {
  var obj1 = [ {  a : 1 } ];
  var obj2 = [ {  b : 1 } ];

  var diffres = jsondiff.diff(obj1, obj2);
  deepEqual(diffres, [ {
    "op": "move",
    "from": "/0/a",
    "path": "/0/b"
  } ]);
  standardCheck(obj1, obj2, diffres)
});

test('complex move', function() {
  var obj1 = [ "thing", [1,2,3]];
  var obj2 = [ "thing", {a:1}, [1,2,3]];

  var diffres = jsondiff.diff(obj1, obj2, false);
  //expect(0);
  deepEqual(diffres,[]);
  standardCheck(obj1, obj2, diffres)
});
