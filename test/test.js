var PEG = require('pegjs');
var expect = require('chai').expect;
var fs = require('fs');
var grammar = fs.readFileSync('../cspotrun.pegjs', 'utf-8');
var parse = PEG.buildParser(grammar).parse;


describe("Print <number expression>", function() {
  
  it("should print numerical expressions", function() {
    // addition of two literals
    var result = traverse(parse('print 3+1'));
    expect(result).to.equal('4');

    // multiplication of two literals
    var result = traverse(parse('print 3*2'));
    expect(result).to.equal('6');

    var result = traverse(parse('int i = 3 print i*2'));
    expect(result).to.equal('6');

  })
});