require "json"

# allow Object.from_rs(rs), will work with arrays and single objects
def Object.from_rs(rs) : self
  if self.is_a?(Array.class)
    new_array = self.new
    object_type = typeof(new_array[0])
    return Objectify.to_many(rs, object_type)
  else
    return Objectify.to_one(rs, self)
  end
end

module Objectify
  module Mappable
    # currently uses JSON::Serializable to create custom initialiser
    macro included
      include JSON::Serializable
    end
  end

  # T.class so we can get type variable of the object and create an array
  def self.to_one(rs, object_type)
    self.build(rs, object_type)[0]
  end

  def self.to_many(rs, object_type)
    self.build(rs, object_type)
  end

  private def self.build(rs, object_type : T.class) forall T
    result = Array(T).new
    rs.each do
      temp = self.transform_one(rs, object_type)
      result.push(temp)
    end

    result
  end

  # transform each row to l
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
    begin
      object = object_type.from_json(string)
    rescue ex
      message = parse_error(ex.message)
      raise Exception.new(message)
    end

    # return object
    return object
  end

  # build a json object for the field
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

  private def self.parse_error(message)
    begin
      field = message.to_s.split(": ")[1]
      return "Result set is missing required field: #{field}"
    rescue
      field = message.to_s.split("#")[1].split(" ")[0]
      return "Invalid data type for field: #{field}"
    end
  end
end
