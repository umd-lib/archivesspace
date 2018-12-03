require 'spec_helper'

describe Searchable do

  before do
    class FakeController < ApplicationController
      include Searchable
    end
  end
  after { Object.send :remove_const, :FakeController }
  let(:object) { FakeController.new }
  let(:default_types) { %w{type_a} }
  let(:default_facet_types) { %w{primary_type subjects published_agents repository} }
  let(:default_search_opts) { { 'sort' => 'title_sort asc', 'resolve[]' => ['repository:id', 'resource:id@compact_resource', 'ancestors:id@compact_resource'], 'facet.mincount' => 1 } }
  let(:default_search_params_limit) { { :q => ['*'], :limit => 'type_a_limit', :op => ['OPERATOR'], :field => ['title'] } }
  let(:default_search_params_no_limit) { { :q => ['*'], :op => ['OPERATOR'], :field => ['title'] } }
  let(:default_search_params_no_q) { { :limit => 'type_a_limit', :op => ['OPERATOR'], :field => ['title'] } }
  let(:results) { { 'total_hits' => 10 } }

  describe 'set_up_advanced_search' do
    describe 'with params' do
      before(:each) do
        object.instance_variable_set(:@base_search, "base_search")
        object.set_up_advanced_search(default_types, default_facet_types, default_search_opts, default_search_params_limit)
      end
      it 'builds base search' do
        expect(object.instance_variable_get(:@base_search)).to eq('base_search&q[]=%2A&op[]=OPERATOR&field[]=title&from_year[]=&to_year[]=&limit=type_a_limit')
      end
      it 'builds criteria' do
        criteria = object.instance_variable_get(:@criteria)
        expect(criteria["sort"]).to eq('title_sort asc')
        expect(criteria["resolve[]"]).to eq(["repository:id", "resource:id@compact_resource", "ancestors:id@compact_resource"])
        expect(criteria["facet.mincount"]).to eq(1)
        expect(criteria["aq"]).to eq("{\"query\":{\"op\":\"AND\",\"subqueries\":[{\"op\":\"AND\",\"subqueries\":[{\"field\":\"title\",\"value\":\"*\",\"negated\":false,\"literal\":false,\"jsonmodel_type\":\"field_query\"}],\"jsonmodel_type\":\"boolean_query\"}],\"jsonmodel_type\":\"boolean_query\"},\"jsonmodel_type\":\"advanced_query\"}")
        expect(criteria["filter"]).to eq("{\"query\":{\"op\":\"AND\",\"subqueries\":[{\"op\":\"OR\",\"subqueries\":[{\"field\":\"types\",\"value\":\"type_a_limit\",\"negated\":false,\"literal\":false,\"jsonmodel_type\":\"field_query\"}],\"jsonmodel_type\":\"boolean_query\"}],\"jsonmodel_type\":\"boolean_query\"},\"jsonmodel_type\":\"advanced_query\"}")
        expect(criteria["facet[]"]).to eq(["primary_type", "subjects", "published_agents", "repository"])
        expect(criteria["page_size"]).to eq(10)
      end
      it 'builds search' do
        search = object.instance_variable_get(:@search)
        expect(search).to have_attributes(:q => ["*"])
        expect(search).to have_attributes(:op => ["OPERATOR"])
        expect(search).to have_attributes(:field => ["title"])
        expect(search).to have_attributes(:limit => "type_a_limit")
        expect(search).to have_attributes(:from_year => [])
        expect(search).to have_attributes(:to_year => [])
        expect(search).to have_attributes(:filter_fields => [])
        expect(search).to have_attributes(:filter_values => [])
        expect(search).to have_attributes(:filter_q => [])
        expect(search).to have_attributes(:filter_from_year => "")
        expect(search).to have_attributes(:filter_to_year => "")
        expect(search).to have_attributes(:recordtypes => [])
        expect(search).to have_attributes(:dates_searched => false)
        expect(search).to have_attributes(:sort => nil)
        expect(search).to have_attributes(:dates_within => false)
        expect(search).to have_attributes(:text_within => false)
        expect(search).to have_attributes(:search_statement => "Search  <strong> translation missing: en.search-limits.type_a_limit</strong> where <ul class='no-bullets'> <li> the <strong>title</strong> contains  <span class='searchterm'>*</span></li></ul>")
      end
      it 'builds sort' do
        criteria = object.instance_variable_get(:@criteria)
        expect(criteria["sort"]).to eq(object.instance_variable_get(:@sort))
      end
      it 'builds facet_filter' do
        facet_filter = object.instance_variable_get(:@facet_filter)
        expect(facet_filter).to have_attributes(:default_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:fields => [])
        expect(facet_filter).to have_attributes(:values => [])
        expect(facet_filter).to have_attributes(:facet_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:facet_set_arr => [])
      end
    end
    describe 'with params no limit' do
      before(:each) do
        object.instance_variable_set(:@base_search, "base_search")
        object.set_up_advanced_search(default_types, default_facet_types, default_search_opts, default_search_params_no_limit)
      end
      it 'builds base search' do
        expect(object.instance_variable_get(:@base_search)).to eq('base_search&q[]=%2A&op[]=OPERATOR&field[]=title&from_year[]=&to_year[]=')
      end
      it 'builds criteria' do
        criteria = object.instance_variable_get(:@criteria)
        expect(criteria["sort"]).to eq('title_sort asc')
        expect(criteria["resolve[]"]).to eq(["repository:id", "resource:id@compact_resource", "ancestors:id@compact_resource"])
        expect(criteria["facet.mincount"]).to eq(1)
        expect(criteria["aq"]).to eq("{\"query\":{\"op\":\"AND\",\"subqueries\":[{\"op\":\"AND\",\"subqueries\":[{\"field\":\"title\",\"value\":\"*\",\"negated\":false,\"literal\":false,\"jsonmodel_type\":\"field_query\"}],\"jsonmodel_type\":\"boolean_query\"}],\"jsonmodel_type\":\"boolean_query\"},\"jsonmodel_type\":\"advanced_query\"}")
        expect(criteria["filter"]).to eq("{\"query\":{\"op\":\"AND\",\"subqueries\":[{\"op\":\"OR\",\"subqueries\":[{\"field\":\"types\",\"value\":\"type_a\",\"negated\":false,\"literal\":false,\"jsonmodel_type\":\"field_query\"}],\"jsonmodel_type\":\"boolean_query\"}],\"jsonmodel_type\":\"boolean_query\"},\"jsonmodel_type\":\"advanced_query\"}")
        expect(criteria["facet[]"]).to eq(["primary_type", "subjects", "published_agents", "repository"])
        expect(criteria["page_size"]).to eq(10)
      end
      it 'builds search' do
        search = object.instance_variable_get(:@search)
        expect(search).to have_attributes(:q => ["*"])
        expect(search).to have_attributes(:op => ["OPERATOR"])
        expect(search).to have_attributes(:field => ["title"])
        expect(search).to have_attributes(:from_year => [])
        expect(search).to have_attributes(:to_year => [])
        expect(search).to have_attributes(:filter_fields => [])
        expect(search).to have_attributes(:filter_values => [])
        expect(search).to have_attributes(:filter_q => [])
        expect(search).to have_attributes(:filter_from_year => "")
        expect(search).to have_attributes(:filter_to_year => "")
        expect(search).to have_attributes(:recordtypes => [])
        expect(search).to have_attributes(:dates_searched => false)
        expect(search).to have_attributes(:sort => nil)
        expect(search).to have_attributes(:dates_within => false)
        expect(search).to have_attributes(:text_within => false)
        expect(search).to have_attributes(:search_statement => "Search  <strong> all record types</strong> where <ul class='no-bullets'> <li> the <strong>title</strong> contains  <span class='searchterm'>*</span></li></ul>")
      end
      it 'builds sort' do
        criteria = object.instance_variable_get(:@criteria)
        expect(criteria["sort"]).to eq(object.instance_variable_get(:@sort))
      end
      it 'builds facet_filter' do
        facet_filter = object.instance_variable_get(:@facet_filter)
        expect(facet_filter).to have_attributes(:default_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:fields => [])
        expect(facet_filter).to have_attributes(:values => [])
        expect(facet_filter).to have_attributes(:facet_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:facet_set_arr => [])
      end
    end
  end

  describe 'set_up_search' do
    describe 'with params' do
      before(:each) do
        object.set_up_search(default_types, default_facet_types, default_search_opts, default_search_params_limit,'')
      end
      it 'builds search' do
        search = object.instance_variable_get(:@search)
        expect(search).to have_attributes(:q => ["*"])
        expect(search).to have_attributes(:op => ["OPERATOR"])
        expect(search).to have_attributes(:field => ["title"])
        expect(search).to have_attributes(:limit => "type_a_limit")
        expect(search).to have_attributes(:from_year => [])
        expect(search).to have_attributes(:to_year => [])
        expect(search).to have_attributes(:filter_fields => [])
        expect(search).to have_attributes(:filter_values => [])
        expect(search).to have_attributes(:filter_q => [])
        expect(search).to have_attributes(:filter_from_year => "")
        expect(search).to have_attributes(:filter_to_year => "")
        expect(search).to have_attributes(:recordtypes => [])
        expect(search).to have_attributes(:dates_searched => false)
        expect(search).to have_attributes(:sort => nil)
        expect(search).to have_attributes(:dates_within => false)
        expect(search).to have_attributes(:text_within => false)
        expect(search).to have_attributes(:search_statement => nil)
      end
      it 'builds query' do
        query = object.instance_variable_get(:@query)
        expect(query).to eq("[\"title\"]:*")
      end
      it 'builds base search' do
        expect(object.instance_variable_get(:@base_search)).to eq("q=[\"title\"]:*&limit=type_a_limit")
      end
      it 'builds criteria' do
        criteria = object.instance_variable_get(:@criteria)
        expect(criteria["sort"]).to eq('title_sort asc')
        expect(criteria["resolve[]"]).to eq(["repository:id", "resource:id@compact_resource", "ancestors:id@compact_resource"])
        expect(criteria["facet.mincount"]).to eq(1)
        expect(criteria["types"]).to eq(nil)
        expect(criteria["aq"]).to eq(nil)
        expect(criteria["filter"]).to eq("{\"query\":{\"op\":\"AND\",\"subqueries\":[{\"op\":\"OR\",\"subqueries\":[{\"field\":\"types\",\"value\":\"type_a_limit\",\"negated\":false,\"literal\":false,\"jsonmodel_type\":\"field_query\"}],\"jsonmodel_type\":\"boolean_query\"}],\"jsonmodel_type\":\"boolean_query\"},\"jsonmodel_type\":\"advanced_query\"}")
        expect(criteria["facet[]"]).to eq(["primary_type", "subjects", "published_agents", "repository"])
        expect(criteria["page_size"]).to eq(10)
      end
      it 'builds facet_filter' do
        facet_filter = object.instance_variable_get(:@facet_filter)
        expect(facet_filter).to have_attributes(:default_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:fields => [])
        expect(facet_filter).to have_attributes(:values => [])
        expect(facet_filter).to have_attributes(:facet_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:facet_set_arr => [])
      end
    end
    describe 'with params no limit' do
      before(:each) do
        object.set_up_search(default_types, default_facet_types, default_search_opts, default_search_params_no_limit,'')
      end
      it 'builds search' do
        search = object.instance_variable_get(:@search)
        expect(search).to have_attributes(:q => ["*"])
        expect(search).to have_attributes(:op => ["OPERATOR"])
        expect(search).to have_attributes(:field => ["title"])
        expect(search).to have_attributes(:from_year => [])
        expect(search).to have_attributes(:to_year => [])
        expect(search).to have_attributes(:filter_fields => [])
        expect(search).to have_attributes(:filter_values => [])
        expect(search).to have_attributes(:filter_q => [])
        expect(search).to have_attributes(:filter_from_year => "")
        expect(search).to have_attributes(:filter_to_year => "")
        expect(search).to have_attributes(:recordtypes => [])
        expect(search).to have_attributes(:dates_searched => false)
        expect(search).to have_attributes(:sort => nil)
        expect(search).to have_attributes(:dates_within => false)
        expect(search).to have_attributes(:text_within => false)
        expect(search).to have_attributes(:search_statement => nil)
      end
      it 'builds query' do
        query = object.instance_variable_get(:@query)
        expect(query).to eq("[\"title\"]:*")
      end
      it 'builds base search' do
        expect(object.instance_variable_get(:@base_search)).to eq("q=[\"title\"]:*")
      end
      it 'builds criteria' do
        criteria = object.instance_variable_get(:@criteria)
        expect(criteria["sort"]).to eq('title_sort asc')
        expect(criteria["resolve[]"]).to eq(["repository:id", "resource:id@compact_resource", "ancestors:id@compact_resource"])
        expect(criteria["facet.mincount"]).to eq(1)
        expect(criteria["types"]).to eq(nil)
        expect(criteria["aq"]).to eq(nil)
        expect(criteria["filter"]).to eq("{\"query\":{\"op\":\"AND\",\"subqueries\":[{\"op\":\"OR\",\"subqueries\":[{\"field\":\"types\",\"value\":\"type_a\",\"negated\":false,\"literal\":false,\"jsonmodel_type\":\"field_query\"}],\"jsonmodel_type\":\"boolean_query\"}],\"jsonmodel_type\":\"boolean_query\"},\"jsonmodel_type\":\"advanced_query\"}")
        expect(criteria["facet[]"]).to eq(["primary_type", "subjects", "published_agents", "repository"])
        expect(criteria["page_size"]).to eq(10)
      end
      it 'builds facet_filter' do
        facet_filter = object.instance_variable_get(:@facet_filter)
        expect(facet_filter).to have_attributes(:default_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:fields => [])
        expect(facet_filter).to have_attributes(:values => [])
        expect(facet_filter).to have_attributes(:facet_types => ["primary_type", "subjects", "published_agents", "repository"])
        expect(facet_filter).to have_attributes(:facet_set_arr => [])
      end
    end
  end
end
