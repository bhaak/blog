+++
date = '2026-01-20T13:25:01+01:00'
title = 'Code Golfing Leap Years in Ruby'
author = "bhaak"
categories = ['Programming']
tags = ['Ruby']
+++

My work buddy presented me with a code golfing challenge in Ruby.

> Write a program to print all the leap years from the year 1800 up to and
> including 2400.

The website (https://code.golf/leap-years#ruby) he got the challenge from has a
neat feature where it can run the code for you and check if its output matches
the desired result.

I am usually not the greatest code golfer as I'd rather like to make code as
performant as possible instead of making it as short and unreadable as possible
but this was a fun little challenge which even turned out to be educational.

I started with a simple but obviously straight forward implementation with 77 chars.
```ruby
(1800..2400).each { p _1 if _1 % 4 == 0 && (_1 % 100 != 0 || _1 % 400 == 0) }
```

Eliminating whitespace and the modulo 4 test by only iterating over multiples of 4 (56 chars).
```ruby
(1800..2400).step(4).each{p(_1)if(_1%100!=0||_1%400==0)}
```

Shortening all numbers by dividing them by 4 and hardcoding the exceptions as
an array (54 chars). I only later realized that if I had not used the hardcoded
exceptions I would have had a much shorter solution.
```ruby
(451..600).each{p(_1*4)if([475,525,550,575]&[_1])==[]}
```

That was as far as I got when work buddy shared his solution (also 54 chars).

His solution used the more concise `upto()` for iterating and a quite elaborate
`if` condition using modulo testing with the shorter less-than operator instead
of the equals operator.
```ruby
1804.upto(2400){p(_1)if _1%4<1&&(_1%100<1?_1%400<1:0)}
```

Combining his solution and mine gave a much shorter version (43 chars).
```ruby
451.upto(600){p(_1*4)if _1%25<1?_1%100<1:0}
```

I was eventually able to shave off 1 char by improving the condition (42 chars).
```ruby
451.upto(600){p(_1*4)if _1%25>0||_1%100<1}
```

The record on the code.golf site is 33 characters. I assume this solution is
using a completely different approach but I have no clue at all what this
approach could be.
