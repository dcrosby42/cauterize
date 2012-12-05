class Field
  attr_reader :name, :type, :init, :desc
  def self.from_hash(hash)
    validate(hash, "name", "type", "init", "description")
    Field.new(hash["name"], hash["type"], hash["init"], hash["description"])
  end

  def initialize(name, type, init, description)
    @name = name
    @type = Type.parse(type)
    @init = init
    @desc = description
  end

  def format(formatter)
    formatter << "/* #{@desc} */"
    formatter << "#{decl};"
  end

  def decl
    "#{@type.type_str} #{@name}#{@type.array_str}"
  end
end
