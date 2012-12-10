=begin
1. Add new middleware Faraday::Response::Headers (which will save headers with response)
2. Add this middleware to connection stack
3. Handle etag/last_modified options in request
4. Patch api methods to support options when needed
=end

# 1
module Faraday
  class Response::Headers < Faraday::Middleware
    LAST_MODIFIED   = 'last-modified'.freeze
    ETAG            = 'etag'.freeze
    RATE_LIMIT      = 'x-ratelimit-limit'.freeze
    RATE_REMAINING  = 'x-ratelimit-remaining'.freeze

    def call(env)
      @app.call(env).tap do |response|
        next unless response.body
        response.body.instance_eval do
          self.last_modified = response.headers[LAST_MODIFIED]
          self.etag          = response.headers[ETAG]

          define_singleton_method :rate_limit do
            response.headers[RATE_LIMIT].to_i
          end

          define_singleton_method :rate_remaining do
            response.headers[RATE_REMAINING].to_i
          end
        end
      end
    end
  end
end

# 2
module Octokit::Connection
  private

  def connection(options={})
    options = {
      :authenticate     => true,
      :force_urlencoded => false,
      :raw              => false,
      :ssl              => { :verify => false },
      :url              => api_endpoint
    }.merge(options)

    if !proxy.nil?
      options.merge!(:proxy => proxy)
    end

    if !oauthed? && !authenticated? && unauthed_rate_limited?
      options.merge!(:params => unauthed_rate_limit_params)
    end

    # TODO: Don't build on every request
    connection = Faraday.new(options) do |builder|

      builder.request :json

      # PATCH
      builder.use Faraday::Response::Headers

      builder.use Faraday::Response::RaiseOctokitError
      builder.use FaradayMiddleware::FollowRedirects
      builder.use FaradayMiddleware::Mashify

      builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/

      faraday_config_block.call(builder) if faraday_config_block

      builder.adapter *adapter
    end

    if options[:authenticate] and authenticated?
      connection.basic_auth authentication[:login], authentication[:password]
    end

    connection.headers[:user_agent] = user_agent

    connection
  end
end

# 3
module Octokit::Request
  private

  def request(method, path, options={})
    path.sub(%r{^/}, '') #leading slash in path fails in github:enterprise

    token = options.delete(:access_token) ||
            options.delete(:oauth_token)  ||
            oauth_token

    conn_options = {
      :authenticate => token.nil?
    }

    response = connection(conn_options).send(method) do |request|

      request.headers['Accept'] =  options.delete(:accept) || 'application/vnd.github.beta+json'

      # PATCH
      request.headers['If-None-Match'] = options.delete(:etag) if options[:etag]
      request.headers['If-Modified-Since'] = options.delete(:last_modified) if options[:last_modified]

      if token
        request.headers[:authorization] = "token #{token}"
      end

      case method
      when :get
        if auto_traversal && per_page.nil?
          self.per_page = 100
        end
        options.merge!(:per_page => per_page) if per_page
        request.url(path, options)
      when :delete, :head
        request.url(path, options)
      when :patch, :post, :put
        request.path = path
        request.body = MultiJson.dump(options) unless options.empty?
      end

      if Octokit.request_host
        request.headers['Host'] = Octokit.request_host
      end

    end

    response
  end
end

# 4
module Octokit::Client::Users
  def user(user=nil, options={})
    if user
      get "users/#{user}", options
    else
      get "user", options
    end
  end
end
