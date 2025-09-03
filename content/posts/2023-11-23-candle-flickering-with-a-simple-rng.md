+++
title = "Simulating candle flickering with a simple RNG"
date = "2023-11-23T12:48:00+01:00"
author = "bhaak"
categories = ['Programming']
tags = ['Ruby', 'RNG']
+++

<style>
  #candle {
    background-color: black;
    color: #eee;
    width: fit-content;
    margin-left: 2vw;
    text-align: center;
    line-height: 0.9;
    font-size: 250%;
    margin-top: 0;
  }
</style>

While preparing to attach the electrical candles to the christmas tree,
a question popped into my mind.

There are electrical candles that simulate the flickering of real
candles. How complex would an algorithm have to be to be convincing?

I wrote a quick proof of concept in Ruby for a script running in the terminal
which just randomly chooses a grey value to display.

```ruby
#!/usr/bin/env ruby
require 'io/console'
lines, cols = $stdout.winsize

rnd = 0
loop {
  rnd = (rnd * 5 + 17) % 256
  lines.times {
    puts "\e[48;2;#{rnd};#{rnd};#{rnd}m" + (" " * cols) + "\e[0m"
  }
  sleep(0.11)
}
```

It uses a simple [linear congruential
generator](https://en.wikipedia.org/wiki/Linear_congruential_generator)
as random number generator with a period of 256. This period is already
large enough for the repetition to be not noticeable for a human being.

But there were obvious improvements, like using a better color and smoothing
the transition from one color to the next.

I think given its simplicity it already works quite well. But the color
transitions are quite harsh so for the second version I restricted the color
value range, varied only one color channel, and added some ASCII art.

```javascript
  function updateFlameColor() {
    rnd = (rnd * 5 + 17) % 256;

    // mapping the random value onto a color range from yellow to orange
    const r = 255;
    const g = 100 + rnd / 2; // 100..228
    const b = 0;

    flameEl.style.color = `rgb(${r},${g},${b})`;

    setTimeout(updateFlameColor, 110);
  }
```

This results in this cozy animation:

<pre id="candle">
<span class="flame" style='color: rgb(255, 200, 0)'>O</span>
<span>|</span>
<span>===</span>
</pre>
<script>
  const flameEl = document.querySelector(".flame");
  let rnd = 0;

  function updateFlameColor() {
    rnd = (rnd * 5 + 17) % 256;

    // mapping the random value onto a color range from yellow to orange
    const r = 255;
    const g = 100 + rnd / 2; // 100..228
    const b = 0;

    flameEl.style.color = `rgb(${r},${g},${b})`;

    setTimeout(updateFlameColor, 110);
  }

  updateFlameColor();
</script>
