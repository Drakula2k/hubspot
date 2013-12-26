require File.expand_path('../../test_helper.rb', __FILE__)

class ContactTest < ActiveSupport::TestCase
  def test_should_return_contact_by_id
    VCR.use_cassette('contact-find-by-id') do
      contact = Hubspot::Contact.find(190843)
      assert_not_nil contact

      assert_equal contact.vid, 190843
      assert_equal contact.canonicalVid, 190843
      assert_equal contact.profileUrl, "https://app.hubspot.com/contacts/62515/lists/public/contact/_AO_T-mMpAAQXzICmmWD7T0hP6btnFglUHed6-2gJVFo61AbQwSWxbyP1sLNHUcMIVWlY7ITFNyEoYG_5_BKblAGHDhUqCCVj4ELIWDkx6iwvwo2SJvpif3pvxttILC5m4TDJccGfEYVb/"
      assert_equal contact.properties.attributes.count, 38
      assert_equal contact.properties.hsAnalyticsFirstUrl.versions.first.sourceType, "ANALYTICS"
      contact.properties.attributes.each { |name, prop| assert_operator prop.versions.count, :>, 0 }

      props = contact.properties_for_conversion(contact.formSubmissions.first.conversionId)
      props.each do |name, prop|
        assert_equal prop.sourceId, contact.formSubmissions.first.conversionId
        assert_equal prop.sourceType, "FORM"
        assert !prop.value.nil?, "value"
      end
    end
  end

  def test_should_return_contact_by_email
    VCR.use_cassette('contact-find') do
      contact = Hubspot::Contact.find_by_email('test2@unbounce.com')
      assert_not_nil contact

      assert_equal contact.vid, 191234
      assert_equal contact.canonicalVid, 191234
      assert_equal contact.profileUrl, "https://app.hubspot.com/contacts/62515/lists/public/contact/_AO_T-mPzb7GGJJBa3c9oSkIlXCgRiUoQSQd5ijP7spO6J6jSDi5my7bNu4LjFHgLeyAPYsD3UvvZAm3eIHG3RweUG7tKs8FGALsagedXTRcbJim4J1Xg9gxU5WY_uaiq0ilu7WXnP7Al/"
      assert_equal contact.properties.attributes.count, 40
      assert_equal contact.properties.hsAnalyticsFirstUrl.versions.first.sourceType, "ANALYTICS"
      contact.properties.attributes.each { |name, prop| assert_operator prop.versions.count, :>, 0 }

      props = contact.properties_for_conversion(contact.formSubmissions.first.conversionId)
      props.each do |name, prop|
        assert_equal prop.sourceId, contact.formSubmissions.first.conversionId
        assert_equal prop.sourceType, "FORM"
        assert !prop.value.nil?, "value"
      end
    end
  end

  def test_should_return_recent_contacts
    VCR.use_cassette('contacts-list') do
      recent = Hubspot::Contact.recent({})

      assert_equal recent["has-more"], true
      assert_equal recent["vid-offset"], 191225
      assert_equal recent["time-offset"], 1384336886530

      contacts = recent["contacts"]
      assert_equal contacts.count, 20

      assert_equal contacts.first.formSubmissions.count, 1, "formSubmissions"
      contacts.each do |contact|
        [:addedAt, :vid, :portalId, :isContact, :profileToken, :profileUrl].each do |sym|
          assert !contact.send(sym).nil?, "root attributes"
        end
        assert_operator contact.properties.attributes.count, :>, 0, "properties"
        assert !contact.identityProfiles.first.email.nil?, "email"
      end
    end
  end
end