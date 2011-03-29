module GSA

  # Represents a single instance of a Google Search Appliance or Mini
  class Engine
    attr_accessor :host, :port, :path

    def initialize(options = {})
      self.port = 8080
      self.path = "/search"
      self.host = options[:host]
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

    def initialize

    end
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
