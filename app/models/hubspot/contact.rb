module Hubspot

  # Finds and updates contacts
  #
  # Finds:
  # Hubspot::Contact.find :all, :params => { :search => 'test' }
  # Hubspot::Contact.find <GUID>
  #
  # Updates:
  # contact.firstName = 'Reinier'; contact.save!
  # contact.update_attributes(:firstName => 'Reinier')
  class Contact < Hubspot::Base
    self.site = 'https://api.hubapi.com/contacts/v1'

    schema do
      string 'guid', 'email', 'firstname', 'lastname', 'website', 'company'
      string 'phone', 'address', 'state', 'city', 'zip'
    end

    alias_attribute :id, :guid

    # Override the create, as it differs totally from the other calls.
    class << self
      def create attributes
        create!(attributes) rescue false
      end

      def create! attributes
        return Hubspot::Contact.connection.post(
          "http://#{ Hubspot.config.hubspot_site }/?app=leaddirector&FormName=#{attributes.delete(:FormName)}",
          attributes.to_query, { 'Content-Type' => 'application/x-www-form-urlencoded', 'skip_default_parameters' => '1' }
        )
      end
    end

  end

end
