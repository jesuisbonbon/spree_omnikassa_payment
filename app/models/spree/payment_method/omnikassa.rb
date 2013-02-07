module Spree
  class PaymentMethod::Omnikassa < PaymentMethod
    preference :merchant_id, :string,  :default => "002020000000001"
    preference :key_version, :integer, :default => 1
    preference :secret_key,  :string,  :default => "002020000000001_KEY1"


    attr_accessible :preferred_key_version
    attr_accessible :preferred_secret_key
    attr_accessible :preferred_merchant_id

    attr_accessible :order, :source, :payment_method, :response_code


    def displayable?(display_on)
      (self.display_on == display_on.to_s || self.display_on.blank?)
    end

    def actions
      %w{capture}
    end

    def can_capture?(payment)
      ['checkout', 'pending'].include?(payment.state)
    end

    def capture(payment)
      #payments with state "checkout" must be moved into state "pending" first:
      raise "capture"
      payment.update_attribute(:state, "pending") if payment.state == "checkout"
      payment.complete
      true
    end

    def source_required?
      false
    end

    def url
      if self.environment == "production"
        #"https://payment-webinit.simu.omnikassa.rabobank.nl/paymentServlet"
        "https://payment-webinit.omnikassa.rabobank.nl/paymentServlet"
      else
        "https://payment-webinit.simu.omnikassa.rabobank.nl/paymentServlet"
      end
    end

    def self.fetch_payment_method
      name = "Omnikassa"
      Spree::PaymentMethod.find(:first, :conditions => [ "lower(name) = ?", name.downcase ]) || raise(ActiveRecord::RecordNotFound)
    end
  end
end
