# ~*~ encoding: utf-8 ~*~
require 'net/http'
require 'uri'
require 'open-uri'
require File.expand_path '../../helpers', __FILE__

# PlantUML Diagrams
#
# Render an inline plantuml diagram by generating a PNG image using the
# plantuml.jar tool.
#
class Gollum::Filter::PlantUML < Gollum::Filter

  #path of plantuml.jar
  JAR = "/root/plantuml/plantuml.jar"
  #path of java
  JAVA= "java"

  # Extract all sequence diagram blocks into the map and replace with
  # placeholders.
  def extract(data)
    return data if @markup.format == :txt
    data.gsub(/(@startuml\r?\n.+\r?\n@enduml)/m) do
      id       = Digest::SHA1.hexdigest($1)
      @map[id] = { :code => $1 }
      id
    end
  end

  # Process all diagrams from the map and replace the placeholders with
  # the final HTML.
  #
  def process(data)
    out_path_dir = ::File.expand_path ::File.join(@markup.page.wiki.path, 'tmp')
    Dir.mkdir out_path_dir unless ::File.exists? out_path_dir
    @map.each do |id, spec|
      data.gsub!(id) do
        render_plantuml(id, spec[:code],out_path_dir)
      end
    end
    data
  end

  private

  def render_plantuml(id, code,filepath)
    out_path = ::File.join(filepath, id)
    unless File::exists?(filepath+"/"+id)
      File.open(filepath+"/"+id, "w") do |file|
            file << code
      end
    end
    unless File::exists?( filepath+"/"+id+".png" )
      puts("#{JAVA} -jar #{JAR} #{filepath}/#{id} -o '#{filepath}'")
      system("#{JAVA} -jar #{JAR} #{filepath}/#{id} -o '#{filepath}'")
        unless $?.success?
          html_error("failed to generate uml image")
        end
    end
    "<img src=\"tmp/#{id}.png\" />"
  end

end
