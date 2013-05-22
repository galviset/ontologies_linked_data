require 'goo'
require 'ostruct'

module LinkedData
  extend self
  attr_reader :settings

  @settings = OpenStruct.new
  @settings_run = false

  def config(&block)
    return if @settings_run
    @settings_run = true

    overide_connect_goo = false

    yield @settings, overide_connect_goo if block_given?

    # Set defaults
    @settings.goo_port          ||= 9000
    @settings.goo_host          ||= "localhost"
    @settings.search_server_url ||= "http://localhost:8983/solr"
    @settings.repository_folder ||= "./test/data/ontology_files/repo"
    @settings.rest_url_prefix   ||= "http://data.bioontology.org/"
    @settings.enable_security   ||= false
    @settings.redis_host        ||= "localhost"
    @settings.redis_port        ||= 6379

    puts ">> Using rdf store #{@settings.goo_host}:#{@settings.goo_port}"
    puts ">> Using search server at #{@settings.search_server_url}"
    puts ">> Using Redis instance at #{@settings.redis_host}:#{@settings.redis_port}"

    connect_goo unless overide_connect_goo
  end

  ##
  # Connect to goo by configuring the store and search server
  def connect_goo
    port              ||= @settings.goo_port
    host              ||= @settings.goo_host

    begin
      Goo.configure do |conf|
        conf.add_sparql_backend(:main, query: "http://#{host}:#{port}/sparql/",
                                data: "http://#{host}:#{port}/data/",
                                update: "http://#{host}:#{port}/update/",
                                options: { rules: :NONE })

        conf.add_search_backend(:main, service: @settings.search_server_url)
        conf.add_redis_backend(host: @settings.redis_host)
      end
    rescue Exception => e
      abort("EXITING: Cannot connect to triplestore and/or search server:\n  #{e}\n#{e.backtrace.join("\n")}")
    end
  end

  ##
  # Configure ontologies_linked_data namespaces
  # We do this at initial runtime because goo needs namespaces for its DSL
  def goo_namespaces
    Goo.configure do |conf|
      conf.add_namespace(:omv, RDF::Vocabulary.new("http://omv.ontoware.org/2005/05/ontology#"))
      conf.add_namespace(:skos, RDF::Vocabulary.new("http://www.w3.org/2004/02/skos/core#"))
      conf.add_namespace(:owl, RDF::Vocabulary.new("http://www.w3.org/2002/07/owl#"))
      conf.add_namespace(:rdfs, RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#"))
      conf.add_namespace(:metadata, RDF::Vocabulary.new("http://data.bioontology.org/metadata/"), default = true)
    end
  end
  self.goo_namespaces

end
