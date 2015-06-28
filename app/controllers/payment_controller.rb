class PaymentController < ApplicationController

	require 'rubygems'
	require 'open-uri'
	require 'digest/sha2'
	require 'json'
	require 'openssl'
	require 'uri'
	require 'time'

	ENV["SSL_CERT_FILE"] = "#{ Rails.root }/config/cacert.pem"


	#------------
	def index
		render :text => ""
	end

	#--------------------
	# Called by client side
	def new

		payment_config 		= YAML.load_file("#{ Rails.root }/config/payment.yml")[Rails.env]
		receiving_address 	= payment_config["recipient"]
		secret				= Digest::SHA256.hexdigest( payment_config["secret"] )
		userid 				= Digest::SHA256.hexdigest( request.remote_ip )
		response 			= {}

		begin

			params = {
				:secret => secret,
				:created => Time.now.to_i,
				:userid  => userid 
			}

			callback_url  		= URI::escape(  "http://#{ payment_config["callbackdomain"] }:#{ payment_config["callbackport"] }/received?#{ params.map { |k,v| "#{k}=#{v}" }.join("&") }"  )
			url 				= "https://blockchain.info/api/receive?method=create&address=#{ receiving_address }&callback=#{ callback_url }"
 			res 				= JSON.parse(open(url).read)
			
			response[:status] = 0 
			response[:statusmsg] = "OK"
			response[:input_address] = res["input_address"] 
			

		rescue Exception => e
				
			response[:status] = -1
			response[:statusmsg] = e.to_s 

		end

		render :text => response.to_json 

	end

	#---------------------
	# Called by blockchain.
	# Params
		#value The value of the payment received in satoshi. Divide by 100000000 to get the value in BTC.
		#input_address The bitcoin address that received the transaction.
		#confirmations The number of confirmations of this transaction.
		#{Custom Parameters} Any parameters included in the callback URL will be passed back to the callback URL in the notification.
		#transaction_hash The transaction hash.
		#input_transaction_hash The original paying in hash before forwarding.
		#destination_address The destination bitcoin address. Check this matches your address.

	def received

		payment_config 		= YAML.load_file("#{ Rails.root }/config/payment.yml")[Rails.env]
		secret				= Digest::SHA256.hexdigest( payment_config["secret"] )

		if secret == params[:secret]

			if params[:value].to_i > 0 

				pr = Paymentrecord.new() 
				pr.amount 		 			= params[:value].to_i
				pr.input_address 			= params[:input_address]
				pr.transaction_hash 		= params[:transaction_hash]
				pr.input_transaction_hash 	= params[:input_transaction_hash]
				pr.received 				= Time.now().to_i
				pr.created 					= params[:created].to_i

				pr.hashed_userid 			= params[:userid]
				
				other_params = {}
				params.keys.each { |key|
					if [ :secret, :value , :input_address , :transaction_hash, :input_transaction_hash , :userid ].index(key.to_sym) == nil
						other_params[key] = params[key]
					end
				}
				pr.params = other_params.to_json
				pr.save()
			end
			render :text => "ok"
		else
			render :text => "Not authorised"
		end
		
	end

end





