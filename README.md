# objectify

Crystal micro-orm library, similar to what dapper supplies for .NET Core  
Main features:  
	SQL result sets to be transformed into an object or array of object  
	SQL scripts to be injected with the correct variables from the passed object  

For the mapping to work (rs -> object) the column name in the result set must match the class' attribute name

Uses the JSON library from stdlib to allow from_json to be used to prevent the need for messy custom initializers on each class.  
Simply ```include Objectify::Mappable``` in classes that will be created from a SQL result set  
This include is not needed if your class is using JSON.mapping  

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  objectify:
    github: drum445/objectify
```

## Usage

```crystal
require "objectify"

# include objectify's mappable in your class
class Foo
  include Objectify::Mappable
end
```

##### Result set to object (to_one)
```crystal
require "db"
require "mysql"
require "objectify"

# Your class that is to be built from SQL, will raise exception if:
# A non-nillable field is not in the result set 
# Or a field in the result set does not match the attribute's type
class Note
  include Objectify::Mappable
  property note_id : String
  property content : String
  property likes : Int64
  property updated : Time

  def initialize(@note_id, @content, @likes, @updated)
  end  
end

db = DB.open "mysql://root:password@localhost:3306/test"

db.query "SELECT '123' as note_id, 'hello' as content, 4 as likes, NOW() as updated FROM DUAL;" do |rs|
    note = Objectify.to_one(rs, Note)

    puts note # => Note Object
end
```

##### Result set to array of object (to_many)
```crystal
require "db"
require "mysql"
require "objectify"

# Your class that is to be built from SQL
class Note
  include Objectify::Mappable
  property note_id : String
  property content : String
  property likes : Int64
  property updated : Time? # nillable as it is not in the result set
end

db = DB.open "mysql://root:password@localhost:3306/test"

db.query "SELECT '123' as note_id, 'hello' as content, 4 as likes FROM DUAL
          UNION ALL
          SELECT '444', 'asd', 66 FROM DUAL;" do |rs|
    notes = Objectify.to_many(rs, Note)

    puts notes # => Array of Note
end

```

#### Inserting object into DB
```crystal
require "db"
require "mysql"
require "objectify"

db = DB.open "mysql://root:password@localhost:3306/test"

class Person
  property id : String
  property username : String

  def initialize(@id, @username)
  end
end

# create a person object and insert it into the db
p = Person.new("1234", "test")
query, args = Objectify.to_sql("INSERT INTO person (person_id, username) VALUES({id}, {username})", p)
db.exec query, args
```
## Error Handling
Checks for required fields (non nillable) ```Result set is missing required field: foo```  
Checks for correct data type: ```Invalid data type for field: foo```  



## Contributors

- [drum445](https://github.com/drum445) ed - creator, maintainer
