require 'time'
require 'digest'

module Cauterize
  class CBuilder
    attr_reader :h, :c

    def initialize(h_file, c_file, name="cauterize")
      @h = h_file
      @c = c_file
      @name = name
    end

    def build
      build_h
      build_c
    end

    private

    def build_h
      f = default_formatter

      excluder = @name.up_snake + "_H_#{Time.now.to_i}"
      f << "/* WARNING: This is generated code. Do not edit this file directly. */"
      f << ""
      f << "#ifndef #{excluder}"
      f << "#define #{excluder}"
      f.blank_line
      f << %Q{#include <cauterize.h>}
      f.blank_line
      f << "#define GEN_VERSION (\"#{Cauterize.get_version}\")"
      f << "#define GEN_DATE (\"#{DateTime.now.to_s}\")"
      f.blank_line

      f << "#define MODEL_HASH_LEN (#{BaseType.digest_class.new.length})"
      f << "#define MODEL_HASH {#{BaseType.model_hash.bytes.to_a.join(", ")}}"
      f.blank_line

      instances = BaseType.all_instances
      builders = instances.map {|i| Builders.get(:c, i)}

      builders.each { |b| b.typedef_decl(f) }
      builders.each { |b| b.enum_defn(f) }
      builders.each { |b| b.struct_proto(f) }
      builders.each { |b| b.struct_defn(f) }

      f << "#ifdef __cplusplus"
      f << "extern \"C\" {"
      f << "#endif"

      builders.each { |b| b.packer_proto(f) }
      builders.each { |b| b.unpacker_proto(f) }

      f << "#ifdef __cplusplus"
      f << "}"
      f << "#endif"

      f.blank_line
      f << "#endif /* #{excluder} */"
      f << "\n"

      File.open(@h, "wb") do |fh|
        fh.write(f.to_s)
      end
    end

    def build_c
      f = default_formatter

      f << "/* WARNING: This is generated code. Do not edit this file directly. */"
      f << ""
      f << %Q{#include <cauterize_util.h>}
      f << %Q{#include "#{@name}.h"}
      f.blank_line

      f << %Q{/* Some extra configuration information may be provided. This is}
      f << %Q{ * a good place for the user to put prototypes or defines used}
      f << %Q{ * elsewhere. This is a user defined file and should be in the}
      f << %Q{ * include search path. */}
      f << %Q{#ifdef USE_CAUTERIZE_CONFIG_HEADER}
      f << %Q{#include "#{@name}_config.h"}
      f << %Q{#endif}
      f.blank_line

      instances = BaseType.all_instances
      builders = instances.map {|i| Builders.get(:c, i)}

      builders.each { |b| b.wrapped_packer_defn(f); f.blank_line }
      builders.each { |b| b.wrapped_unpacker_defn(f); f.blank_line }

      File.open(@c, "wb") do |fh|
        fh.write(f.to_s)
      end
    end
  end
end
