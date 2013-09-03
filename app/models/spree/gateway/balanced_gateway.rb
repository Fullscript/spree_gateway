module Spree
  class Gateway::BalancedGateway < Gateway
    preference :login, :string
    preference :on_behalf_of_uri, :string

    attr_accessible :preferred_login, :preferred_on_behalf_of_uri

    def authorize(money, creditcard, gateway_options)
      if token = creditcard.gateway_payment_profile_id
        # The Balanced ActiveMerchant gateway supports passing the token directly as the creditcard parameter
        creditcard = token
      end

      provider.authorize(money, creditcard, gateway_options)
    end

    def capture(authorization, creditcard, gateway_options)
      provider.capture((authorization.amount * 100).round, authorization.response_code, gateway_options)
    end

    def create_profile(payment)
      return unless payment.source.gateway_payment_profile_id.nil?

      options = {}
      options[:email] = payment.order.email
      options[:login] = preferred_login
      response = provider.store(payment.source, options)
      if response.is_a?(Hash)
        payment.source.update_attributes!(:gateway_payment_profile_id => response[:card_uri], :gateway_customer_profile_id => response[:account_uri])     
      else
        payment.send(:gateway_error, response.message) unless response.success?
      end
    end

    def options_with_test_preference
      options_without_test_preference.merge(:test => self.preferred_test_mode)
    end
    alias_method_chain :options, :test_preference

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      if token = creditcard.gateway_payment_profile_id
        # The Balanced ActiveMerchant gateway supports passing the token directly as the creditcard parameter
        creditcard = token
      end
      provider.purchase(money, creditcard, gateway_options)
    end

    def provider_class
      ActiveMerchant::Billing::BalancedGateway
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.refund(money, response_code, {})
    end

    def void(response_code, creditcard, gateway_options)
      provider.void(response_code)
    end

  end
end
