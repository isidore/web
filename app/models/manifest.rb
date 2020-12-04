# frozen_string_literal: true

class Manifest

  def initialize(manifest)
    @manifest = manifest
  end

  def self.required(*names)
    names.each do |name|
      define_method name do
        @manifest[name.to_s]
      end
    end
  end

  # - - - - - - - - - -

  def self.defaulted(*names)
    names.each do |name|
      define_method name do
        @manifest[name.to_s]
      end
    end
  end

  # - - - - - - - - - -

  required :group_id,           # eg '8bvlJk',    nil if !group-session
           :group_index,        # eg 45 (salmon), nil if !group-session
           :created,            # eg [2018,10,14, 9,50,23,800239]
           :display_name,       # eg 'Java, JUnit'
           :filename_extension, # eg [ '.java' ]
           :id,                 # eg '260za8'
           :image_name          # eg 'cyberdojofoundation/java_junit:956b0c2'

  defaulted :exercise,
            :highlight_filenames,
            :tab_size,
            :max_seconds,
            :progress_regexs

end
