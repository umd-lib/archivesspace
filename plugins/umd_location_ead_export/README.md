# umd_location_ead_export

## Introduction

This is a "proof-of-concept" plugin that exports the current "Location" of a
"Top Container" as part of the EAD export.

## Application Setup

1) Add a "plugins/local/indexer/indexer_common_config.rb" file with the
   following content:

   ```
   class IndexerCommonConfig
     def self.resolved_attributes
       [
         'location_profile',
         'container_profile',
         'container_locations',
         'subjects',

         # EAD export depends on this
         'linked_agents',
         'linked_records',
         'classifications',

         # EAD export depends on this
         'digital_object',
         'agent_representation',
         'repository',
         'repository::agent_representation',
         'related_agents',

         # EAD export depends on this
         'top_container',

         # EAD export depends on this
         'top_container::container_profile',

         # Used by "umd_ead_location_export" plugin
         'top_container::container_locations',

         # Assessment module depends on these
         'related_agents',
         'records',
         'collections',
         'surveyed_by',
         'reviewer',

         'creator'
       ]
     end
   end
   ```

  **Note:** This file is simply the "self.resolved_attributes" method of the
  "indexer/app/lib/indexer_common_config.rb" with the following lines added:

  ```
         # Used by "umd_ead_location_export" plugin
         'top_container::container_locations',
  ```

2) Add a "plugins/local/indexer/indexer_common.rb" file with the following
   content:

   ```
   require_relative 'indexer_common_config'

   class IndexerCommon
     include JSONModel

     @@resolved_attributes = IndexerCommonConfig.resolved_attributes
   end
   ```

3) Edit the "common/config/config.rb" file, adding the following line as the
third line:

```
AppConfig[:plugins] << 'umd_location_ead_export'
```

## Plugin Functionality

This plugin will add the "Building" and "Barcode" fields of the first
"Location" of a "Top Container" associated is a resource into the "label"
attribute of the "container" XML tag associated with the resource.
