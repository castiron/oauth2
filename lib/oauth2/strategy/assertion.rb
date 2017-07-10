require 'jwt'

module OAuth2
  module Strategy
    # The Client Assertion Strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-10#section-4.1.3
    #
    # Sample usage:
    #   client = OAuth2::Client.new(client_id, client_secret,
    #                               :site => 'http://localhost:8080')
    #
    #   params = {:hmac_secret => "some secret",
    #             # or :private_key => "private key string",
    #             :iss => "http://localhost:3001",
    #             :prn => "me@here.com",
    #             :exp => Time.now.utc.to_i + 3600}
    #
    #   access = client.assertion.get_token(params)
    #   access.token                 # actual access_token string
    #   access.get("/api/stuff")     # making api calls with access token in header
    #
    class Assertion < Base
      # Not used for this strategy
      #
      # @raise [NotImplementedError]
      def authorize_url
        raise(NotImplementedError, 'The authorization endpoint is not used in this strategy')
      end

      # Retrieve an access token given the specified client.
      #
      # @param [Hash] params assertion params
      # pass either :hmac_secret or :private_key, but not both.
      #
      #   params :hmac_secret, secret string.
      #   params :private_key, private key string.
      #
      #   params :iss, issuer
      #   params :aud, audience, optional
      #   params :prn, principal, current user
      #   params :exp, expired at, in seconds, like Time.now.utc.to_i + 3600
      #
      # @param [Hash] opts options
      def get_token(params = {}, opts = {})
        assertion = params.delete(:assertion)
        hash = build_request(params, assertion)
        @client.get_token(hash, opts)
      end

      def build_request( params = {}, assertion = nil)
        assertion = build_assertion(params) if assertion.nil?
        {
          :grant_type     => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          :assertion      => assertion,
          :scope          => params[:scope],
        }
      end

      def build_assertion(params)
        if params[:hmac_secret]
          hmac_secret = params.delete(:hmac_secret)
          JWT.encode(params, hmac_secret, 'HS256')
        elsif params[:private_key]
          private_key = params.delete(:private_key)
          JWT.encode(params, private_key, 'RS256')
        end
      end
    end
  end
end
