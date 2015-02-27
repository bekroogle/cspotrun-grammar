var PEG = require('pegjs');
var expect = require('chai').expect;
var fs = require('fs');
var grammar = fs.readFileSync('../cspotrun.pegjs', 'utf-8');
var parse = PEG.buildParser(grammar).parse;

var check = function(str) {
  return traverse(parse(str));
};

describe("PRINT STATEMENTS", function() {
  describe("print on the right line", function() {
    it("Multiple print <string> should output to same line ", function() {
      var result = check('print "hello "\nprint "world."');
      expect(result).to.equal('hello world.');
    });
    it("Multiple print <number> should output to same line ", function() {
      var result = check('print 3\nprint 5');
      expect(result).to.equal('35');
    });
    it("Should handle newline reserved word", function() {
      var result = check('print "hello" + endl + "goodbye"');
      expect(result).to.equal("hello\ngoodbye");
      expect(result).to.not.equal("hellogoodbye");
      expect(result).to.not.equal("hello\\ngoodbye");
    });
  });
  describe("handle single or double-quoted strings", function() {
    it('should handle simple single quoted strings', function() {
      var result = check("print 'hello'");
      expect(result).to.equal('hello');
    });
    it('should handle single quoted strings containing double quote char', function() {
      var result = check("print 'hello\"'");
      expect(result).to.equal('hello\"');
    });
    it('should handle double single quoted strings', function() {
      var result = check('print "hello"');
      expect(result).to.equal('hello');
    });
    it('should handle double quoted strings containing single quote char', function() {
      var result = check('print "hello\'"');
      expect(result).to.equal("hello'");
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
}); // PRINT STATEMENTS

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
}); // COMMENTS

describe("SYMBOL TABLE", function() {
  describe("Initialized variables", function() {
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
  }); // Initialized variables

  describe("Assignments", function() {
    describe("Assign to int vars", function() {
      it("simple assignments to int vars", function() {
        var result = check('int i\nlet i = 2')
        expect(symbol_table['i']).to.eql({type: 'int', val: 2});
      });
      it("expression assignments to int vars", function() {
        var result = check('int i\nlet i = 2 + 2')
        expect(symbol_table['i']).to.eql({type: 'int', val: 4});
      });
    }); // Assignn to int vars
    describe("Cast assignments (as would occur in prompt input)", function() {
      it("should properly cast input for int vars", function() {
        var result = check('int i\nlet i = "3.14"');
        expect(symbol_table['i']).to.eql({type: 'int', val: 3});
      });
      it("should properly cast input for real vars", function() {
        var result = check('real r\nlet r = "3.14"');
        expect(symbol_table['r']).to.eql({type: 'real', val: 3.14});
      });
      it("should properly cast input for text vars", function() {
        var result = check('text t\nlet t = 3.14');
        expect(symbol_table['t']).to.eql({type: 'text', val: "3.14"});
      });
    }); // Cast assignments
  });// Assignents

  describe("LISTS", function() {
    it("list item assignments to int vars", function() {
      var result = check('list l = [1,2,3]\nint i = l[2]');
      expect(symbol_table['i']).to.eql({type: 'int', val: 3});
    });
    it("should assign to lists with list literal", function() {
      var result = check('list l\nlet l = [1,2,3]\nprint l');
      expect(result).to.equal('1,2,3');
    });
    it("should assign to lists with list variable", function() {
      var result = check('list l = [1,2,3]\nlist m\nlet m = l\nprint m');
      expect(result).to.equal('1,2,3');
    });
    it("should assign to existing list items", function() {
      var result = check('list l = [1,2,3]\nlet l[0] = 2');
      expect(symbol_table['l']).to.eql({type: 'list', val: [2,2,3]});
    });
    it("should assign to new list items", function() {
      var result = check('list l = [1,2,3]\nlet l[5] = 2');
      expect(symbol_table['l']).to.eql({type: 'list', val: [1,2,3,,,2]});
    });
    it("should initialize lists with list literal", function() {
      var result = check('list l = [1,2,3] print l');
      expect(result).to.equal('1,2,3');
    });
    it("should initialize lists with list variable", function() {
      var result = check('list l = [1,2,3]\nlist m = l\nprint m');
      expect(result).to.equal('1,2,3');
    }); 
    it("should parse 2D list literals", function() {
      var result = check('list l = [[1,2],[2,4],[3,6]]');
      expect(symbol_table['l']).to.eql({type: 'list', val: [[1,2],[2,4],[3,6]]});
    }); 
    it("should parse 2D list elements", function() {
      var result = check('list l = [[1,2],[2,4],[3,6]]\nprint l[0][0]');
      expect(result).to.equal('1');
    });
  }); // LISTS
}); // SYMBOL_TABLE

describe("EXPRESSIONS", function() {
  it("should handle simple integer division", function() {
    var result = check('int i = 10 / 3\nprint i');
      expect(result).to.equal('3');
  });
  it("should handle simple floating point division", function() {
    var result = check('real r = 10 / 3\nprint r');
    expect(symbol_table["r"].val).to.be.within(3,4);
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
