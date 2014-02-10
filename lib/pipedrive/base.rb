require 'httparty'
require 'ostruct'
require 'forwardable'

module Pipedrive

  # Globally set request headers
  HEADERS = {
    "User-Agent"    => "Ruby.Pipedrive.Api",
    "Accept"        => "application/json",
    "Content-Type"  => "application/x-www-form-urlencoded"
  }

  # Base class for setting HTTParty configurations globally
  class Base < OpenStruct

    include HTTParty
    base_uri 'api.pipedrive.com/v1'
    headers HEADERS
    format :json

    extend Forwardable
    def_delegators 'self.class', :delete, :get, :post, :put, :resource_path, :bad_response

    attr_reader :data

    # Create a new CloudApp::Base object.
    #
    # Only used internally
    #
    # @param [Hash] attributes
    # @return [CloudApp::Base]
    def initialize(attrs = {})
      if attrs['data']
        super( attrs['data'] )
      else
        super(attrs)
      end
    end

    # Updates the object.
    #
    # @param [Hash] opts
    # @return [Boolean]
    def update(opts = {}, api_token = nil)
      original_path = "#{resource_path}/#{id}"
      path = api_token ? "#{original_path}?api_token=#{api_token}" : original_path
      res = put path, :body => opts
      !!(res.success? && @table.merge!(res['data'].symbolize_keys))
    end

    class << self
      # Sets the authentication credentials in a class variable.
      #
      # @param [String] email cl.ly email
      # @param [String] password cl.ly password
      # @return [Hash] authentication credentials
      def authenticate(token)
        default_params :api_token => token
      end

      # Examines a bad response and raises an appropriate exception
      #
      # @param [HTTParty::Response] response
      def bad_response(response)
        if response.class == HTTParty::Response
          raise HTTParty::ResponseError, response
        end
        raise StandardError, 'Unknown error'
      end

      def new_list( attrs )
        attrs['data'].is_a?(Array) ? attrs['data'].map {|data| self.new( 'data' => data ) } : []
      end

      def all(response = nil, opts={}, api_token = nil)
        opts.merge!({:api_token => api_token}) if api_token
        res = response || get(resource_path, opts)
        if res.ok?
          res['data'].nil? ? [] : res['data'].map{|obj| new(obj)}
        else
          puts res
          bad_response(res)
        end
      end

      def create( opts = {}, api_token = nil)
        path = api_token ? "#{resource_path}?api_token=#{api_token}" : api_token
        res = post path, :body => opts
        if res.success?
          res['data'] = opts.merge res['data']
          new(res)
        else
          bad_response(res)
        end
      end

      def find(id, api_token = nil)
        opts = {}
        opts.merge!({"api_token" => api_token}) if api_token
        res = get "#{resource_path}/#{id}", :query => opts
        res.ok? ? new(res) : bad_response(res)
      end

      def find_by_name(name, opts={}, api_token = nil)
        opts.merge!({:api_token => api_token}) if api_token
        res = get "#{resource_path}/find", :query => { :term => name }.merge(opts)
        res.ok? ? new_list(res) : bad_response(res)
      end

      def resource_path
        # The resource path should match the camelCased class name with the
        # first letter downcased.  Pipedrive API is sensitive to capitalisation
        klass = name.split('::').last
        klass[0] = klass[0].chr.downcase
        klass.end_with?('y') ? "/#{klass.chop}ies" : "/#{klass}s"
      end
    end
  end

end
