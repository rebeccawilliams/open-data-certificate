class Certificate < ActiveRecord::Base
  belongs_to :response_set

  has_one :user, :through => :response_set

  attr_accessible :published, :name, :attained_level, :curator

  class << self
    def search(search)
      query = self.where({})
      search.downcase.split(/\s+/).each do |term|
        query = query.where("LOWER(certificates.name) LIKE ?", "%#{term}%")
      end
      query
    end

    def by_newest
      order("certificates.created_at DESC")
    end

    def group_similar
      joins(:response_set => [:survey]).group('surveys.title, response_sets.dataset_id')
    end

    def badge_file_for_level(level)
      filename = case level
                   when 'basic'
                     'raw_level_badge.png'
                   when 'raw', 'pilot', 'standard', 'exemplar'
                     "#{level}_level_badge.png"
                   else
                     'no_level_badge.png'
                 end

      File.open(File.join(Rails.root, 'app/assets/images/badges', filename))
    end
  end

  def badge_file
    Certificate.badge_file_for_level(attained_level)
  end


  def update_from_response_set

    unless response_set_id.nil?

      # because of the caching of attained level etc, we have to load
      # a new instance of the response_set to calculate these freshly
      #
      # A fix to this is to calculate the attained_level
      # more effectively (related - #362)
      r2 = ResponseSet.find response_set_id
      update_attributes({
        attained_level: r2.attained_level,
        curator:  r2.curator_determined_from_responses,
        name:  r2.title
      })

    end
  end

end
