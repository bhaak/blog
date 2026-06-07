+++
date = '2026-05-14T15:23:13+02:00'
draft = false
title = 'Accessing ActiveRecord attribute slower than local variable'
tags = ["Performance", "Ruby", "Rails"]
categories = ["Programming"]
+++

I was deep in a performance optimization flow when I stumbled upon this part in
[a ruby-prof graph](https://github.com/ruby-prof/ruby-prof):

<style>
.prof {
  .hot   { color: hsl(8,   80%, 65%); }
  .warm  { color: hsl(30,  80%, 65%); }
  .mid   { color: hsl(55,  80%, 65%); }
  .cool  { color: hsl(100, 80%, 65%); }
  .cold  { color: hsl(118, 80%, 65%); }
  .method { color: hsl(205, 60%, 65%); }
  .calls { color: hsl(95, 40%, 65%); }
}

:root[data-theme="light"] .prof {
  .hot   { color: hsl(8,   70%, 42%); }
  .warm  { color: hsl(28,  70%, 40%); }
  .mid   { color: hsl(48,  65%, 36%); }
  .cool  { color: hsl(100, 55%, 32%); }
  .cold  { color: hsl(130, 50%, 30%); }
  .method { color: hsl(221, 84%, 53%); }
  .calls  { color: hsl(142, 86%, 36%); }
}
</style>

<pre style='background: inherit' class='prof'>
<code class="language-text" data-lang="text"><span class="cool">- 17.59%</span> <span class="hot">(73.45%)</span> <span class="method">SomeTable::GeneratedAttributeMethods#some_attribute</span> <span class="calls">[30263106 calls, 44665545 total]</span>
<span class="cool">  - 15.24%</span> <span class="hot">(86.62%)</span> <span class="method">ActiveRecord::AttributeMethods::Read#_read_attribute</span> <span class="calls">[30263106 calls, 49437307 total]</span>
<span class="cool">    - 11.82%</span> <span class="hot">(77.58%)</span> <span class="method">ActiveModel::AttributeSet#fetch_value</span> <span class="calls">[30263106 calls, 49068748 total]</span>
<span class="cold">      - 5.44%</span> <span class="mid">(46.06%)</span> <span class="method">ActiveModel::AttributeSet#[]</span> <span class="calls">[30263106 calls, 49303667 total]</span>
<span class="cold">        - 2.32%</span> <span class="mid">(42.58%)</span> <span class="method">Hash#[]</span> <span class="calls">[30263106 calls, 72892138 total]</span>
<span class="cold">      - 2.05%</span> <span class="cool">(17.36%)</span> <span class="method">ActiveModel::Attribute#value</span> <span class="calls">[30263106 calls, 49274896 total]</span>
</code></pre>

ActiveRecord stores attributes internally in a hash, which is more expensive than I expected.

Naturally, I benchmarked this to come up with a faster access method.
I tried various alternative methods and although sources on the internet suggested some might be
faster, no ActiveRecord-native way of accessing attributes was faster than the standard method.

[This gist](https://gist.github.com/bhaak/5e62455f96792183cf3bdac6e3ac83e3)
contains the benchmark I ran.

The only way I could speed up access was by caching the value in a local instance variable, like this:

```ruby
class Records < ActiveRecord::Base
  def ivar_some_string
    @ivar_some_string ||= _read_attribute('some_string')
  end
end
```

I tested this on `arm64-darwin25` and `x86_64-linux`, and it turns out that instance variable lookups
are 2 to 3 times faster than standard ActiveRecord attribute access.
I would not generally recommend this optimisation, but in some edge cases, it might be worth a try.

Here are the relevant snippets from the output of the benchmark script:

```text
Records#1 some_string="123456"
Ruby:           ruby 4.0.4 (2026-05-12 revision b89eb1bcbf) +PRISM [arm64-darwin25]
ActiveRecord:   8.1.3

ruby 4.0.4 (2026-05-12 revision b89eb1bcbf) +PRISM [arm64-darwin25]

Calculating -------------------------------------
some_string (public accessor)
                          4.880M (± 1.1%) i/s  (204.94 ns/i) -     24.418M in   5.004799s
ivar_some_string (memoized ivar)
                         15.393M (± 1.9%) i/s   (64.96 ns/i) -     78.333M in   5.090594s

Comparison:
some_string (public accessor):  4879503.2 i/s
ivar_some_string (memoized ivar): 15393424.8 i/s - 3.15x  faster
```

Fun fact, in 65 nanoseconds, light travels 20 meters, and a 3GHz CPU performs 200 cycles.
