require "./objectify/*"
require "json"

module Objectify
  # T.class so we can get type variable of the object and create an array
  def self.to_object(rs, object_type)
    self.get(rs, object_type)[0]
  end

  def self.to_objects(rs, object_type)
    self.get(rs, object_type)
  end

  private def self.get(rs, object_type : T.class) forall T
    result = Array(T).new
    rs.each do
      result.push(self.transform_one(rs, object_type))
    end

    result
  end

  private def self.transform_one(rs, object_type)
    col_names = rs.column_names

    # build a JSON string using our columns and fields
    string = JSON.build do |json|
      json.object do
        col_names.each do |col|
          json_encode_field json, col, rs.read
        end
      end
    end

    # create an object using the JSON created above
    object = object_type.from_json(string)
    # return object
    return object
  end

  private def self.json_encode_field(json, col, value)
    case value
    when Bytes
      # custom json encoding. Avoid extra allocations.
      json.field col do
        json.array do
          value.each do |e|
            json.scalar e
          end
        end
      end
    when Time::Span
      # Time Span isn't supported
    else
      # encode the value as their built in json format.
      json.field col do
        value.to_json(json)
      end
    end
  end
end

require "db"
require "mysql"


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

db = DB.open "mysql://root:password@localhost:3306/todo_list"

db.query "SELECT '123' as note_id, 'hello' as content, 4 as likes, NOW() as updated, NULL as optional FROM DUAL
          UNION ALL
          SELECT '444', 'asd', 66, NOW(), 0 FROM DUAL;" do |rs|
    notes = Objectify.to_objects(rs, Note)

    puts notes # => Array of Note
end