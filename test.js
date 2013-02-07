var obj, compiled;

jsondiff.diff([1],[2])

// QUnit
test('simpletest', function() {
    var obj1 = [1];
    var obj2 = [2];

    var diffres = jsondiff.diff(obj1, obj2);
    console.log("diff:", diffres);
    expect(0);
    //deepEqual(obj, {foo: 1, baz: [{qux: 'hello'}], bar: [1, 2, 3, 4]});

});

/*
test('firsttest', function() {
    var obj1 = {foo: 1, baz: [{qux: 'hello'}]};
    var obj2 = {foo: 2, baz: [{qux: 'hello'}]};

    var diffres = jsondiff.diff(obj1, obj2);
    console.log(diffres);
    //deepEqual(obj, {foo: 1, baz: [{qux: 'hello'}], bar: [1, 2, 3, 4]});

});
*/