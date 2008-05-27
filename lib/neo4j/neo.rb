require 'singleton'

module Neo4j
  
  
  #
  # Allows start and stop the Neo4j service
  # 
  # A wrapper class around org.neo4j.api.core.EmbeddedNeo
  # 
  class Neo
    include Singleton
    attr_accessor :db_storage

    #
    # meta_nodes : Return the meta nodes containing relationship to all MetaNode objects
    #
    attr_reader :meta_nodes 
    
    #
    # starts neo with a database at the given storage location
    # 
    def start(storage = "var/neo")
      @db_storage = storage
      raise Exception.new("Already started neo") if @neo
      @neo = EmbeddedNeo.new(@db_storage)  
      
      ref_node = nil
      Neo4j::transaction do
        ref_node = @neo.getReferenceNode
        @meta_nodes = MetaNodes.new(ref_node)
      end
      
      $neo_logger.info{ "Started neo. DB at '#{@db_storage}'"}

    end
    
    
    #
    # Create an internal neo node (returns a java object)
    #
    def create_node
      @neo.createNode
    end
    
    # 
    # Find the meta node represented by the given Ruby class name
    #
    def find_meta_node(classname) 
      @meta_nodes.nodes.find{|node| node.ref_classname == classname}    
    end
    
    #
    # Returns a Node object that has the given id or nil
    # 
    def find_node(id) 
      neo_node = @neo.getNodeById(id)
      load_node(neo_node)
    end
  
    def load_node(neo_node)
      classname = neo_node.get_property('classname')
      
      # find the class (classes are constants) 
      clazz = classname.split("::").inject(Kernel) do |container, name|
        container.const_get(name.to_s)
      end
      clazz.new(neo_node)
    end
    
    #
    # Stop neo
    # Must be done before the program stops
    #
    def stop
      $neo_logger.info {"stop neo #{@neo}"}
      @neo.shutdown  
      @neo = nil
    end
    
  end
end
