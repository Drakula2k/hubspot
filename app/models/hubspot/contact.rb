module Hubspot

  # Finds and updates contacts
  #
  # NOTE: works, but returns hashes, not actual objects. still working on this
  #
  # Finds:
  # Hubspot::Contact.find :all, :params => { :search => 'test' }
  # Hubspot::Contact.find <GUID>
  #
  # Updates:
  # contact.firstName = 'Reinier'; contact.save!
  # contact.update_attributes(:firstName => 'Reinier')
  class Contact < Hubspot::Base

    self.site = 'https://api.hubapi.com/contacts/v1/contact/'

    schema do
      string 'vid', 'email', 'firstname', 'lastname', 'website', 'company'
      string 'phone', 'address', 'state', 'city', 'zip'
    end

    alias_attribute :id, :vid


    def update_attributes(attributes)
      raise self.to_yaml
      begin
        response = Hubspot::Contact.connection.post(
          "#{ self.class.site }/contact/vid/#{self.id}/profile?hapikey=#{Hubspot.config.hubspot_key}",
          self.parse_attributes(attributes).to_json,
          {
            'Content-Type' => 'application/json',
            'skip_default_parameters' => '1',
          }
        )
        return ActiveSupport::JSON.decode(response.body).merge({
          success: true
        })
      rescue ActiveResource::ResourceNotFound => e
        return {
          success: false,
          message: 'Not found',
          debug: e.message,
          params: {
            email: email
          }
        }
      end
    end


    # override the create, as it differs totally from the other calls.
    class << self
      def parse_attributes attributes
        params = { :properties => [] }
        attributes.each do |key, val|
          params[:properties] << { :property => key, :value => val }
        end
        params
      end

      def refresh_token *args
        return false
        response = Hubspot::Contact.connection.post(
          "https://app.hubspot.com/auth/authenticate/?client_id=#{Hubspot.config.client_id}&portalId=#{Hubspot.config.portal_id}&redirect_uri=#{Hubspot.config.oauth_uri}&scope=contacts-rw+offline"
        )
      end

      def update(vid, attributes)
        update!(vid, attributes) rescue false
      end

      def find_by_email(email)
        find_by_email!(email) rescue false
      end

      def create(attributes)
        create!(attributes) rescue false
      end

      def update!(vid, attributes)
        #begin
          url = "#{ self.site }vid/#{vid}/profile?hapikey=#{Hubspot.config.hubspot_key}"
          response = Hubspot::Contact.connection.post(
            url,
            self.parse_attributes(attributes).to_json,
            {
              'Content-Type' => 'application/json',
              'skip_default_parameters' => '1',
            }
          )
          return response.code == '204'
        #rescue ActiveResource::UnauthorizedAccess
          ## authenticate
          #self.refresh_token
        #end
      end

      def find_by_email!(email)
        #begin
        url = "#{ self.site }email/#{email}/profile?hapikey=#{Hubspot.config.hubspot_key}"
        response = Hubspot::Contact.connection.get(url)
        return ActiveSupport::JSON.decode(response.body)
        #rescue ActiveResource::UnauthorizedAccess
          ## authenticate
          #self.refresh_token
        #end
      end

      def create!(attributes)
        #begin
          response = Hubspot::Contact.connection.post(
            "#{ self.site }?hapikey=#{Hubspot.config.hubspot_key}",
            self.parse_attributes(attributes).to_json,
            {
              'Content-Type' => 'application/json',
              'skip_default_parameters' => '1',
            }
          )
          return ActiveSupport::JSON.decode(response.body)
        #rescue ActiveResource::UnauthorizedAccess
          ## authenticate
          #self.refresh_token
        #end
      end
    end

  end

end
