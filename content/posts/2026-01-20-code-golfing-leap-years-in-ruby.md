+++
date = '2026-01-20T13:25:01+01:00'
title = 'Code Golfing Leap Years in Ruby'
author = "bhaak"
categories = ['Programming']
tags = ['Ruby']
+++

A work buddy challenged me to a bit of Ruby code golfing.

> Write a program to print all leap years from 1800 up to and including 2400.

The website he got the challenge from (https://code.golf/leap-years#ruby) has a
neat feature: it can run your code and verify whether the output matches the
expected result.

I’m usually not much of a code golfer, I generally prefer writing code that’s
performant and readable rather than short and cryptic, but this turned out to be
a fun little challenge and even somewhat educational.

I started with a simple, straightforward implementation at 77 characters:

```ruby
(1800..2400).each { p _1 if _1 % 4 == 0 && (_1 % 100 != 0 || _1 % 400 == 0) }
```

Next, I eliminated whitespace and removed the modulo 4 check by iterating only
over multiples of 4, bringing it down to 56 characters:

```ruby
(1800..2400).step(4).each{p(_1)if(_1%100!=0||_1%400==0)}
```

Then I shortened all numbers by dividing them by 4 and hard-coded the
exceptions as an array, reaching 54 characters. I only realized later that
skipping the hard-coded exceptions would have led to an even shorter solution.

```ruby
(451..600).each{p(_1*4)if([475,525,550,575]&[_1])==[]}
```

That was as far as I got before my work buddy shared his solution (also 54 characters).

His approach used the more concise upto method for iteration and a fairly
elaborate if condition, relying on modulo tests with the shorter less-than
operator instead of equality checks:

```ruby
1804.upto(2400){p(_1)if _1%4<1&&(_1%100<1?_1%400<1:0)}
```

Combining ideas from his solution and mine produced a much shorter version at
43 characters:

```ruby
451.upto(600){p(_1*4)if _1%25<1?_1%100<1:0}
```

Eventually, I managed to shave off one more character by simplifying the
condition, bringing it down to 42 characters:

```ruby
451.upto(600){p(_1*4)if _1%25>0||_1%100<1}
```

The current record on the code.golf site is 33 characters. I assume that
solution uses a completely different approach, but I have no idea what that
approach might be.
