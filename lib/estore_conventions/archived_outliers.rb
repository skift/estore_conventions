# Combination of Archivedattributes and Enumerable#outliers

module EstoreConventions
  module ArchivedOutliers
    # returns (Array) start, end of PaperTrail::Versions
    #   [date_start, date_end] in strftime(%Y-%m-%d)
    def versions_endpoints(att)
      days = versions_complete_data_for_attribute(att).keys

      return [days[0], days[-1]]
    end


    # returns Float
    # this is wonky because of the wonky way we use historical_rate_by_day
    def versions_average_for_attribute(att, opts={})
      _use_delta = opts[:delta] || false
      if _use_delta
        return historical_rate_per_day(att, nil, nil)
      else
        data = versions_complete_data_for_attribute(att, opts)

        return data.e_mean
      end
    end

    def versions_average_for_delta_attribute(att)
      versions_average_for_attribute(att, delta: true)
    end


    # returns Hash of outliers
    #  { 2013-10-12 => {value: 1020, sigma: 2.3 }}
    def versions_outliers_for_attribute(att, opts={})
      data = versions_complete_data_for_attribute(att, opts)

      return data.outliers
    end


    def versions_outliers_for_delta_attribute(att)
      versions_outliers_for_attribute(att, delta: true)
    end


    def versions_complete_data_for_attribute(att, opts={})
      _use_delta = opts[:delta] || false

      if _use_delta
        version_data = archived_attribute_delta_by_day(att, nil, nil)
      else
        version_data = archived_attribute(att, nil, nil)
      end

      return version_data
    end

    def versions_complete_data_for_delta_attribute(att)
      versions_complete_data_for_attribute(att, delta: true)
    end

  end
end