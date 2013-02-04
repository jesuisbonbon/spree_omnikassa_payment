module Spree
  class OmnikassaPaymentsController < ApplicationController
    skip_before_filter :verify_authenticity_token


    # def homecoming

    #   @payment_response = payment_response_from_params(params)
    #   @order = @payment_response.order

    #   if not @payment_response.valid?
    #     flash[:error] = "Invalid request"
    #     redirect_to(root_url) and return
    #   end

    #   case @payment_response.response_level
    #   when :success
    #     flash[:info] = "Success!"
    #   when :pending
    #     flash[:info] = "Still pending. You will recieve a message"
    #   when :cancelled
    #     flash[:error] = "Order cancelled"
    #   when :failed
    #     flash[:error] = "Error occurred"
    #   else
    #     flash[:error] = "Unknown Error occurred"
    #   end

    #   session[:order_id] = nil

    #   redirect_to(root_url) and return
    # end

    def reply
       
      @payment_response = payment_response_from_params(params)
      @order = @payment_response.order

      add_payment_if_not_exists
      message   = "OmnikassaPaymentResponse posted: payment: # @payment_response.payment.id}; params: #{params.inspect}"
      msg_error = "Helaas er is iets fout gegaan met het bestellen, probeer het later opnieuw."
      msg_ok    = "Bedankt voor uw bestelling."

      if @payment_response.valid?
        case @payment_response.response_level
        when :success
          Rails.logger.info message
          @payment_response.payment.complete!
          advance_order_status :complete
          flash[:notice] = msg_ok
        when :pending
          Rails.logger.info message
          advance_order_status :payment
          flash[:notice] = msg_ok
        when :cancelled
          Rails.logger.info message
           @payment_response.order.cancel
          flash[:error] = msg_error
        when :failed
          Rails.logger.error message
           @payment_response.order.cancel
          flash[:error] = msg_error
        else
          Rails.logger.error message
          @payment_response.order.cancel
          flash[:error] = msg_error
        end
      else
        Rails.logger.error message
        flash[:error] = msg_error
        @payment_response.payment.pend!
      end

      redirect_to(root_url) and return

    end

    private

    def advance_order_status upto_state
      @order.update_attribute(:state, upto_state.to_s)
      session[:order_id] = nil # Usually checkout_controllers after_complete is called, setting session[:order_id] to nil
      @order.finalize!
    end

    # Adds a payment to order if order has no payments yet. 
    # Allows both homecoming and reply to create a payment, but avoids having two payments.
    def add_payment_if_not_exists
      if @order.payments.empty?
        Spree::Payment.create({
          :order => @order,
          :source => @payment_response.payment_method,
          :payment_method => Spree::PaymentMethod::Omnikassa.fetch_payment_method,
          :amount => @order.total,
          :response_code => @payment_response.attributes[:response_code]}, 
          :without_protection => true).started_processing!
      end
    end

    def payment_response_from_params params
      Spree::OmnikassaPaymentResponse.new(params["Seal"], params["Data"])
    end
  end
end


