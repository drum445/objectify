# objectify

Crystal library to be used with the db lib.  
Allows SQL result sets to be transformed into an object or array of object  
Also allows SQL scripts to be injected with the correct variables from the passed object  
  Currently requires the object to be setup with JSON.mapping

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
```

##### Result set to object
```crystal
require "db"
require "mysql"
require "objectify"

# Your class that is to be built from SQL (requires JSON Mapping)
class Note
    JSON.mapping(
        note_id: String,
        content: String,
        likes: Int64,
        updated: Time
      )
end

db = DB.open "mysql://root:password@localhost:3306/test"

db.query "SELECT '123' as note_id, 'hello' as content, 4 as likes, NOW() as updated FROM DUAL;" do |rs|
    note = Objectify.to_object(rs, Note)

    puts note # => Note Object
end
```

##### Result set to array of object
```crystal
require "db"
require "mysql"
require "objectify"

# Your class that is to be built from SQL (requires JSON Mapping)
class Note
    JSON.mapping(
        note_id: String,
        content: String,
        likes: Int64,
        updated: Time,
        optional: Int64?
      )
end

db = DB.open "mysql://root:password@localhost:3306/test"

db.query "SELECT '123' as note_id, 'hello' as content, 4 as likes, NOW() as updated, NULL as optional FROM DUAL
          UNION ALL
          SELECT '444', 'asd', 66, NOW(), 0 FROM DUAL;" do |rs|
    notes = Objectify.to_objects(rs, Note)

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
  JSON.mapping(
    id: String,
    username: String
  )

  def initialize(@id, @username)
  end
end

# create a person object and insert it into the db
p = Person.new("1234", "test")
query, args = Objectify.to_sql("INSERT INTO person (person_id, username) VALUES({id}, {username})", p)
db.exec query, args
```
## Todo
Better error handling  
Possible alternative to needing JSON.mapping

## Contributors

- [drum445](https://github.com/drum445) ed - creator, maintainer
