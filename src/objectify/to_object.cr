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
    object = object_type.new
    col_names = rs.column_names

    col_names.each_with_index do |col, idx|
      self.set(object, col, rs.read)
    end

    return object
  end

  private def self.set(obj : T, attr, val) forall T
    {% for ivar in T.instance_vars %}
      if {{ivar.stringify}} == attr
        # check that the var is correct type for field
        if val.is_a?({{ivar.type}})
          obj.{{ivar.id}} = val
        end
      end
    {% end %}
  end
end
