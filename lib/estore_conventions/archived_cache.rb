module EstoreConventions
  class ArchivedCache
    # acts like an estore_record in that it has an array of #archives
    include ArchivedAttributes
    include ArchivedOutliers

    def initialize(estore_record)
      # TODO: Do we need this? Seems like caching the archive fetching should
      #   save us a few n+1 queries on the ActiveRecord model.
      #
      # TODO: Write tests to confirm the cacheability
      #
      # Note: @_thearchives is the name of the internal instance
      #       method that holds the array...
      #
      #
      #       ... this is smell code but works
      #       for now
      #
      @_thearchives ||= estore_record.archives
    end







  end
end