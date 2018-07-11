require "../to_object"
require "mysql"

db = DB.open "mysql://root:password@localhost:3306/test"

class Person
  JSON.mapping(
    id: String?,
    username: String
  )

  def initialize(@id, @username)
  end
end

# create a person object and insert it into the db
p = Person.new("1234", "test")
query, args = Objectify.to_sql("INSERT INTO person (person_id, username) VALUES({id}, {username})", p)
db.exec query, args

puts "selecting single object"

# create our person object and use it to select
p2 = Person.new(nil, "test")
query, args = Objectify.to_sql("SELECT person_id as id, username FROM person where username = {username}", p2)

results = db.query query, args do |rs|
  res = Objectify.to_object(rs, Person)
  puts res.id
  puts res.username
end

puts "selecting array of object"

results = db.query "SELECT person_id as id, username FROM person" do |rs|
  res = Objectify.to_objects(rs, Person)
  res.each do |person|
    puts person.id
    puts person.username
    puts "----"
  end
end
