require 'factory_girl'

def sample(enum, exclude = [])
  values = if enum.has_key?('enum')
             enum['enum']
           elsif enum.has_key?('dynamic_enum')
             enum_source.values_for(enum['dynamic_enum'])
           else
             raise "Not sure how to sample this: #{enum.inspect}"
           end

  exclude += ['other_unmapped']

  values.reject{|i| exclude.include?(i) }.sample
end


def enum_source
  if defined? BackendEnumSource
    BackendEnumSource
  else
    JSONModel.init_args[:enum_source]
  end
end


def JSONModel(key)
  JSONModel::JSONModel(key)
end


def nil_or_whatever
  [nil, generate(:alphanumstr)].sample
end


def few_or_none(key)
  arr = []
  rand(4).times { arr << build(key) }
  arr
end


FactoryGirl.define do

  to_create{|instance| instance.save}

  sequence(:repo_code) {|n| "ASPACE REPO #{n} -- #{rand(1000000)}"}
  sequence(:username) {|n| "username_#{n}"}

  sequence(:alphanumstr) { (0..4).map{ rand(3)==1?rand(10):(65 + rand(25)).chr }.join }
  sequence(:string) { generate(:alphanumstr) }
  sequence(:generic_title) { |n| "Title: #{n}"}
  sequence(:generic_description) {|n| "Description: #{n}"}
  sequence(:generic_name) {|n| "Name Number #{n}"}
  sequence(:container_type) {|n| sample(JSONModel(:container).schema['properties']['type_1'])}
  sequence(:sort_name) { |n| "SORT #{('a'..'z').to_a[rand(26)]} - #{n}" }
  sequence(:archival_object_language) {|n| sample(JSONModel(:abstract_archival_object).schema['properties']['language']) }

  sequence(:phone_number) { (3..5).to_a[rand(3)].times.map { (3..5).to_a[rand(3)].times.map { rand(9) }.join }.join(' ') }
  sequence(:yyyy_mm_dd) { Time.at(rand * Time.now.to_i).to_s.sub(/\s.*/, '') }
  sequence(:hh_mm) { t = Time.now; "#{t.hour}:#{t.min}" }
  sequence(:number) { rand(100).to_s }
  sequence(:url) {|n| "http://www.example-#{n}.com"}
  sequence(:barcode) { 20.times.map { rand(2)}.join }
  sequence(:indicator) { (2+rand(3)).times.map { (2+rand(3)).times.map {rand(9)}.join }.join('-') }

  sequence(:name_rule) { sample(JSONModel(:abstract_name).schema['properties']['rules']) }
  sequence(:name_source) { sample(JSONModel(:abstract_name).schema['properties']['source']) }
  sequence(:level) { %w(series subseries item)[rand(3)] }
  sequence(:term) { |n| "Term #{n}" }
  sequence(:term_type) { sample(JSONModel(:term).schema['properties']['term_type']) }

  sequence(:agent_role) { sample(JSONModel(:event).schema['properties']['linked_agents']['items']['properties']['role']) }
  sequence(:record_role) { sample(JSONModel(:event).schema['properties']['linked_records']['items']['properties']['role']) }

  sequence(:date_type) { sample(JSONModel(:date).schema['properties']['date_type']) }
  sequence(:date_lable) { sample(JSONModel(:date).schema['properties']['label']) }

  sequence(:multipart_note_type) { sample(JSONModel(:note_multipart).schema['properties']['type'])}
  sequence(:singlepart_note_type) { sample(JSONModel(:note_singlepart).schema['properties']['type'])}
  sequence(:note_index_type) { sample(JSONModel(:note_index).schema['properties']['type'])}
  sequence(:note_index_item_type) { sample(JSONModel(:note_index_item).schema['properties']['type'])}
  sequence(:note_bibliography_type) { sample(JSONModel(:note_bibliography).schema['properties']['type'])}
  sequence(:orderedlist_enumeration) { sample(JSONModel(:note_orderedlist).schema['properties']['enumeration']) }
  sequence(:chronology_item) { {'event_date' => nil_or_whatever, 'events' => (0..rand(3)).map { generate(:alphanumstr) } } }

  sequence(:event_type) { sample(JSONModel(:event).schema['properties']['event_type']) }
  sequence(:extent_type) { sample(JSONModel(:extent).schema['properties']['extent_type']) }
  sequence(:portion) { sample(JSONModel(:extent).schema['properties']['portion']) }
  sequence(:instance_type) { sample(JSONModel(:instance).schema['properties']['instance_type'], ['digital_object']) }

  sequence(:rights_type) { sample(JSONModel(:rights_statement).schema['properties']['rights_type']) }
  sequence(:ip_status) { sample(JSONModel(:rights_statement).schema['properties']['ip_status']) }
  sequence(:jurisdiction) { sample(JSONModel(:rights_statement).schema['properties']['jurisdiction']) }

  sequence(:container_location_status) { sample(JSONModel(:container_location).schema['properties']['status']) }
  sequence(:temporary_location_type) { sample(JSONModel(:location).schema['properties']['temporary']) }

  sequence(:use_statement) { sample(JSONModel(:file_version).schema['properties']['use_statement']) }
  sequence(:checksum_method) { sample(JSONModel(:file_version).schema['properties']['checksum_method']) }
  sequence(:xlink_actuate_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_actuate_attribute']) }
  sequence(:xlink_show_attribute) { sample(JSONModel(:file_version).schema['properties']['xlink_show_attribute']) }
  sequence(:file_format_name) { sample(JSONModel(:file_version).schema['properties']['file_format_name']) }
  sequence(:language) { sample(JSONModel(:resource).schema['properties']['language']) }
  sequence(:archival_record_level) { sample(JSONModel(:resource).schema['properties']['level'], ['otherlevel']) }
  sequence(:finding_aid_description_rules) { sample(JSONModel(:resource).schema['properties']['finding_aid_description_rules']) }

  sequence(:relator) { sample(JSONModel(:abstract_archival_object).schema['properties']['linked_agents']['items']['properties']['relator']) }
  sequence(:subject_source) { sample(JSONModel(:subject).schema['properties']['source']) }

  sequence(:vocab_name) {|n| "Vocabulary #{generate(:generic_title)} #{n}" }
  sequence(:vocab_refid) {|n| "vocab_ref_#{n}"}

  sequence(:downtown_address) { "#{rand(200)} #{%w(E W).sample} #{(4..9).to_a.sample}th Street" }


  # AS Models
  if defined? ASModel
    factory :unselected_repo, class: Repository do
      json_schema_version { 1 }
      repo_code { generate(:repo_code) }
      name { generate(:generic_description) }
      agent_representation_id { 1 }
    end

    factory :repo, class: Repository do
      json_schema_version { 1 }
      repo_code { generate(:repo_code) }
      name { generate(:generic_description) }
      agent_representation_id { 1 }
      org_code { generate(:alphanumstr) }
      image_url { generate(:url) }
      after(:create) do |r|
        $repo_id = r.id
        $repo = JSONModel(:repository).uri_for(r.id)
        JSONModel::set_repository($repo_id)
        RequestContext.put(:repo_id, $repo_id)
      end
    end

    factory :agent_corporate_entity, class: AgentCorporateEntity do
      json_schema_version { 1 }
      after(:create) do |a|
        a.add_name_corporate_entity(:rules => generate(:name_rule),
                                    :primary_name => generate(:generic_name),
                                    :sort_name => generate(:sort_name),
                                    :sort_name_auto_generate => 1,
                                    :json_schema_version => 1)
        a.add_agent_contact(:name => generate(:generic_name),
                            :telephone => generate(:phone_number),
                            :address_1 => [nil, generate(:alphanumstr)].sample,
                            :address_2 => [nil, generate(:alphanumstr)].sample,
                            :address_3 => [nil, generate(:alphanumstr)].sample,
                            :city => [nil, generate(:alphanumstr)].sample,
                            :region => [nil, generate(:alphanumstr)].sample,
                            :country => [nil, generate(:alphanumstr)].sample,
                            :post_code => [nil, generate(:alphanumstr)].sample,
                            :telephone => [nil, generate(:alphanumstr)].sample,
                            :fax => [nil, generate(:alphanumstr)].sample,
                            :email => [nil, generate(:alphanumstr)].sample,
                            :email_signature => [nil, generate(:alphanumstr)].sample,
                            :note => [nil, generate(:alphanumstr)].sample,
                            :json_schema_version => 1)
      end
    end

    factory :user, class: User do
      json_schema_version { 1 }
      # before(:create) { agent = create(:json_agent_person) }

      username { generate(:username) }
      name { generate(:generic_name) }
      agent_record_type :agent_person
      agent_record_id {JSONModel(:agent_person).id_for(create(:json_agent_person).uri)}
      source 'local'
    end

    factory :accession do
      json_schema_version { 1 }
      id_0 { generate(:alphanumstr) }
      id_1 { generate(:alphanumstr) }
      id_2 { generate(:alphanumstr) }
      id_3 { generate(:alphanumstr) }
      title { "Accession " + generate(:generic_title) }
      content_description { generate(:generic_description) }
      condition_description { generate(:generic_description) }
      accession_date { generate(:yyyy_mm_dd) }
    end

    factory :resource do
      json_schema_version { 1 }
      title { generate(:generic_title) }
      id_0 { generate(:alphanumstr) }
      id_1 { generate(:alphanumstr) }
      level { generate(:archival_record_level) }
      language { generate(:language) }
    end

    factory :extent do
      json_schema_version { 1 }
      portion { generate(:portion) }
      number { generate(:number) }
      extent_type { generate(:extent_type) }
      resource_id nil
      archival_object_id nil
    end

    factory :archival_object do
      json_schema_version { 1 }
      title { generate(:generic_title) }
      repo_id nil
      ref_id { generate(:alphanumstr) }
      level { generate(:archival_record_level) }
      root_record_id nil
      parent_id nil
    end
  end
  # JSON Models:

  factory :json_accession, class: JSONModel(:accession) do
    id_0 { generate(:alphanumstr) }
    id_1 { generate(:alphanumstr) }
    id_2 { generate(:alphanumstr) }
    id_3 { generate(:alphanumstr) }
    title { "Accession " + generate(:generic_title) }
    content_description { generate(:generic_description) }
    condition_description { generate(:generic_description) }
    accession_date { generate(:yyyy_mm_dd) }
  end

  factory :json_agent_contact, class: JSONModel(:agent_contact) do
    name { generate(:generic_name) }
    telephone { generate(:phone_number) }
    address_1 { [nil, generate(:alphanumstr)].sample }
    address_2 { [nil, generate(:alphanumstr)].sample }
    address_3 { [nil, generate(:alphanumstr)].sample }
    city { [nil, generate(:alphanumstr)].sample }
    region { [nil, generate(:alphanumstr)].sample }
    country { [nil, generate(:alphanumstr)].sample }
    post_code { [nil, generate(:alphanumstr)].sample }
    telephone_ext { [nil, generate(:alphanumstr)].sample }
    fax { [nil, generate(:alphanumstr)].sample }
    email { [nil, generate(:alphanumstr)].sample }
    email_signature { [nil, generate(:alphanumstr)].sample }
    note { [nil, generate(:alphanumstr)].sample }
  end

  factory :json_agent_corporate_entity, class: JSONModel(:agent_corporate_entity) do
    agent_type 'agent_corporate_entity'
    names { [build(:json_name_corporate_entity)] }
    agent_contacts { [build(:json_agent_contact)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_family, class: JSONModel(:agent_family) do
    agent_type 'agent_family'
    names { [build(:json_name_family)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_person, class: JSONModel(:agent_person) do
    agent_type 'agent_person'
    names { [build(:json_name_person)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_agent_software, class: JSONModel(:agent_software) do
    agent_type 'agent_software'
    names { [build(:json_name_software)] }
    dates_of_existence { [build(:json_date, :label => 'existence')] }
  end

  factory :json_archival_object, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
  end

  factory :json_archival_object_normal, class: JSONModel(:archival_object) do
    ref_id { generate(:alphanumstr) }
    level { generate(:level) }
    title { "Archival Object #{generate(:generic_title)}" }
    extents { few_or_none(:json_extent) }
    dates { few_or_none(:json_date) }
  end

  factory :json_classification, class: JSONModel(:classification) do
    identifier { generate(:alphanumstr) }
    title { "Classification #{generate(:generic_title)}" }
    description { generate(:generic_description) }
  end

  factory :json_classification_term, class: JSONModel(:classification_term) do
    identifier { generate(:alphanumstr) }
    title { "Classification #{generate(:generic_title)}" }
    description { generate(:generic_description) }
  end

  factory :json_note_index, class: JSONModel(:note_index) do
    type { generate(:note_index_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
    items { [ build(:json_note_index_item), build(:json_note_index_item) ] }
  end

  factory :json_note_index_item, class: JSONModel(:note_index_item) do
    value { generate(:alphanumstr) }
    reference { generate(:alphanumstr) }
    reference_text { generate(:alphanumstr) }
    type { generate(:note_index_item_type) }
  end

  factory :json_note_bibliography, class: JSONModel(:note_bibliography) do
    label { generate(:alphanumstr) }
    content { [generate(:alphanumstr)] }
    items { [generate(:alphanumstr)] }
    type { generate(:note_bibliography_type) }
  end

  factory :json_note_bioghist, class: JSONModel(:note_bioghist) do
    label { generate(:alphanumstr) }
    subnotes { [ build(:json_note_outline), build(:json_note_text) ] }
  end

  factory :json_note_outline, class: JSONModel(:note_outline) do
    levels { [ build(:json_note_outline_level) ] }
  end

  factory :json_note_text, class: JSONModel(:note_text) do
    content { generate(:alphanumstr) }
  end

  factory :json_note_orderedlist, class: JSONModel(:note_orderedlist) do
    title { nil_or_whatever }
    enumeration { generate(:orderedlist_enumeration) }
    items { (0..rand(3)).map { generate(:alphanumstr) } }
  end

  factory :json_note_definedlist, class: JSONModel(:note_definedlist) do
    title { nil_or_whatever }
    items { (0..rand(3)).map { {:label => generate(:alphanumstr), :value => generate(:alphanumstr) } } }
  end

  factory :json_note_abstract, class: JSONModel(:note_abstract) do
    content { (0..rand(3)).map { generate(:alphanumstr) } }
  end

  factory :json_note_citation, class: JSONModel(:note_citation) do
    content { (0..rand(3)).map { generate(:alphanumstr) } }
    xlink Hash[%w(actuate arcrole href role show title type).map{|i| [i, i]}]
  end

  factory :json_note_chronology, class: JSONModel(:note_chronology) do
    title { nil_or_whatever }
    items { (0..rand(3)).map { generate(:chronology_item) } }
  end

  factory :json_note_outline_level, class: JSONModel(:note_outline_level) do
    items { [ generate(:alphanumstr) ] }
  end

  factory :json_container, class: JSONModel(:container) do
    type_1 { generate(:container_type) }
    indicator_1 { generate(:indicator) }
    barcode_1 { generate(:barcode) }
    container_extent { generate (:number) }
    container_extent_type { sample(JSONModel(:container).schema['properties']['container_extent_type']) }
  end

  factory :json_date, class: JSONModel(:date) do
    date_type { generate(:date_type) }
    label 'creation'
    self.begin { generate(:yyyy_mm_dd) }
    self.end { self.begin }
    expression { generate(:alphanumstr) }
  end

  factory :json_deaccession, class: JSONModel(:deaccession) do
    scope { "whole" }
    description { generate(:generic_description) }
    date { build(:json_date) }
  end

  factory :json_digital_object, class: JSONModel(:digital_object) do
    title { "Digital Object #{generate(:generic_title)}" }
    language { generate(:archival_object_language) }
    digital_object_id { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    file_versions { few_or_none(:json_file_version) }
    dates { few_or_none(:json_date) }
  end

  factory :json_digital_object_component, class: JSONModel(:digital_object_component) do
    component_id { generate(:alphanumstr) }
    title { "Digital Object Component #{generate(:generic_title)}" }
  end

  factory :json_event, class: JSONModel(:event) do
    date { build(:json_date) }
    event_type { generate(:event_type) }
    linked_agents { [{'ref' => create(:json_agent_person).uri, 'role' => generate(:agent_role)}] }
    linked_records { [{'ref' => create(:json_accession).uri, 'role' => generate(:record_role)}] }
  end

  factory :json_extent, class: JSONModel(:extent) do
    portion { generate(:portion) }
    number { generate(:number) }
    extent_type { generate(:extent_type) }
  end

  factory :json_file_version, class: JSONModel(:file_version) do
    file_uri { generate(:alphanumstr) }
    use_statement { generate(:use_statement) }
    xlink_actuate_attribute { generate(:xlink_actuate_attribute) }
    xlink_show_attribute { generate(:xlink_show_attribute) }
    file_format_name { generate(:file_format_name) }
    file_format_version { generate(:alphanumstr) }
    file_size_bytes { generate(:number).to_i }
    checksum { generate(:alphanumstr) }
    checksum_method { generate(:checksum_method) }
  end

  factory :json_external_document, class: JSONModel(:external_document) do
    title { "External Document #{generate(:generic_title)}" }
    location { generate(:url) }
  end

  factory :json_group, class: JSONModel(:group) do
    group_code { generate(:alphanumstr) }
    description { generate(:generic_description) }
  end

  factory :json_instance, class: JSONModel(:instance) do
    instance_type { generate(:instance_type) }
    container { build(:json_container) }
  end

  factory :json_instance_digital, class: JSONModel(:instance) do
    instance_type 'digital_object'
    digital_object { {'ref' => create(:json_digital_object).uri } }
  end


  factory :json_location, class: JSONModel(:location) do
    building { generate(:downtown_address) }
    floor { "#{rand(13)}" }
    room { "#{rand(20)}" }
    area { %w(Back Front).sample }
    barcode { generate(:barcode) }
    temporary { generate(:temporary_location_type) }
  end

  factory :json_name_corporate_entity, class: JSONModel(:name_corporate_entity) do
    rules { generate(:name_rule) }
    primary_name { generate(:generic_name) }
    subordinate_name_1 { generate(:alphanumstr) }
    subordinate_name_2 { generate(:alphanumstr) }
    number { generate(:alphanumstr) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate true
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
  end

  factory :json_name_family, class: JSONModel(:name_family) do
    rules { generate(:name_rule) }
    family_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate true
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    prefix { generate(:alphanumstr) }
  end

  factory :json_name_person, class: JSONModel(:name_person) do
    rules { generate(:name_rule) }
    source { generate(:name_source) }
    primary_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    name_order { %w(direct inverted).sample }
    number { generate(:alphanumstr) }
    sort_name_auto_generate true
    dates { generate(:alphanumstr) }
    qualifier { generate(:alphanumstr) }
    fuller_form { generate(:alphanumstr) }
    prefix { [nil, generate(:alphanumstr)].sample }
    title { [nil, generate(:alphanumstr)].sample }
    suffix { [nil, generate(:alphanumstr)].sample }
    rest_of_name { [nil, generate(:alphanumstr)].sample }
  end

  factory :json_name_software, class: JSONModel(:name_software) do
    rules { generate(:name_rule) }
    software_name { generate(:generic_name) }
    sort_name { generate(:sort_name) }
    sort_name_auto_generate true
  end

  factory :json_collection_management, class: JSONModel(:collection_management) do
  end

  factory :json_note_singlepart, class: JSONModel(:note_singlepart) do
    type { generate(:singlepart_note_type)}
    content { [ generate(:alphanumstr), generate(:alphanumstr) ] }
  end

  factory :json_note_multipart, class: JSONModel(:note_multipart) do
    type { generate(:multipart_note_type)}
    subnotes { [ build(:json_note_text) ] }
  end

  factory :json_resource, class: JSONModel(:resource) do
    title { "Resource #{generate(:generic_title)}" }
    id_0 { generate(:alphanumstr) }
    extents { [build(:json_extent)] }
    level { generate(:archival_record_level) }
    language { generate(:language) }
    dates { [build(:json_date)] }
    finding_aid_description_rules { [nil, generate(:finding_aid_description_rules)].sample }
    ead_id { nil_or_whatever }
    finding_aid_language { nil_or_whatever }
    finding_aid_revision_date { nil_or_whatever }
    finding_aid_revision_description { nil_or_whatever }
    ead_location { generate(:alphanumstr) }
    instances { [build(:json_instance), build(:json_instance)] }
  end

  factory :json_repo, class: JSONModel(:repository) do
    repo_code { generate(:repo_code) }
    name { generate(:generic_description) }
    org_code { generate(:alphanumstr) }
    image_url { generate(:url) }
  end

  # may need factories for each rights type
  factory :json_rights_statement, class: JSONModel(:rights_statement) do
    rights_type 'intellectual_property'
    ip_status { generate(:ip_status) }
    jurisdiction { generate(:jurisdiction) }
    active true
  end

  factory :json_subject, class: JSONModel(:subject) do
    terms { [build(:json_term)] }
    vocabulary { create(:json_vocab).uri }
    authority_id { generate(:url) }
    scope_note { generate(:alphanumstr) }
    source { generate(:subject_source) }
  end

  factory :json_term, class: JSONModel(:term) do
    term { generate(:term) }
    term_type { generate(:term_type) }
    vocabulary { create(:json_vocab).uri }
  end

  factory :json_user, class: JSONModel(:user) do
    username { generate(:username) }
    name { generate(:generic_name) }
  end

  factory :json_vocab, class: JSONModel(:vocabulary) do
    name { generate(:vocab_name) }
    ref_id { generate(:vocab_refid) }
  end

  factory :json_import_job, class: JSONModel(:job) do
    import_type { ['marcxml', 'ead_xml', 'eac_xml'].sample }
    filenames { (0..3).map { generate(:alphanumstr) } }
  end

  factory :json_preference, class: JSONModel(:preference) do
    defaults { "{}" }
  end

end
