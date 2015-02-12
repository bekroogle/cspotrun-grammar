var PEG = require('pegjs');
var expect = require('chai').expect;
var fs = require('fs');
var grammar = fs.readFileSync('../cspotrun.pegjs', 'utf-8');
var parse = PEG.buildParser(grammar).parse;

var check = function(str) {
  return traverse(parse(str));
};

describe("PRINT STATEMENTS", function() {
  describe("Printing concatenations", function() {
    it("Multiple print <string> should output to same line ", function() {
      var result = check('print "hello "\nprint "world."');
      expect(result).to.equal('hello world.');
    });
    it("Multiple print <number> should output to same line ", function() {
      var result = check('print 3\nprint 5');
      expect(result).to.equal('35');
    });
  });
  describe("Proper spacing in contatenating", function() {
    it("Should handle trailing spaces in string literals", function() {
      var result = check('print "cool " + "cool"');
      expect(result).to.equal('cool cool');
    });
    it("Should handle trailing spaces in string variables", function() {
      var result = check('text t = "cool "\nprint t + t');
      expect(result).to.equal('cool cool ');
    });
    it("Should handle leading spaces in string literals", function() {
      var result = check('print "cool" + " cool"');
      expect(result).to.equal('cool cool');
    });
    it("Should handle leading spaces in string variables", function() {
      var result = check('text t = " cool"\nprint t + t');
      expect(result).to.equal(' cool cool');
    });
    it("Should handle concatenated spaces", function() {
      var result = check('print "cool" + " " + "cool"');
      expect(result).to.equal('cool cool');
    });
  });
  describe("Printing arithmetic expressions", function() {
    it("should print simple addition expressions using int literals", function() {
      var result = check('print 3+1');
      expect(result).to.equal('4');
    });
    it("should print simple multiplication expressions using int literals", function() {
      // multiplication of two literals
      var result = check('print 3*2');
      expect(result).to.equal('6');
    });
    it("should print numerical variable values", function() {
      var result = check('int i = 3 print i');
      expect(result).to.equal('3');
    });
    it("should print simple addition expressions using int variables", function() {
      var result = check('int i = 3\nint j = 2\nprint i+j');
      expect(result).to.equal('5');
    });  
    it("should print simple multiplication expressions using int variables", function() {
      // multiplication of two literals
      var result = check('int i = 3\nint j = 2\nprint i*j');
      expect(result).to.equal('6');
    });
  });
  describe("Printing string expressions", function() {
    it("should print string literals", function() {
      var result = check('print "hello world"');
      expect(result).to.equal("hello world");
    });
    it("should print values of string variables", function() {
      var result = check(
        'text t = "hello world"\
        print t');
      expect(result).to.equal("hello world");
    });
  });
});

describe("COMMENTS", function() {
  it("should effectively ignore a single comment", function() {
    var result = check('# nobody here but us comments');
    expect(result).to.equal('');
  });
  it("should allow a program to start with a comment", function() {
    var result=check('# cool\nprint "cool"');
    expect(result).to.equal('cool');
  });
  it("should allow a program to end with a comment", function() {
    var result=check('print "cool"\n# prog is over, bud.');
    expect(result).to.equal('cool');
  });
});

describe("SYMBOL TABLE", function() {
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
