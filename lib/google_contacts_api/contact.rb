require "google_contacts_api/client"
require "google_contacts_api/request"
require "google_contacts_api/parser"
require "google_contacts_api/group"

module GoogleContactsApi
  module Contact
    include GoogleContactsApi::Request
    include GoogleContactsApi::Parser
    include GoogleContactsApi::Group

    BASE_URL = "https://www.google.com/m8/feeds/contacts/default/full"
    EMAIL_TYPES = %i(work home other).freeze
    PHONE_TYPES = %i(work home other mobile main home_fax work_fax pager).freeze
    GOOGLE_VOICE_LABEL = "grandcentral"

    def list(options = {})
      result = get(BASE_URL, parameters: { 'alt' => 'json', 'updated-min' => options[:since] || '1901-01-16T00:00:00', 'max-results' => '100000' }.merge(options))

      process_contacts_list(result[:data]['feed']['entry'])
    end
    alias_method :contacts, :list

    def group_contacts(group_id)
      list(group: group_base_url(group_id))
    end

    # <?xml version="1.0" encoding="UTF-8"?>
    # <entry gd:etag="&quot;SHw7fTVSLit7I2A9XRFWGUUMQAc.&quot;" xmlns="http://www.w3.org/2005/Atom" xmlns:batch="http://schemas.google.com/gdata/batch" xmlns:gContact="http://schemas.google.com/contact/2008" xmlns:gd="http://schemas.google.com/g/2005">
    #  <id>http://www.google.com/m8/feeds/contacts/hanakohanakoliu%40gmail.com/base/382bc1288afeabe5</id>
    #  <updated>2016-10-09T04:18:59.205Z</updated>
    #  <app:edited xmlns:app="http://www.w3.org/2007/app">2016-10-09T04:18:59.205Z</app:edited>
    #  <category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
    #  <title>劉 治子</title>
    #  <link rel="http://schemas.google.com/contacts/2008/rel#photo" type="image/*" href="https://www.google.com/m8/feeds/photos/media/hanakohanakoliu%40gmail.com/382bc1288afeabe5"/>
    #  <link rel="self" type="application/atom+xml" href="https://www.google.com/m8/feeds/contacts/hanakohanakoliu%40gmail.com/full/382bc1288afeabe5"/>
    #  <link rel="edit" type="application/atom+xml" href="https://www.google.com/m8/feeds/contacts/hanakohanakoliu%40gmail.com/full/382bc1288afeabe5"/>
    #  <gd:name>
    #   <gd:fullName>劉 治子</gd:fullName>
    #   <gd:givenName yomi="はるこ">治子</gd:givenName>
    #   <gd:familyName yomi="りゅう">劉</gd:familyName>
    #  </gd:name>
    #  <gd:email rel="http://schemas.google.com/g/2005#home" address="taiwanhimawari@gmail.com" primary="true"/>
    #  <gd:email label="携帯" address="studioha3@dreamhint.com"/>
    #  <gd:email rel="http://schemas.google.com/g/2005#work" address="haruko_liu@dreamhint.com"/>
    #  <gd:phoneNumber rel="http://schemas.google.com/g/2005#mobile" primary="true" uri="tel:+81-80-3623-8534">08036238534</gd:phoneNumber>
    #  <gd:phoneNumber rel="http://schemas.google.com/g/2005#home" uri="tel:+81-52-409-5796">0524095796</gd:phoneNumber>
    #  <gd:phoneNumber rel="http://schemas.google.com/g/2005#work" uri="tel:+81-52-400-2529">0524002529</gd:phoneNumber>
    #  <gd:structuredPostalAddress rel="http://schemas.google.com/g/2005#home" primary="true">
    #   <gd:formattedAddress>新清洲6-2-5  部屋番号
    # 清須市, 愛知県 4520943
    # 日本
    #   </gd:formattedAddress>
    #   <gd:street>新清洲6-2-5
    # 部屋番号</gd:street>
    #   <gd:city>清須市</gd:city>
    #   <gd:region>愛知県</gd:region>
    #   <gd:postcode>4520943</gd:postcode>
    #   <gd:country>日本</gd:country>
    #  </gd:structuredPostalAddress>
    #  <gContact:groupMembershipInfo deleted="false" href="http://www.google.com/m8/feeds/groups/hanakohanakoliu%40gmail.com/base/653957a68fe92257"/>
    #  <gContact:groupMembershipInfo deleted="false" href="http://www.google.com/m8/feeds/groups/hanakohanakoliu%40gmail.com/base/6"/>
    # </entry>
    def show(contact_id, options = {})
      result = get("#{BASE_URL}/#{contact_id}", headers: { "GData-Version"=>"3.0", "Content-Type" => "application/atom+xml" }.merge(options))

      result[:body]
    end
    alias_method :contact, :show

    # user.update("1527d54f89944880", {"email" => {other: { address: "lala@gmail.com"}}, {work: {address: "liuchiang2010@gmail.com", primary: true }}})
    # user.update("1527d54f89944880", {"phone" => {other: { number: "123456789"}, mobile: {number: "08036337882", primary: true}}})
    # email_node = doc.xpath("//*[name()='gd:email'][contains(@rel, '#{email_type}')]").first
    # email_node.attributes["address"].value = value[:address]
    # phone_node = doc.xpath("//*[name()='gd:phoneNumber'][contains(@rel, '#{key.sub("phone:", "")}')]").first
    # phone_node.content = value[:number]
    # email_node.attributes["primary"].value = "#{!!value[:primary]}"
    def update(contact_id, options)
      content = show(contact_id)
      doc = Nokogiri::XML(CGI::unescape(content).delete("\n"))
      doc = handle_contact_options(doc, options)
      put("#{BASE_URL}/#{contact_id}", doc.to_xml)
    end
    alias_method :update_contact, :update

    def create(options)
      doc = Nokogiri::XML(contact_xml_template)
      doc = handle_contact_options(doc, options)
      post(BASE_URL, doc.to_xml)
    end
    alias_method :create_contact, :create

    protected

    def process_contacts_list(group_list)
      (group_list || []).map do |contact|
        contact_raw_data = {
          id: parse_id(pure_data(contact["id"])),
          emails: extract_schema(contact['gd$email']),
          phone_numbers: extract_schema(contact['gd$phoneNumber']),
          handles: extract_schema(contact['gd$im']),
          addresses: extract_schema(contact['gd$structuredPostalAddress']),
          name_data: cleanse_gdata(contact['gd$name']),
          nickname: contact['gContact$nickname'] && contact['gContact$nickname']['$t'],
          websites: extract_schema(contact['gContact$website']),
          organizations: extract_schema(contact['gd$organization']),
          events: extract_schema(contact['gContact$event']),
          group_ids: contact["gContact$groupMembershipInfo"] ? contact["gContact$groupMembershipInfo"].map{|g| parse_id(g["href"]) } : [],
          birthday: contact['gContact$birthday'].try(:[], "when")
        }.tap do |basic_data|
          # Extract a few useful bits from the basic data
          basic_data[:full_name] = basic_data[:name_data].try(:[], :full_name)
          primary_email_data = basic_data[:emails].find { |type, email| email[:primary] }
          if primary_email_data
            basic_data[:primary_email] = primary_email_data.last[:address]
          end
        end
        GoogleContact.new(contact_raw_data)
      end
    end

    def contact_xml_template
      <<-EOF
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005">
          <atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
          <title></title>
          <gd:name>
            <gd:givenName></gd:givenName>
            <gd:familyName></gd:familyName>
          </gd:name>
        </atom:entry>
      EOF
    end

    def handle_contact_options(doc, options)
      options.each do |key, value|
        case key.to_sym
        when :name
          # name: { familyName: last_name, givenName: first_name}
          value.each do |name_type, name_value|
            doc.xpath("//*[name()='gd:#{name_type}']").first.content = name_value
          end
          doc.xpath("//*[name()='title']").first.content = "#{value[:givenName]} #{value[:familyName]}"
        when :phonetic_name
          # phonetic_name: { familyName: last_name, givenName: first_name}
          value.each do |name_type, name_value|
            name_node = doc.xpath("//*[name()='gd:#{name_type}']").first
            name_node.attributes["yomi"].value = name_value
          end
        when :email
          # email: { work: { address: address, primary: false }, other: {...}}
          doc.xpath("//*[name()='gd:email']").remove
          value.each do |email_type, email_value|
            attr = if EMAIL_TYPES.include?(email_type)
                     %Q|rel="http://schemas.google.com/g/2005##{email_type}"|
                   else
                     %Q|label="#{email_type}"|
                   end

            doc.children.children.last.add_next_sibling(
              %Q|<gd:email #{attr} address="#{email_value[:address]}" primary="#{!!email_value[:primary]}" />|
            )
          end
        when :phone
          # phone: { work: { number: number, primary: false } }
          doc.xpath("//*[name()='gd:phoneNumber']").remove
          value.each do |phone_type, phone_value|
            attr = if PHONE_TYPES.include?(phone_type)
                     %Q|rel="http://schemas.google.com/g/2005##{phone_type}"|
                   else
                     %Q|label="#{phone_type}"|
                   end

            doc.children.children.last.add_next_sibling(
              %Q|<gd:phoneNumber #{attr} primary="#{!!phone_value[:primary]}">#{phone_value[:number]}</gd:phoneNumber>|
            )
          end
        when :address
          # address: { work: { street: 新清洲6-2-5 部屋番號, city: 清須市, region: 愛知縣, postcode: 4520943, country: 日本}}
          doc.xpath("//*[name()='gd:structuredPostalAddress']").remove
          value.each do |phone_type, phone_value|
            doc.children.children.last.add_next_sibling(
              %Q|<gd:structuredPostalAddress rel="http://schemas.google.com/g/2005##{phone_type}" primary="#{!!phone_value[:primary]}">
                   <gd:street>#{phone_value[:street]}</gd:street>
                   <gd:city>#{phone_value[:city]}</gd:city>
                   <gd:region>#{phone_value[:region]}</gd:region>
                   <gd:postcode>#{phone_value[:postcode]}</gd:postcode>
                   <gd:country>#{phone_value[:country]}</gd:country>
                 </gd:structuredPostalAddress>|
            )
          end
        when :birthday
          doc.xpath("//*[name()='gContact:birthday']").first.attributes["when"].value = value
        when :group_id
          unless doc.to_xml.match(/#{value}/)
            doc.children.children.last.add_next_sibling(
              %Q|<gContact:groupMembershipInfo deleted="false" href="#{group_base_url(value)}" />|
            )
          end
        else
        end
      end
      doc
    end
  end
end

class GoogleContact
  attr_accessor :id, :first_name, :last_name, :email_address, :raw_data

  def initialize(raw_data)
    @raw_data = raw_data
    @first_name = raw_data && raw_data[:name_data] ? raw_data[:name_data][:given_name] : nil
    @last_name = raw_data && raw_data[:name_data] ? raw_data[:name_data][:family_name] : nil
    @id = raw_data[:id]
    @email_address = raw_data[:primary_email]
  end

  def full_name
    "#{@first_name} #{@last_name}"
  end
end
