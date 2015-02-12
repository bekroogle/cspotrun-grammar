var PEG = require('pegjs');
var expect = require('chai').expect;
var fs = require('fs');
var grammar = fs.readFileSync('../cspotrun.pegjs', 'utf-8');
var parse = PEG.buildParser(grammar).parse;

var check = function(str) {
  return traverse(parse(str));
};

describe("Print Statements", function() {
  
  describe("Printing concatenations", function() {
    it("Multiple print <string> should output to same line ", function() {
      var result = check('print "hello "\
        print "world."');
      expect(result).to.equal('hello world.');
    });

    it("Multiple print <number> should output to same line ", function() {
      var result = check('print 3\
        print 5');
      expect(result).to.equal('35');
    });
  });



  it("should print simple addition expressions", function() {
    
    var result = check('print 3+1');
    expect(result).to.equal('4');
  });
  
  it("should print simple multiplication expressions", function() {
    // multiplication of two literals
    var result = check('print 3*2');
    expect(result).to.equal('6');
  });
  
  it("should print numerical variable values", function() {
    var result = check('int i = 3 print i');
    expect(result).to.equal('3');
  });

  it("should print string literals", function() {
    var result = check('print "hello world"');
    expect(result).to.equal("hello world");
  });

  it("should print values of string variables", function() {
    var result = check(
    'text t = "hello world"\
     print t'
    );
    expect(result).to.equal("hello world");
  });
});

describe("Assingment types", function() {
  it("should properly cast ints", function() {
    var result = check('int i = "3.14"\
      print i');
    expect(result).to.equal('3');
  });

  it("should properly cast floats", function() {
    var result = check('real r = "3.14"\
      print r');
    expect(result).to.equal('3.14');
  });

  it("should properly cast strings", function() {
    var result = check('text t = 3.14\
      print t');
    expect(result).to.equal('3.14');
  });

  it("list l = [1,2,3]", function() {
    var result = check('list l = [1,2,3] print l');
    expect(result).to.equal('1,2,3');
  });
});
  //   var result = traverse(parse('int i = 3 print i*2'));
  //   expect(result).to.equal('6');

  //  var result = traverse(parse('int i = "3.14" real r = "3.14" text t = "3.14" list l = [3,.1,"4"] print t print r print i print l'));
  //   expect(result).to.equal("3.14\
  //     3.14\
  //     3\
  //     3,0.1,4")
  // });
