+++
date = '2026-05-14T15:23:13+02:00'
draft = true
title = 'Accessing ActiveRecord attribute slower than local variable'
tags = ["Performance", "Ruby", "Rails"]
categories = ["Programming"]
+++

I was deep with a performance improve flow when I stumbled about this part in a ruby-prof
(opencode: link to ruby-prof) graph:


```
- 17.59% (73.45%) SomeTable::GeneratedAttributeMethods#some_attribute [30263106 calls, 44665545 total]
  - 15.24% (86.62%) ActiveRecord::AttributeMethods::Read#_read_attribute [30263106 calls, 49437307 total]
    -11.82% (77.58%) ActiveModel::AttributeSet#fetch_value [30263106 calls, 49068748 total]
      - 5.44% (46.06%) ActiveModel::AttributeSet#[] [30263106 calls, 49303667 total]
        - 2.32% (42.58%) Hash#[] [30263106 calls, 72892138 total]
      - 2.05% (17.36%) ActiveModel::Attribute#value [30263106 calls, 49274896 total]
```

ActiveRecord keeps attributes internally in a hash and that's more expensive than I expected.

Naturally I would benchmark this and try to come up with a faster access method. I tried various
methods and even though the internet claimed some of them should be faster, no ActiveRecord way of
accessing attributes was faster then the standard way.

This gist is the benchmark I ran. (OpenCode: link to gist https://gist.github.com/bhaak/5e62455f96792183cf3bdac6e3ac83e3)

The only way I could speed up access was by caching the value in a local instance variable, like
this:

```
class Records < ActiveRecord::Base
  def ivar_some_string
    @ivar_some_string ||= _read_attribute('some_string')
  end
end
```

Tried it on arm64-darwin25 and x86_64-linux and it turns out that tnstance variable lookups are
2 to 3 times faster than standard ActiveRecord attribute access. I wouldn't generally recommend
doing this optimisation but in some edge cases it might be orth a try.

Here is the relevant snippets from the output of the benchmark script:
```
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

Fun facts: in 65 nano seconds light travels 20 meters or a 3GHz CPU will do 200 cycles.
