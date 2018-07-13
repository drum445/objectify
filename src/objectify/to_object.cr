require "json"

module Objectify
  # currently uses JSON::Serializable to create custom initialiser
  macro included
    include JSON::Serializable
  end

  # T.class so we can get type variable of the object and create an array
  def self.to_object(rs, object_type)
    self.build(rs, object_type)[0]
  end

  def self.to_objects(rs, object_type)
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

  # transform each row to object
  private def self.transform_one(rs, object_type)
    object = object_type.new
    col_names = rs.column_names
    req_fields = get_required(object)

    # after we have our colum names and required fields, make sure the required fields
    # are present in the result set, if it isn't this will cause memory issues later
    req_fields.each do |field|
      if !col_names.includes?(field)
        raise Exception.new("Result set is missing required field '#{field}'")
      end
    end

    col_names.each do |col|
      self.set(object, col, rs.read)
    end

    return object
  end

  # loop through our object variables and find what cannot be nil
  private def self.get_required(obj : T) forall T
    req = Array(String).new
    {% for ivar in T.instance_vars %}
      if {{!ivar.type.nilable?}}
        req.push({{ivar.stringify}})
      end
    {% end %}

    return req
  end

  # pass through object, col name, col value and attempt to set it
  # if it cannot return false, this will be due to either a type miss match or
  private def self.set(obj : T, attr, val) forall T
    {% for ivar in T.instance_vars %}
      if {{ivar.stringify}} == attr
        # check that the var is correct type for field
        if val.is_a?({{ivar.type}})
          obj.{{ivar.id}} = val
        else
          raise Exception.new("Result set has wrong type for field '#{attr}'")
        end
      end
    {% end %}
  end
end
