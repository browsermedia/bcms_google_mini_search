# A general purpose API for querying a Google Search Appliance for results.
module GSA

  # Represents a single instance of a Google Mini
  class Engine
    attr_accessor :host, :port, :path, :default_collection, :default_front_end

    def initialize(options = {})
      self.port = 8080
      self.path = "/search"
      self.host = options[:host]
      self.default_front_end = options[:front_end]
      self.default_collection = options[:collection]
    end

    # Return a Hash suitable to be passed to SearchResult.find()
    def options_for_query
      {:host=>host, :front_end=>default_front_end, :collection=>default_collection}
    end
  end

  # GSA support slightly different features than Google Mini.
  class Appliance < Engine



    # Fetch a set of Suggested queries, based on a given query.
    #
    # See http://code.google.com/apis/searchappliance/documentation/50/admin_searchexp/ce_understanding.html#h3drc for the spec.
    # See http://groups.google.com/group/Google-Search-Appliance-Help/browse_thread/thread/8a821fc8475a5e24/34a5c3c8ab74ed35?hl=en&lnk=gst#34a5c3c8ab74ed35
    #   for details about how this is implemented.
    #
    # Clustering (aka Narrow your search) is only supported by GSA.
    # @param [String] query A term to fetch 'suggested' queries for/
    # @return [GSA::SuggestedQueries] A set of suggested queries
    def find_narrow_search_results(query)
      url = narrow_search_results_url(query)
      document = SearchResult.fetch_document(url)
      SuggestedQueries.new(document)
    end

    private

    # Returns the URL to GET a set of Dynamic Search Clusters for a particular query.
    def narrow_search_results_url(query)
      "#{host}/cluster?coutput=xml&q=#{CGI::escape(query)}&site=#{default_collection}&client=#{default_front_end}&output=xml_no_dtd"
    end
  end

  # Represents a set of suggested search terms, based on results from a GSA.
  # AKA DynamicResultClusters
  class SuggestedQueries
    def initialize(xml_as_string, appliance=nil)
      @clusters = []
      doc = REXML::Document.new(xml_as_string)
      doc.elements.each('toplevel/Response/cluster/gcluster') do |ele|
        @clusters << Suggestion.new(ele.elements["label"].attributes["data"])
      end

    end

    delegate :each, :each_with_index, :size, '[]', :to=>:clusters

    private

    def clusters
      @clusters
    end


    # Since generating are handled in the view, this might no longer be necessary a separate class, and could probably be converted into a String.
    class Suggestion
      attr_accessor :query

      def initialize(query)
        self.query = query
      end

    end
  end




  class Query
    attr_reader :engine, :query, :front_end, :collection

    def initialize(options={})
      @engine = options[:engine]
      @query = options[:query]
      @front_end = options[:front_end]
      @collection = options[:collection]
    end
  end

  # Represent a collection of results from a GSA search.
  class Results

    attr_accessor :query


  end

  # Represents a single result (aka Hit) from a GSA query.
  # Defined by http://code.google.com/apis/searchappliance/documentation/46/xml_reference.html#results_xml_tag_r
  class Result
    attr_accessor :number, :title, :url, :description, :size, :cache_id, :results

    # @param [RXEML::Element] xml_element The <R> result from GSA a search.
    def initialize(xml_element = nil)
      return if xml_element == nil
      self.number = xml_element.attributes["N"]
      self.title = xml_element.elements["T"].text
      self.url = xml_element.elements["U"].text
      self.description = xml_element.elements["S"].text

      cache_element = xml_element.elements["HAS/C"]

      if cache_element
        self.size = cache_element.attributes["SZ"]
        self.cache_id = cache_element.attributes["CID"]
      else
        self.size = ""
        self.cache_id=""
      end

    end

    # Returns the value for q if a user wants to request the cached version of this document.
    def cached_document_param
      param = "cache:#{cache_id}:#{url}"
      if results
        param += "+#{results.query}"
      end
      param
    end

    def cached_document_url(gsa_query)
      SearchResult.query_url(cached_document_param, {:host=>gsa_query.engine.host, :collection=>gsa_query.collection, :front_end=>gsa_query.front_end, :as_xml=>false})
    end
  end
end
