module UglifierWithSourceMaps
  class Compressor
    def self.call(*args)
      new.call(*args)
    end

    def initialize(options = {})
      @uglifier = Uglifier.new(options)
    end

    def compress(data, context)
      minified_data, sourcemap = Uglifier.new.compile_with_map(data)

      digest_value = digest(minified_data)
      minified_filepath = [Rails.application.config.assets.prefix, "#{context.logical_path}-#{digest_value}.js"].join('/')
      sourcemap_filepath = "tmp/#{context.logical_path}-#{digest_value}.map"
      unminified_filepath = "tmp/#{context.logical_path}-#{digest_value}.js"

      map = JSON.parse(sourcemap)
      map["file"] = minified_filepath
      map["sources"] = [unminified_filepath]

      FileUtils.mkdir_p File.dirname(File.join(Rails.root, sourcemap_filepath))
      FileUtils.mkdir_p File.dirname(File.join(Rails.root, unminified_filepath))

      # Write sourcemap and uncompressed js
      File.open(File.join(Rails.root, sourcemap_filepath), "w") { |f| f.puts map.to_json }
      File.open(File.join(Rails.root, unminified_filepath), "w") { |f| f.write(data) }

      json_file = File.join(Rails.root, "tmp/sourcemap.json")
      source_maps = []
      if File.exist?(json_file)
        source_maps = JSON.parse(File.read(json_file))
      end
      source_maps << {
        version: digest_value,
        minified_url: "#{AppConfig.domain}#{minified_filepath}",
        sourcemap_file: sourcemap_filepath,
        unminified_file: unminified_filepath
      }
      File.open(json_file, "w") { |f| f.write(source_maps.to_json) }

      minified_data
    end

    def digest(io)
      Rails.application.assets.digest.update(io).hexdigest
    end
  end
end





