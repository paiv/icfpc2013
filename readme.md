
# paiv icfpc2013

http://icfpc2013.cloudapp.net/

## The Team
@paiv

contestScore: 135
lightningScore: 27
trainingScore: 676

## The Method
### The Power of Brute Force
Not that much


## Notes

As a solid brute force, this works well up to size 9 where it starts gobbling memory like a nut.
Some optimizations added to remove equivalent operations and cut duplicate branches.
If you need a tool to intelligently hog single core - look no further.

Spent too much time on issues in brute force generator, left with no time for alternative approach.


## Running

`paiv.rb` -- for stats and myproblems dump
`bruteforce/solver.rb` -- does the job
`myeval.rb` -- compiles your program and runs through supplied integers

## Software
Ruby 2.0

gems: treetop, rest-client


## Hardware
MacBook Pro mid-2010
