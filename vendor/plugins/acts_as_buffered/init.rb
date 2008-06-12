require 'acts_as_buffered'
ActiveRecord::Base.send :include, Acts::Buffered
