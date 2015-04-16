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

describe("CONDITIONALS", function() {
  describe("If-then guards", function() {
    describe("Boolean literals", function() {
      it("should execute then-part with true boolean literal", function() {
        var result = check('if true   \nprint "good"\n end if');
        expect(result).to.equal('good');
      });
      it("should not execute then-part with false boolean literal", function() {
        var result = check('if false   \nprint "bad"\n end if\n print "good"');
        expect(result).to.equal('good');
      });
    });
    describe("Relational expressions", function() {
      it("A guard of '1 < 2' should cause the body to execute", function() {
        var result = check('if 1 < 2   \nprint "good"\n end if');
        expect(result).to.equal('good');
      });
      it("A guard of '1 > 2' should NOT cause the body to execute", function() {
        var result = check('if 1 > 2   \nprint "bad"\n end if\n print "good"');
        expect(result).to.equal('good');
      });
      it("A guard of '1 <= 2' should cause the body to execute", function() {
        var result = check('if 1 <= 2   \nprint "good"\n end if');
        expect(result).to.equal('good');
      });
      it("A guard of '1 >= 2' should NOT cause the body to execute", function() {
        var result = check('if 1 >= 2   \nprint "bad"\n end if\n print "good"');
        expect(result).to.equal('good');
      });
    }); // Relational expressions
    describe("Equality tests", function() {
      it("A guard of '1 = 1' should cause the body to execute", function() {
        var result = check('if 1 = 1   \nprint "good"\n end if');
        expect(result).to.equal('good');
      });
      it("A guard of '1 = 2' should NOT cause the body to execute", function() {
        var result = check('if 1 = 2   \nprint "bad"\n end if\n print "good"');
        expect(result).to.equal('good');
      });

      it("A guard of '1 != 2' should cause the body to execute", function() {
        var result = check('if 1 != 2   \nprint "good"\n end if');
        expect(result).to.equal('good');
      });
      it("A guard of '2 != 2' should NOT cause the body to execute", function() {
        var result = check('if 2 != 2   \nprint "bad"\n end if\n print "good"');
        expect(result).to.equal('good');
      });
    }); // If-then gaurds
    describe("If-else", function () {
      it("should only do the if-part for true gaurd expressions", function() {
        var result = check('if 1 = 1  \nprint "true"\nelse\n print "false"\n end if');
        expect(result).to.equal('true');
      });
      it("should only do the else-part for false gaurd expressions", function() {
        var result = check('if 1 = 2  \nprint "true"\nelse\n print "false"\n end if');
        expect(result).to.equal('false');
      });
    });

  }); 
});

describe("EXPRESSIONS", function() {
  it("should handle simple integer division", function() {
    var result = check('int i = 10 / 3\nprint i');
    expect(result).to.equal('3');
  });
  it("should handle simple floating point division", function() {
    var result = check('real r = 10 / 3\nprint r');
    expect(symbol_table["r"].val).to.be.within(3,4);
  });
  it("should handle <int> % <int> expressions", function() {
    var result = check('int i = 5 % 2\nprint i');
    expect(result).to.equal('1');
  });
  it("should handle <number> - <variable>", function() {
    var result = check('int i = 5\n int j = 100 - i\n print j');
    expect(result).to.equal('95');
  });
  it("should handle simple exponentiation", function() {
    var result = check('int i = 2 ^ 3');
    expect(symbol_table.lookup('i')).to.equal(8);
  });
  it("should handle variable exponentiation", function() {
    var result = check('int i = 2 int j = 3 int k = i ^ j');
    expect(symbol_table.lookup('k')).to.equal(8);
  });
  it("should handle parenthesized exponents", function() {
    var result = check('int i = 2 * (3 + 2) ^ 2');
    expect(symbol_table.lookup('i')).to.equal(50);
  })
}); // EXPRESSIONS

describe("LISTS", function() {
  it("should initialize declared lists with []", function() {
    var result = check('list l');
    expect(symbol_table['l'].val).to.eql([]);
  });
  it("should allow setting list items to int vars", function() {
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
  it("should allow strings to be assigned to list items", function() {
    var result = check("list l = ['A',['B1',['B2a', 'B2b']],'C'] let l[2] = 'hello'");
    expect(symbol_table['l'].val[2]).to.equal('hello');
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
  it("should parse 3D list literals", function() {
    var result = check("list l = ['A',['B1',['B2a', 'B2b']],'C']");
    expect(symbol_table['l'].val).to.eql(['A',['B1',['B2a','B2b']],'C']); 
  });
  it("should parse 3D list elements", function() {
    var result = check("list l = ['A',['B1',['B2a', 'B2b']],'C']\nprint l[1][1][0]");
    expect(result).to.equal('B2a');
  });
  it("should iterate through an array with explicit indexing", function() {
    var result = check('list l = [2,4,6,8,10]\n while i = 0 to 4\n print l[i] + " "\n repeat');
    expect(result).to.equal('2 4 6 8 10 ');
  });
}); // LISTS


describe("LOOPS", function() {
  describe("While loops", function() {
    it("Should iterate a simlpe loop", function() {
      var result = check('int i = 0\n while i < 3\n print i \n let i = i + 1\n repeat');
      expect(result).to.equal('012');
    })
  }); // While loops
  describe("Counting loops", function() {
    it("Should be able to count from 1 to 10", function() {
      var result = check('while i = 1 to 10\nprint i\nrepeat');
      expect(result).to.equal('12345678910');
    });
    it("Should be able to count from 10 to 1", function() {
      var result = check('while i = 10 to 1\nprint i\nrepeat');
      expect(result).to.equal('10987654321');
    });
    it("Should not allow counting from a number to itself", function() {
      // Probably won't.
    });
  }); // Counting loops
});






describe("STRINGS", function() {
  describe("Methods", function() {
    it("should return the length", function() {
      var result = check('text t = "spot"\nprint t.length');
      expect(result).to.equal('4');
    });
    it("should convert the string to uppercase", function() {
      var result = check('text t = "spot"\nprint t.uppercase');
      expect(result).to.equal("SPOT");
    });
  }); // Methods 
});
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
}); // SYMBOL_TABLE

describe("SEQUENCES", function() {
  it("should execute simple assignments and print statements in sequential, imperative manner", function() {
    var result = check('int i = 3\nprint i\nlet i = 2');
    expect(result).to.equal('3');
  });
  it("should execute list assignments and print statements in sequential, imperative manner", function() {
    var result = check('list l =[1,2,3]\nprint l + endl\nlet l = [2,4,6]');
    expect(result).to.equal('1,2,3\n');
  });
  it("should execute list-elem assignments and print statements in sequential, imperative manner", function() {
    var result = check('list l = [1,2,3]\nlet l = [2,4,6]\nprint l\nlet l[0] = 7');
    expect(result).to.equal('2,4,6');
  });
  it("should exec list-elem assigns and list-elem print stmts in seq., imperative manner", function() {
    var result = check('list l = [1,2]\nprint l[0]\nlet l[0] = 2');
    expect(result).to.equal('1');
  });
});