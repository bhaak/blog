+++
title = 'Avoid Integer for File Sizes in Postgres'
date = '2026-03-05T12:43:14+01:00'
author = "bhaak"
categories = ['Programming']
tags = ['Postgres', 'Rails']
+++

Here’s a small bug we recently encountered in production.
Occasionally, PDF generation jobs would fail, and the cause turned out to be
a small oversight when designing database tables.

The PDF metadata is stored in a table, and the column for file size was defined
as `integer`, also known as `int4`.

Since this data type is signed in Postgres, those 4 bytes only allow for files
up to 2.1 GB (2&#8239;147&#8239;483&#8239;647 bytes).
You might think, 2^31 bytes ought to be enough for everybody ... except
apparently for our PDFs.

The error is easy to reproduce.

```sql
CREATE TABLE files
(
  name   VARCHAR NOT NULL,
  size   INTEGER NOT NULL CHECK (size >= 0)
);

INSERT INTO files (name, size) VALUES ('filename', power(2, 31));

-- this triggers the following error
ERROR: integer out of range
```

Changing the column to `bigint` (also known as `int8`) resolves the issue.

It would probably be better if Postgres consistently used the more explicit
byte-indicated aliases like `int2`, `int4`, and `int8`, rather than the older
names `smallint`, `integer`, and `bigint`.
The same issue exists with serial and float data types.

Interestingly, Rails 8.1 detects data type overflows before the `INSERT` even
reaches the database.

```ruby
class MyFile < ApplicationRecord
  self.table_name = 'files'
end

3.4.8 :001 > MyFile.create(name: 'filename', size: 2**31)
ActiveModel::RangeError: 2147483648 is out of range for ActiveModel::Type::Integer with limit 4 bytes (ActiveModel::RangeError)
[...]/ruby-3.4.8/gems/activemodel-8.1.2/lib/active_model/type/integer.rb:90:in 'ActiveModel::Type::Integer#serialize_cast_value'
```

Even though Rails provides a clearer error message, both Rails and Postgres
leave you guessing *which* column is too small.
