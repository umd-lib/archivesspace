require 'spec_helper'
require 'stringio'
require 'oai_helper'

require_relative 'export_spec_helper'
require_relative 'oai_response_checker'

describe 'OAI handler' do
  FIXTURES_DIR = OAIHelper::FIXTURES_DIR

  before(:all) do
    @oai_repo_id, @test_record_count, @test_resource_record, @test_archival_object_record = OAIHelper.load_oai_data
  end

  around(:each) do |example|
    JSONModel.with_repository(@oai_repo_id) do
      RequestContext.open(:repo_id => @oai_repo_id) do
        example.run
      end
    end
  end

  before(:each) do
    # EAD export normally tries the search index first, but for the tests we'll
    # skip that since Solr isn't running.
    allow(Search).to receive(:records_for_uris) do |*|
      {'results' => []}
    end
  end

  def format_xml(s)
    Nokogiri::XML(s).to_xml(:indent => 2, :save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
  end

  XML_HEADER = "<!-- THIS FILE IS AUTOMATICALLY GENERATED - DO NOT EDIT.  To update it, just delete it and it will be regenerated from your test data. -->"

  def check_oai_request_against_fixture(fixture_name, params)
    fixture_file = File.join(FIXTURES_DIR, 'responses', fixture_name) + ".xml"

    result = ArchivesSpaceOaiProvider.new.process_request(params)

    # Setting the OAI_SPEC_RECORD will override our stored fixtures with
    # whatever we get back from the OAI.  Be sure to manually check the changes
    # to ensure that responses are what you were expecting.
    if !File.exist?(fixture_file)
      $stderr.puts("NOTE: Updating fixture #{fixture_file}")
      File.write(fixture_file, XML_HEADER + "\n" + format_xml(result))
    else
      OAIResponseChecker.compare(File.read(fixture_file), result)
    end
  end


  ###
  ### Tests start here
  ###

  describe "OAI protocol and mapping support" do

    RESOURCE_BASED_FORMATS = ['oai_ead']
    RESOURCE_AND_COMPONENT_BASED_FORMATS = ['oai_dc', 'oai_dcterms', 'oai_mods', 'oai_marc']

    it "responds to an OAI Identify request" do
      expect {
        check_oai_request_against_fixture('identify', :verb => 'Identify')
      }.not_to raise_error
    end

    it "responds to an OAI ListMetadataFormats request" do
      expect {
        check_oai_request_against_fixture('list_metadata_formats', :verb => 'ListMetadataFormats')
      }.not_to raise_error
    end

    it "responds to an OAI ListSets request" do
      expect {
        check_oai_request_against_fixture('list_sets', :verb => 'ListSets')
      }.not_to raise_error
    end


    RESOURCE_BASED_FORMATS.each do |prefix|
      it "responds to a GetRecord request for type #{prefix}, mapping appropriately" do
        expect {
          check_oai_request_against_fixture("getrecord_#{prefix}",
                                            :verb => 'GetRecord',
                                            :identifier => 'oai:archivesspace/' + @test_resource_record,
                                            :metadataPrefix => prefix)
        }.not_to raise_error
      end
    end

    # TODO: Fix this test and fixtures
    # RESOURCE_AND_COMPONENT_BASED_FORMATS.each do |prefix|
    #   it "responds to a GetRecord request for type #{prefix}, mapping appropriately" do
    #     expect {
    #       check_oai_request_against_fixture("getrecord_#{prefix}",
    #                                         :verb => 'GetRecord',
    #                                         :identifier => 'oai:archivesspace/' + @test_archival_object_record,
    #                                         :metadataPrefix => prefix)
    #
    #       check_oai_request_against_fixture("getrecord_resource_#{prefix}",
    #                                         :verb => 'GetRecord',
    #                                         :identifier => 'oai:archivesspace/' + @test_resource_record,
    #                                         :metadataPrefix => prefix)
    #     }.not_to raise_error
    #   end
    # end
  end

  describe "ListIdentifiers" do

    def list_identifiers(prefix)
      params = {
        :verb => 'ListIdentifiers',
        :metadataPrefix => prefix,
      }

      result = ArchivesSpaceOaiProvider.new.process_request(params)

      doc = Nokogiri::XML(result)
      doc.remove_namespaces!

      doc.xpath("//identifier").map {|elt| elt.text}
    end

    RESOURCE_BASED_FORMATS.each do |prefix|
      it "responds to a ListIdentifiers request for type #{prefix}" do
        list_identifiers(prefix).all? {|identifier| identifier =~ %r{/resources/}}
      end
    end

    RESOURCE_AND_COMPONENT_BASED_FORMATS.each do |prefix|
      it "responds to a ListIdentifiers request for type #{prefix}" do
        list_identifiers(prefix).all? {|identifier| identifier =~ %r{/archival_objects|resources/}}
      end
    end

    it "does not include an identifier in ListIdentifiers for an entity if that entity has an unpublished ancestor" do
      first_ao = ArchivalObject.first
      first_ao_root = Resource[first_ao.root_record_id]

      expect(list_identifiers("oai_dc").include?("oai:archivesspace//repositories/#{first_ao.repo_id}/archival_objects/#{first_ao.id}")).to eq(true)

      first_ao_root.update(:publish => 0)

      expect(list_identifiers("oai_dc").include?("oai:archivesspace//repositories/#{first_ao.repo_id}/archival_objects/#{first_ao.id}")).to eq(false)
    end
  end

  describe "ListRecords" do

    let (:page_size) { 2 }

    let (:oai_repo) {
      oai_repo = ArchivesSpaceOAIRepository.new

      # Drop our page size to ensure we get a resumption token
      smaller_pages = ArchivesSpaceOAIRepository::FormatOptions.new([ArchivalObject], page_size)

      allow(oai_repo).to receive(:options_for_type)
                           .with('oai_dc')
                           .and_return(smaller_pages)

      oai_repo
    }

    it "supports an unqualified ListRecords request" do
      response = oai_repo.find(:all, {:metadata_prefix => "oai_dc"})
      expect(response.records.length).to eq(page_size)
    end

    it "does not list a record in ListRecords if it has an unpublished ancestor" do
      first_ao = ArchivalObject.first
      first_ao_root = Resource[first_ao.root_record_id]

      response = oai_repo.find(:all, {:metadata_prefix => "oai_dc"})
      response_uris = response.records.map { |r| r.jsonmodel_record["uri"] }

      expect(response_uris.include?("/repositories/#{first_ao.repo_id}/archival_objects/#{first_ao.id}")).to eq(true)

      first_ao_root.update(:publish => 0)

      response_2 = oai_repo.find(:all, {:metadata_prefix => "oai_dc"})
      response_2_uris = response_2.records.map { |r| r.jsonmodel_record["uri"] }

      expect(response_2_uris.include?("/repositories/#{first_ao.repo_id}/archival_objects/#{first_ao.id}")).to eq(false)
    end

    it "supports resumption tokens" do
      page1_response = oai_repo.find(:all, {:metadata_prefix => "oai_dc"})
      page1_uris = page1_response.records.map(&:jsonmodel_record).map(&:uri)

      expect(page1_response.token).not_to be_nil

      page2_response = oai_repo.find(:all, {:resumption_token => page1_response.token.serialize})
      page2_uris = page2_response.records.map(&:jsonmodel_record).map(&:uri)

      # We got some different URIs on the next page
      expect((page2_uris + page1_uris).length).to eq(page1_uris.length + page2_uris.length)
    end

    it "supports date ranges when listing records" do
      start_time = Time.parse('1975-01-01 00:00:00 UTC')
      end_time = Time.parse('1976-01-01 00:00:00 UTC')

      margin = 86400
      record_count = 2

      # Backdate some of our AOs to fall within our timeframe of interest.
      #
      # Note that we do a simple UPDATE here to avoid having our Sequel model
      # save hook from updating the system_mtime to Time.now.
      #
      ao_ids = ArchivalObject.filter(:repo_id => @oai_repo_id).order(:id).all.take(record_count).map(&:id)
      ArchivalObject.filter(:id => ao_ids).update(:system_mtime => (start_time + margin))

      response = oai_repo.find(:all, {:metadata_prefix => "oai_dc",
                                      :from => start_time,
                                      :until => end_time})

      expect(response.records.length).to eq(record_count)
    end

    it "lists deletes" do
      token = nil
      loop do
        opts = {:metadata_prefix => "oai_dc"}

        if token
          opts[:resumption_token] = token
        end

        response = oai_repo.find(:all, opts)

        if response.is_a?(Array)
          # Our final page of results--which should be entirely deletes
          expect(response.all?(&:deleted?)).to be_truthy

          break
        elsif response.token
          # Next page!
          token = response.token.serialize
        else
          # Shouldn't have happened...
          fail "no deletes found"
          break
        end
      end
    end

    it "supports OAI sets based on levels" do
      response = oai_repo.find(:all, {:metadata_prefix => "oai_dc", :set => 'fonds'})
      expect(response.records.length).to be > 0

      expect(response.records.map(&:jsonmodel_record).map(&:level).uniq).to eq(['fonds'])
    end


    it "supports OAI sets based on sponsors" do
      allow(AppConfig).to receive(:has_key?).with(any_args).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:oai_sets).and_return(true)

      allow(AppConfig).to receive(:[]).with(any_args).and_call_original
      allow(AppConfig).to receive(:[]).with(:oai_sets)
                            .and_return('sponsor_0' => {
                                          :sponsors => ['sponsor_0']
                                        })

      response = oai_repo.find(:all, {:metadata_prefix => "oai_dc", :set => 'sponsor_0'})

      expect(response.records.all? {|record| record.jsonmodel_record.resource['ref'] == @test_resource_record})
        .to be_truthy
    end

    it "supports OAI sets based on repositories" do
      allow(AppConfig).to receive(:has_key?).with(any_args).and_call_original
      allow(AppConfig).to receive(:has_key?).with(:oai_sets).and_return(true)

      allow(AppConfig).to receive(:[]).with(any_args).and_call_original
      allow(AppConfig).to receive(:[]).with(:oai_sets)
                            .and_return('by_repo' => {
                                          :repo_codes => ['oai_test']
                                        })

      response = oai_repo.find(:all, {:metadata_prefix => "oai_dc", :set => 'by_repo'})
      expect(response.records.all? {|record| record.sequel_record.repo_id == @oai_repo_id})
        .to be_truthy
    end

    describe "OAI sets for resource records" do

      let (:oai_repo) {
        oai_repo = ArchivesSpaceOAIRepository.new

        allow(oai_repo).to receive(:options_for_type)
                             .with('oai_dc')
                             .and_return(ArchivesSpaceOAIRepository::FormatOptions.new([Resource], 5))

        oai_repo
      }

      it "supports OAI sets based on sponsors for resource records too" do
        allow(AppConfig).to receive(:has_key?).with(any_args).and_call_original
        allow(AppConfig).to receive(:has_key?).with(:oai_sets).and_return(true)

        allow(AppConfig).to receive(:[]).with(any_args).and_call_original
        allow(AppConfig).to receive(:[]).with(:oai_sets)
                              .and_return('sponsor_0' => {
                                            :sponsors => ['sponsor_0']
                                          })

        response = oai_repo.find(:all, {:metadata_prefix => "oai_dc", :set => 'sponsor_0'})

        # Just matched the single collection
        expect(response.records.length).to eq(1)

        resource = response.records.first
        expect(resource.jsonmodel_record['finding_aid_sponsor']).to eq('sponsor_0')
      end

      it "supports OAI sets based on repositories for resource records too" do
        allow(AppConfig).to receive(:has_key?).with(any_args).and_call_original
        allow(AppConfig).to receive(:has_key?).with(:oai_sets).and_return(true)

        allow(AppConfig).to receive(:[]).with(any_args).and_call_original
        allow(AppConfig).to receive(:[]).with(:oai_sets)
                              .and_return('by_repo' => {
                                            :repo_codes => ['oai_test']
                                          })

        response = oai_repo.find(:all, {:metadata_prefix => "oai_dc", :set => 'by_repo'})
        expect(response.records.count).to eq(5)
      end

    end

    it "doesn't reveal published or suppressed records" do
      unpublished = create(:json_archival_object, :publish => false, :resource => {:ref => @test_resource_record})
      suppressed = create(:json_archival_object, :publish => true, :resource => {:ref => @test_resource_record})
      ArchivalObject[suppressed.id].set_suppressed(true)

      token = nil
      loop do
        opts = {:metadata_prefix => "oai_dc"}

        if token
          opts[:resumption_token] = token
        end

        response = oai_repo.find(:all, opts)

        records = []

        if response.respond_to?(:token)
          # A partial response
          token = response.token.serialize
          records = response.records
        elsif response.is_a?(Array)
          records = response
          token = nil
        else
          # Shouldn't have happened...
          fail "unexpected result"
          break
        end

        prohibited_uris = [unpublished.uri, suppressed.uri]

        records.each do |record|
          if record.is_a?(ArchivesSpaceOAIRecord) && prohibited_uris.include?(record.jsonmodel_record.uri)
            fail "URI #{record.jsonmodel_record.uri} is unpublished/suppressed and should not be shown in OAI results"
          end
        end

        break if token.nil?
      end
    end
  end

  describe 'OAI mappers output' do
    describe 'DC output' do
      it "should map Conditions Governing Access and Conditions Governing Use to <dc:rights>" do

        uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{@test_resource_record}&metadataPrefix=oai_dc"

        response = get uri
        expect(response.body).to match(/<dc:rights>conditions governing access note<\/dc:rights>/)
        expect(response.body).to match(/<dc:rights>conditions governing use note<\/dc:rights>/)

        expect(response.body).not_to match(/<dc:relation>conditions governing access note<\/dc:relation>/)
        expect(response.body).not_to match(/<dc:relation>conditions governing use note<\/dc:relation>/)
      end

      it "should map Extents to dc:format, not dc:extent" do
        uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{@test_resource_record}&metadataPrefix=oai_dc"

        response = get uri

        expect(response.body).to match(/<dc:format>10 Volumes; Container summary<\/dc:format>/)
        expect(response.body).to match(/<dc:format>physical description note<\/dc:format>/)
        expect(response.body).to match(/<dc:format>dimensions note<\/dc:format>/)

        expect(response.body).not_to match(/<dc:extent>10 Volumes; Container summary<\/dc:extent>/)
        expect(response.body).not_to match(/<dc:extent>physical description note<\/dc:extent>/)
        expect(response.body).not_to match(/<dc:extent>dimensions note<\/dc:extent>/)
      end
    end
  end

  describe 'publish flags' do
    it "should respect publish flags for dc exports" do
      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{@test_resource_record}&metadataPrefix=oai_dc"
      response = get uri
      expect(response.body).not_to match(/note with unpublished parent node/)
    end

    it "should respect publish flags for ead exports" do
      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{@test_resource_record}&metadataPrefix=oai_ead"
      response = get uri
      expect(response.body).not_to match(/note with unpublished parent node/)
    end

    it "should respect publish flags for marc exports" do
      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{@test_resource_record}&metadataPrefix=oai_marc"
      response = get uri
      expect(response.body).not_to match(/note with unpublished parent node/)
    end

    it "should respect publish flags for mods exports" do
      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{@test_resource_record}&metadataPrefix=oai_mods"
      response = get uri
      expect(response.body).not_to match(/note with unpublished parent node/)
    end

    it "does not publish objects via GetRecord with if it has a unpublished ancestor" do
      first_ao = ArchivalObject.first
      first_ao_root = Resource[first_ao.root_record_id]

      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{first_ao.uri}&metadataPrefix=oai_dc"

      response = get uri
      expect(response.body).to_not match(/<error code="idDoesNotExist">/)

      first_ao_root.update(:publish => 0)

      response2 = get uri
      expect(response2.body).to match(/<error code="idDoesNotExist">/)
    end
  end

  describe "respository with OAI harvesting disabled" do
    before(:all) do
      @repo_disabled = create(:json_repo, :oai_is_disabled => true)

      $another_repo_id = $repo_id
      $repo_id = @repo_disabled.id

      JSONModel.set_repository($repo_id)

      @resource = create(:json_resource,
                          :level => 'collection')
    end

    after(:all) do
      @resource.delete
      $repo_id = $another_repo_id

      JSONModel.set_repository($repo_id)
    end

    it "does not publish resources in a repository with OAI disabled" do
      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace/#{@resource['uri']}&metadataPrefix=oai_marc"

      response = get uri
      expect(response.body).to match(/<error code="idDoesNotExist">/)
    end
  end

  describe "repository with sets disabled" do
    before(:all) do
      # 891 is the enum_value_id for 'fonds'
      # add a set restriction for only 'fonds' objects
      Repository.where(:id => 3).update(:oai_sets_available => ([891]).to_json)
    end

    after(:all) do
      # change things back: remove all set restrictions
      Repository.where(:id => 3).update(:oai_sets_available => "[]")
    end

    it "does not return an object if set excluded from OAI in repo" do
      uri = "/oai?verb=ListRecords&set=collection&metadataPrefix=oai_dc"
      response = get uri
      doc = Nokogiri::XML(response.body)

      # should not have any non-tombstone results in xml
      expect(doc.xpath("//xmlns:header[not(@status='deleted')]").length).to eq(0)
    end

    it "returns an object if set included in OAI in repo" do
        # query explicitly for only fonds objects
        uri = "/oai?verb=ListRecords&set=fonds&metadataPrefix=oai_dc"
        response = get uri
        doc = Nokogiri::XML(response.body)

        # should have at least 1 result in XML
        expect(doc.xpath("//xmlns:header[not(@status='deleted')]").length > 0).to be true
    end
  end
end
