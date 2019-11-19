require_relative 'indexer_common_config'

class IndexerCommon
  include JSONModel

  @@resolved_attributes = IndexerCommonConfig.resolved_attributes
end
