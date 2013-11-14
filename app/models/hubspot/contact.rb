module Hubspot

  # Finds and updates contacts
  #
  # NOTE: only .properties_for_conversion, #find_by_email and #recent methods are tested
  #
  # Finds:
  # Hubspot::Contact.find :all, :params => { :search => 'test' }
  # Hubspot::Contact.find <GUID>
  #
  # Updates:
  # contact.firstName = 'Reinier'; contact.save!
  # contact.update_attributes(:firstName => 'Reinier')
  class Contact < Hubspot::Base
    class << self
      attr_accessor :site_lists
    end

    self.site = 'https://api.hubapi.com/contacts/v1/contact/'
    self.site_lists = 'https://api.hubapi.com/contacts/v1/lists/'

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

    def properties_for_conversion(id)
      result = {}
      properties.attributes.each do |name, attrs|
        if attrs.respond_to?(:versions)
          attrs.versions.each do |version|
            result[name] = version if version.sourceId == id
          end
        end
      end
      result
    end

    # override the create, as it differs totally from the other calls.
    class << self
      def parse_attributes(attributes)
        params = { :properties => [] }
        attributes.each do |key, val|
          params[:properties] << { :property => key, :value => val }
        end
        params
      end

      # auth token no needed for contacts
      def refresh_token(*args)
        false
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
        url = "#{ self.site }vid/#{vid}/profile?hapikey=#{Hubspot.config.hubspot_key}"
        response = Hubspot::Contact.connection.post(
          url,
          self.parse_attributes(attributes).to_json,
          {
            'Content-Type' => 'application/json',
            'skip_default_parameters' => '1',
          }
        )
        response.code == '204'
      end

      def find_by_email!(email)
        url = "#{ self.site }email/#{email}/profile?hapikey=#{Hubspot.config.hubspot_key}"
        response = Hubspot::Contact.connection.get(url)
        parse_contact_body(response.body)
      end

      def create!(attributes)
        response = Hubspot::Contact.connection.post(
          "#{ self.site }?hapikey=#{Hubspot.config.hubspot_key}",
          self.parse_attributes(attributes).to_json,
          {
            'Content-Type' => 'application/json',
            'skip_default_parameters' => '1',
          }
        )
        parse_contact_body(response.body)
      end

      # Return all contacts that have been recently updated or created
      #
      # params: count, timeOffset, vidOffset
      # http://developers.hubspot.com/docs/methods/contacts/get_recently_updated_contacts
      def recent(params)
        path_params = ""
        params.each do |key, value|
          path_params += "&#{key}=#{value}"
        end

        url = "#{ self.site_lists }recently_updated/contacts/recent?hapikey=#{Hubspot.config.hubspot_key}#{path_params}"
        response = Hubspot::Contact.connection.get(url)
        parse_contacts_body(response.body)
      end

      def parse_contacts_body(body)
        contacts = format.decode(body)["contacts"]
        contacts.map! { |contact| camelize_keys_recursive(contact)}
        instantiate_collection(contacts)
      end

      def parse_contact_body(body)
        contact = format.decode(body)
        instantiate_record(camelize_keys_recursive(contact))
      end

      def camelize_keys_recursive(hash)
        Hash[
          hash.map do |k,v|
            k = k.gsub('-','_').camelize(:lower)
            if v.is_a?(Hash)
              [k, camelize_keys_recursive(v)]
            else
              if v.is_a?(Array)
                v.map! { |val| val.is_a?(Hash) ? camelize_keys_recursive(val) : val }
              end
              [k, v]
            end
          end
        ]
      end

    end

    class Properties < Contact
      def method_missing(m, *args, &block)
        super rescue OpenStruct.new({ :value => nil })
      end
    end

    class IdentityProfile < Contact
      def email
        identities.each do |id|
          return id.value if id.type == "EMAIL"
        end
      end
    end

  end

end
