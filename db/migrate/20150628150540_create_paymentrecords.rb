class CreatePaymentrecords < ActiveRecord::Migration
  def up
  		create_table :paymentrecords do |t|

  			t.column :hashed_userid	, :string
	    	
	      	t.column :amount		, :integer
	    	t.column :input_address , :string 
	    	t.column :input_transaction_hash , :string 
	    	t.column :transaction_hash , :string
	    		
  			# Date in epoch format
  			t.column :created 		, :integer
	      	t.column :received 		, :integer

	      	# Other params
	      	t.column :params  		, :text
  			
  		end
  end

  def down
  	drop_table :paymentrecords
  end
end
