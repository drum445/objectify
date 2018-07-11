require "./objectify/*"
require "json"
require "db"

module Objectify
  def self.to_sql(script : String, object)
    fields = self.get_fields(script)

    # create the args
    args = [] of DB::Any
    fields.each do |field|
      args.push(self.send(object, field))
    end

    # prepare the script for db
    fields.each do |field|
      script = script.gsub "{#{field}}", "?"
    end

    return script, args
  end

  private def self.send(obj : T, attr) forall T
    {% for ivar in T.instance_vars %}
      if {{ivar.stringify}} == attr
        return obj.@{{ivar.id}}
      end
    {% end %}
  end

  private def self.get_fields(script : String)
    fields = Array(String).new
    found = false
    field = ""
    script.split("").each do |char|
      if char == "{"
        found = true
        next
      end

      if char == "}"
        fields.push(field)
        field = ""
        found = false
      end

      if found
        field += char
      end
    end

    fields
  end
end
